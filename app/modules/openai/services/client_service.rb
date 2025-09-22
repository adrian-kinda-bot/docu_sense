module Openai
  module Services
    class ClientService
      include Singleton

      EMBEDDING_MODEL = "text-embedding-3-small".freeze
      CHAT_MODEL = "gpt-4o-mini".freeze # More cost-effective than gpt-4-turbo
      MAX_RETRIES = 3
      INITIAL_RETRY_DELAY = 1

      def initialize
        @client = OpenAI::Client.new(
          access_token: Rails.application.credentials.openai&.[](:api_key) || ENV["OPENAI_API_KEY"],
          request_timeout: 30
        )
        @cache_service = Common::Services::CachingService.instance
      end

      # Generate embeddings with caching, retry logic and error handling
      def generate_embeddings(text)
        return nil if text.blank?

        # Check cache first
        cached_embedding = @cache_service.get_cached_embedding(text)
        return cached_embedding if cached_embedding.present?

        embedding = retry_with_exponential_backoff do
          response = @client.embeddings(
            parameters: {
              model: EMBEDDING_MODEL,
              input: text.strip
            }
          )

          embedding_data = response.dig("data", 0, "embedding")
          validate_embedding!(embedding_data)
          embedding_data
        end

        # Cache the result for future use
        @cache_service.cache_embedding(text, embedding) if embedding.present?

        embedding
      rescue => e
        Rails.logger.error "Failed to generate embeddings after #{MAX_RETRIES} retries: #{e.message}"
        nil
      end

      # Generate chat completion with context and conversation history
      def generate_chat_completion(messages:, context: nil, model: CHAT_MODEL, max_tokens: 1000, temperature: 0.7)
        return nil if messages.blank?

        retry_with_exponential_backoff do
          system_message = build_system_message(context)
          all_messages = [ system_message ] + format_messages(messages)

          response = @client.chat(
            parameters: {
              model: model,
              messages: all_messages,
              max_tokens: max_tokens,
              temperature: temperature,
              stream: false
            }
          )

          content = response.dig("choices", 0, "message", "content")
          usage = response["usage"]

          {
            content: content,
            usage: usage,
            model: model
          }
        end
      rescue => e
        Rails.logger.error "Failed to generate chat completion: #{e.message}"
        {
          content: "I'm sorry, I'm having trouble processing your request right now. Please try again.",
          usage: nil,
          model: model,
          error: e.message
        }
      end

      # Generate a descriptive title for a chat session
      def generate_chat_title(first_message)
        return nil if first_message.blank?

        messages = [
          {
            role: "user",
            content: "Generate a short, descriptive title (maximum 50 characters) for a chat session based on this message: \"#{first_message}\". Return only the title, no quotes or additional text."
          }
        ]

        result = generate_chat_completion(
          messages: messages,
          model: CHAT_MODEL,
          max_tokens: 20,
          temperature: 0.3
        )

        title = result[:content]&.strip&.gsub(/^["']|["']$/, "")
        title if title.present? && title.length <= 50
      rescue => e
        Rails.logger.error "Failed to generate chat title: #{e.message}"
        nil
      end

      # Estimate token count for text (rough approximation)
      def estimate_token_count(text)
        return 0 if text.blank?
        # Rough estimation: 1 token ≈ 4 characters for English text
        (text.length / 4.0).ceil
      end

      # Check if text is within token limits for embedding
      def within_embedding_token_limit?(text)
        estimated_tokens = estimate_token_count(text)
        estimated_tokens <= 8000 # Conservative limit for text-embedding-3-small
      end

      private

      def retry_with_exponential_backoff(&block)
        retries = 0
        begin
          yield
        rescue OpenAI::Error => e
          retries += 1
          if retries <= MAX_RETRIES
            delay = INITIAL_RETRY_DELAY * (2 ** (retries - 1))
            Rails.logger.warn "OpenAI API error (attempt #{retries}/#{MAX_RETRIES}): #{e.message}. Retrying in #{delay} seconds..."
            sleep(delay)
            retry
          else
            raise e
          end
        end
      end

      def validate_embedding!(embedding)
        unless embedding.is_a?(Array) && embedding.length > 0 && embedding.all? { |x| x.is_a?(Numeric) }
          raise "Invalid embedding format received from OpenAI"
        end
      end

      def build_system_message(context = nil)
        base_prompt = "You are a helpful AI assistant that answers questions based on document content."

        if context.present?
          context_prompt = <<~PROMPT
            #{base_prompt}

            You have access to relevant excerpts from documents. Use this information to provide accurate, helpful answers.
            Always cite specific information from the documents when possible.
            If the provided context doesn't contain enough information to answer the question, say so clearly.
            Keep your responses concise but comprehensive.

            Context from documents:
            #{context}
          PROMPT

          { role: "system", content: context_prompt }
        else
          { role: "system", content: base_prompt }
        end
      end

      def format_messages(messages)
        messages.map do |msg|
          case msg
          when Hash
            msg
          when String
            { role: "user", content: msg }
          else
            raise ArgumentError, "Invalid message format: #{msg.class}"
          end
        end
      end
    end
  end
end
