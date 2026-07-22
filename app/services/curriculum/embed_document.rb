module Curriculum
  class EmbedDocument
    BATCH_SIZE = 32

    def initialize(document:, provider: Ai::ProviderRegistry.fetch)
      @document = document
      @provider = provider
    end

    def call
      chunks = document.document_chunks.order(:id).to_a
      return if chunks.empty?

      chunks.each_slice(BATCH_SIZE) do |batch|
        embeddings = provider.embed(model: Ai::Configuration.embedding_model, inputs: batch.map(&:content))
        batch.zip(embeddings).each { |chunk, embedding| chunk.update!(embedding: embedding) }
      end
    end

    private

    attr_reader :document, :provider
  end
end
