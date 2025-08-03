module Chat
  module Services
    class AiService
      include Singleton

      def initialize
        @client = OpenAI::Client.new(access_token: Rails.application.credentials.openai[:api_key])
      end

      # Generate embeddings for text content
      def generate_embeddings(text)
        response = @client.embeddings(
          parameters: {
            model: "text-embedding-3-small",
            input: text
          }
        )

        response.dig("data", 0, "embedding")
      rescue => e
        Rails.logger.error "Error generating embeddings: #{e.message}"
        nil
      end

      # Generate chat completion with context
      def generate_chat_response(messages, context = nil)
        system_message = build_system_message(context)

        response = @client.chat(
          parameters: {
            model: "gpt-4-turbo-preview",
            messages: [ system_message ] + messages,
            temperature: 0.7,
            max_tokens: 1000
          }
        )

        response.dig("choices", 0, "message", "content")
      rescue => e
        Rails.logger.error "Error generating chat response: #{e.message}"
        "I apologize, but I'm having trouble processing your request right now. Please try again later."
      end

      # Search for relevant document chunks
      def search_documents(query, document_collection, limit = 5)
        query_embedding = generate_embeddings(query)
        return [] unless query_embedding

        # Get all embeddings for the collection
        embeddings = document_collection.documents
                                       .joins(:document_embeddings)
                                       .includes(:document_embeddings)

        # Calculate similarities and return top matches
        similarities = []

        embeddings.each do |document|
          document.document_embeddings.each do |embedding|
            similarity = embedding.similarity_with(query_embedding)
            similarities << {
              embedding: embedding,
              similarity: similarity,
              document: document
            }
          end
        end

        # Sort by similarity and return top results
        similarities.sort_by { |s| -s[:similarity] }
                    .first(limit)
                    .map { |s| s[:embedding] }
      end

      # Chunk text for embedding generation
      def chunk_text(text, max_tokens = 1000)
        return [] if text.blank?

        # Simple chunking by sentences and token count
        sentences = text.split(/[.!?]+/).map(&:strip).reject(&:blank?)
        chunks = []
        current_chunk = ""

        sentences.each do |sentence|
          # Rough token estimation (1 token ≈ 4 characters)
          estimated_tokens = (current_chunk + sentence).length / 4

          if estimated_tokens > max_tokens && current_chunk.present?
            chunks << current_chunk.strip
            current_chunk = sentence
          else
            current_chunk += (current_chunk.present? ? ". " : "") + sentence
          end
        end

        chunks << current_chunk.strip if current_chunk.present?
        chunks
      end

      private

      def build_system_message(context = nil)
        base_message = "You are a helpful AI assistant that helps users understand and navigate their documents. "
        base_message += "You provide accurate, helpful responses based on the document content provided. "
        base_message += "Always cite specific parts of the documents when answering questions. "
        base_message += "If you don't have enough information to answer a question, say so clearly."

        if context.present?
          base_message += "\n\nRelevant document context:\n#{context}"
        end

        { role: "system", content: base_message }
      end
    end
  end
end 