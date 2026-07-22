module Curriculum
  class Chunker
    Chunk = Data.define(:content, :locator, :token_count, :metadata)
    MAX_WORDS = 220
    OVERLAP_WORDS = 40

    def call(pages)
      pages.flat_map do |page|
        words = page.text.scan(/\S+/)
        next [] if words.empty?

        page_chunks(words).each_with_index.map do |chunk_words, index|
          Chunk.new(
            content: chunk_words.join(" "),
            locator: "Page #{page.number} · chunk #{index + 1}",
            token_count: chunk_words.length,
            metadata: { page_number: page.number, page_chunk_index: index + 1 }
          )
        end
      end
    end

    private

    def page_chunks(words)
      chunks = []
      offset = 0
      step = MAX_WORDS - OVERLAP_WORDS

      while offset < words.length
        chunks << words.slice(offset, MAX_WORDS)
        break if offset + MAX_WORDS >= words.length

        offset += step
      end
      chunks
    end
  end
end
