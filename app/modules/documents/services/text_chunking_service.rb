module Documents
  module Services
    class TextChunkingService
      include Singleton

      # Default chunk size that works well with text-embedding-3-small
      DEFAULT_CHUNK_SIZE = 1000
      DEFAULT_OVERLAP_SIZE = 200
      MIN_CHUNK_SIZE = 100

      def initialize
        @openai_client = Openai::Services::ClientService.instance
      end

      def chunk_text(text, chunk_size: DEFAULT_CHUNK_SIZE, overlap_size: DEFAULT_OVERLAP_SIZE)
        return [] if text.blank?

        text = sanitize_text(text)
        return [] if text.length < MIN_CHUNK_SIZE

        # Use semantic chunking for better context preservation
        chunks = create_semantic_chunks(text, chunk_size, overlap_size)

        # Validate and optimize chunks
        chunks.map.with_index do |chunk, index|
          {
            content: chunk,
            index: index,
            token_count: @openai_client.estimate_token_count(chunk),
            character_count: chunk.length
          }
        end.select { |chunk_data| chunk_data[:token_count] > 0 }
      end

      private

      def sanitize_text(text)
        # Remove excessive whitespace and normalize
        text = text.gsub(/\r\n|\r/, "\n")  # Normalize line endings
        text = text.gsub(/\n{3,}/, "\n\n") # Limit consecutive newlines
        text = text.gsub(/[ \t]+/, " ")     # Normalize spaces
        text = text.strip

        # Remove non-printable characters except newlines and tabs
        text.gsub(/[^\p{Print}\n\t]/, "")
      end

      def create_semantic_chunks(text, chunk_size, overlap_size)
        # Strategy: Try to split at paragraph boundaries, then sentences, then words
        chunks = []
        remaining_text = text

        while remaining_text.length > chunk_size
          chunk_end = find_optimal_split_point(remaining_text, chunk_size)
          chunk = remaining_text[0...chunk_end].strip

          if chunk.length >= MIN_CHUNK_SIZE
            chunks << chunk

            # Calculate overlap for next chunk
            overlap_start = [ chunk_end - overlap_size, 0 ].max
            remaining_text = remaining_text[overlap_start..-1]
          else
            # If chunk is too small, take a larger piece
            remaining_text = remaining_text[chunk_size..-1] || ""
          end
        end

        # Add the remaining text as the last chunk
        if remaining_text.strip.length >= MIN_CHUNK_SIZE
          chunks << remaining_text.strip
        end

        chunks
      end

      def find_optimal_split_point(text, max_size)
        return text.length if text.length <= max_size

        # Try to split at paragraph boundaries (double newlines)
        split_point = find_split_at_pattern(text, /\n\n/, max_size)
        return split_point if split_point

        # Try to split at sentence boundaries
        split_point = find_split_at_pattern(text, /[.!?]+\s+/, max_size)
        return split_point if split_point

        # Try to split at clause boundaries
        split_point = find_split_at_pattern(text, /[,;:]\s+/, max_size)
        return split_point if split_point

        # Split at word boundaries as last resort
        split_point = find_split_at_pattern(text, /\s+/, max_size)
        return split_point if split_point

        # If all else fails, hard split at max_size
        max_size
      end

      def find_split_at_pattern(text, pattern, max_size)
        # Find all matches of the pattern within the acceptable range
        matches = []
        text.scan(pattern) do |match|
          pos = Regexp.last_match.end(0)
          matches << pos if pos <= max_size
        end

        # Return the position closest to max_size
        matches.max
      end
    end
  end
end
