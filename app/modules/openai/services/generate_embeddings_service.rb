module Openai
  module Services
    class GenerateEmbeddingsService
      def initialize(content)
        @content = content
        @client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
      end

      def call
        response = client.embeddings(
          parameters: {
            model: "text-embedding-3-small",
            input: content
          }
        )

        response.dig("data", 0, "embedding")
      end

      private

      attr_reader :content, :client
    end
  end
end
