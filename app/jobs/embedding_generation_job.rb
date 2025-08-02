class EmbeddingGenerationJob < ApplicationJob
  queue_as :default

  def perform(document)
    return unless document.can_generate_embeddings?

    begin
      # Split content into chunks
      chunks = split_content_into_chunks(document.content)

      chunks.each_with_index do |chunk, index|
        # Generate embedding using OpenAI
        embedding = generate_embedding(chunk)

        # Store embedding
        document.document_embeddings.create!(
          content: chunk,
          embedding: embedding,
          chunk_index: index,
          token_count: estimate_token_count(chunk),
          metadata: {
            chunk_size: chunk.length,
            chunk_index: index
          }
        )
      end

      Rails.logger.info "Generated #{chunks.length} embeddings for document #{document.id}"
    rescue => e
      Rails.logger.error "Embedding generation failed for document #{document.id}: #{e.message}"
    end
  end

  private

  def split_content_into_chunks(content, max_chunk_size = 1000)
    # Simple chunking by sentences
    sentences = content.split(/[.!?]+/).map(&:strip).reject(&:empty?)
    chunks = []
    current_chunk = ""

    sentences.each do |sentence|
      if (current_chunk + sentence).length > max_chunk_size && current_chunk.present?
        chunks << current_chunk.strip
        current_chunk = sentence
      else
        current_chunk += (current_chunk.empty? ? "" : ". ") + sentence
      end
    end

    chunks << current_chunk.strip if current_chunk.present?
    chunks
  end

  def generate_embedding(text)
    client = OpenAI::Client.new(access_token: Rails.application.credentials.openai[:api_key])

    response = client.embeddings(
      parameters: {
        model: "text-embedding-ada-002",
        input: text
      }
    )

    response.dig("data", 0, "embedding")
  end

  def estimate_token_count(text)
    # Rough estimation: 1 token ≈ 4 characters
    (text.length / 4.0).ceil
  end
end
