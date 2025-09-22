module Chat
  module Jobs
    class ProcessChatMessageJob < BaseSidekiqJob
      sidekiq_options queue: :messages_queue, retry: true

      def initialize
        super
        @openai_client = Openai::Services::ClientService.instance
        @retrieval_service = Chat::Services::DocumentRetrievalService.instance
      end

      def perform(chat_message_id)
        chat_message = Chat::Models::ChatMessage.find(chat_message_id)
        return unless chat_message&.role == "user"

        Rails.logger.info "Processing chat message #{chat_message_id} for session #{chat_message.chat_session_id}"

        begin
          # Find relevant document chunks using enhanced retrieval
          relevant_chunks = @retrieval_service.search_with_reranking(
            chat_message.content,
            chat_message.chat_session.document_collection
          )

          # Build conversation context
          conversation_context = build_conversation_context(chat_message.chat_session)
          document_context = @retrieval_service.build_context_from_chunks(relevant_chunks)

          # Generate AI response using improved context
          response_data = generate_enhanced_ai_response(
            query: chat_message.content,
            document_context: document_context,
            conversation_context: conversation_context
          )

          # Create assistant response with enhanced metadata
          chat_message.chat_session.chat_messages.create!(
            content: response_data[:content],
            role: "assistant",
            message_type: "answer",
            user: chat_message.chat_session.user,
            tokens_used: response_data[:usage]&.dig("total_tokens"),
            cost: calculate_cost(response_data[:usage]),
            metadata: {
              relevant_chunks_count: relevant_chunks.length,
              sources: relevant_chunks.map { |c| c.document.title }.uniq,
              similarity_scores: relevant_chunks.map { |c|
                c.similarity_with(@openai_client.generate_embeddings(chat_message.content))
              }.compact,
              model_used: response_data[:model],
              context_token_count: @openai_client.estimate_token_count(document_context),
              generated_at: Time.current.iso8601
            }
          )

          # Update chat session
          chat_message.chat_session.touch(:last_activity_at)

          # Generate title if this is the first exchange and no title exists
          if should_generate_title?(chat_message.chat_session)
            generate_and_update_title(chat_message.chat_session, chat_message.content)
          end

          Rails.logger.info "Successfully processed chat message #{chat_message_id}"

        rescue => e
          Rails.logger.error "Chat message processing failed for message #{chat_message_id}: #{e.message}"
          handle_processing_error(chat_message, e)
        end
      end

      private

      def build_conversation_context(chat_session)
        # Get the last few messages for conversational context
        recent_messages = chat_session.chat_messages.ordered.limit(6).pluck(:role, :content)

        return "" if recent_messages.empty?

        context_messages = recent_messages.map do |role, content|
          "#{role.humanize}: #{content}"
        end.join("\n\n")

        "Recent conversation:\n#{context_messages}"
      end

      def generate_enhanced_ai_response(query:, document_context:, conversation_context:)
        # Prepare messages for the conversation
        messages = []

        # Add the user's current query
        user_message = if document_context.present?
          <<~MESSAGE
            Based on the following document content, please answer my question:

            #{document_context}

            #{conversation_context.present? ? "\n#{conversation_context}\n" : ""}

            Question: #{query}

            Please provide a comprehensive answer based on the document content. If the information isn't available in the documents, please say so clearly. Always cite specific documents when referencing information.
          MESSAGE
        else
          <<~MESSAGE
            #{conversation_context.present? ? "#{conversation_context}\n\n" : ""}

            Question: #{query}

            I don't have access to relevant document content for this question. Please let me know if you'd like me to help with something else or if you can provide more context.
          MESSAGE
        end

        messages << { role: "user", content: user_message }

        @openai_client.generate_chat_completion(
          messages: messages,
          model: Openai::Services::ClientService::CHAT_MODEL,
          max_tokens: 1500,
          temperature: 0.7
        )
      end

      def should_generate_title?(chat_session)
        chat_session.chat_messages.count == 2 &&
        (chat_session.title.blank? || chat_session.title == "New Chat")
      end

      def generate_and_update_title(chat_session, first_message)
        title = @openai_client.generate_chat_title(first_message)
        if title.present?
          chat_session.update(title: title)
          Rails.logger.info "Generated title '#{title}' for chat session #{chat_session.id}"
        end
      end

      def calculate_cost(usage)
        return nil unless usage.present?

        # OpenAI pricing (as of 2024) - you should update these rates as needed
        input_tokens = usage["prompt_tokens"] || 0
        output_tokens = usage["completion_tokens"] || 0

        # GPT-4o-mini pricing (example rates)
        input_cost_per_1k = 0.00015  # $0.15 per 1K input tokens
        output_cost_per_1k = 0.0006  # $0.60 per 1K output tokens

        input_cost = (input_tokens / 1000.0) * input_cost_per_1k
        output_cost = (output_tokens / 1000.0) * output_cost_per_1k

        (input_cost + output_cost).round(6)
      end

      def handle_processing_error(chat_message, error)
        error_message = case error
        when OpenAI::Error
          "I'm experiencing connectivity issues with the AI service. Please try again in a moment."
        when ActiveRecord::RecordNotFound
          "I couldn't find the requested information. Please try rephrasing your question."
        else
          "I encountered an unexpected error while processing your request. Please try again."
        end

        # Create error response
        chat_message.chat_session.chat_messages.create!(
          content: error_message,
          role: "assistant",
          message_type: "text",
          user: chat_message.chat_session.user,
          metadata: {
            error: true,
            error_type: error.class.name,
            error_message: error.message,
            occurred_at: Time.current.iso8601
          }
        )
      end
    end
  end
end
