class ProcessChatMessageJob < ApplicationJob
  queue_as :default

  def perform(chat_message_id)
    chat_message = ChatMessage.find(chat_message_id)
    return unless chat_message.role == "user"

    begin
      # Find relevant document chunks using embeddings
      relevant_chunks = find_relevant_chunks(chat_message.content, chat_message.chat_session)

      # Generate AI response
      response = generate_ai_response(chat_message.content, relevant_chunks)

      # Create assistant response
      chat_message.chat_session.chat_messages.create!(
        content: response,
        role: "assistant",
        message_type: "ai_response",
        metadata: {
          relevant_chunks_count: relevant_chunks.length,
          sources: relevant_chunks.map { |c| c.document.title }.uniq
        }
      )

      # Update chat session
      chat_message.chat_session.touch(:last_activity_at)

    rescue => e
      Rails.logger.error "Chat message processing failed: #{e.message}"

      # Create error response
      chat_message.chat_session.chat_messages.create!(
        content: "I'm sorry, I encountered an error while processing your request. Please try again.",
        role: "assistant",
        message_type: "error"
      )
    end
  end

  private

  def find_relevant_chunks(query, chat_session)
    return [] unless chat_session.document_collection.present?

    # Get all embeddings from the chat session's document collection
    embeddings = DocumentEmbedding.joins(document: :document_collection)
                                 .where(document_collections: { id: chat_session.document_collection_id })
                                 .where.not(embedding: nil)

    return [] if embeddings.empty?

    # Generate query embedding
    query_embedding = generate_embedding(query)
    return [] unless query_embedding

    # Calculate similarities and find top matches
    similarities = embeddings.map do |embedding|
      similarity = cosine_similarity(query_embedding, embedding.embedding)
      [ embedding, similarity ]
    end

    # Sort by similarity and return top 5
    similarities.sort_by { |_, similarity| -similarity }
                .first(5)
                .map(&:first)
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

  def cosine_similarity(vec1, vec2)
    return 0 if vec1.nil? || vec2.nil?

    dot_product = vec1.zip(vec2).sum { |a, b| a * b }
    magnitude1 = Math.sqrt(vec1.sum { |x| x * x })
    magnitude2 = Math.sqrt(vec2.sum { |x| x * x })

    return 0 if magnitude1 == 0 || magnitude2 == 0

    dot_product / (magnitude1 * magnitude2)
  end

  def generate_ai_response(query, relevant_chunks)
    client = OpenAI::Client.new(access_token: Rails.application.credentials.openai[:api_key])

    context = relevant_chunks.map(&:content).join("\n\n")

    prompt = <<~PROMPT
      You are a helpful assistant that answers questions based on the provided document content.

      Context from documents:
      #{context}

      Question: #{query}

      Please provide a helpful answer based on the context above. If the context doesn't contain relevant information, say so. Cite specific parts of the documents when possible.
    PROMPT

    response = client.chat(
      parameters: {
        model: "gpt-3.5-turbo",
        messages: [
          { role: "system", content: "You are a helpful assistant that answers questions based on document content." },
          { role: "user", content: prompt }
        ],
        max_tokens: 1000,
        temperature: 0.7
      }
    )

    response.dig("choices", 0, "message", "content")
  end
end
