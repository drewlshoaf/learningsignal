module Curriculum
  class EmbedDocument
    def initialize(document:, provider: Ai::ProviderRegistry.fetch)
      @document = document
      @provider = provider
    end

    def call
      chunks = document.document_chunks.order(:id).to_a
      return if chunks.empty?

      embeddings = provider.embed(model: Ai::Configuration.embedding_model, inputs: chunks.map(&:content))
      chunks.zip(embeddings).each { |chunk, embedding| chunk.update!(embedding: embedding) }
    end

    private

    attr_reader :document, :provider
  end
end
