module Retrieval
  class HybridSearch
    Result = Data.define(:chunk, :score)

    def initialize(organization:, objective:, provider: Ai::ProviderRegistry.fetch)
      @organization = organization
      @objective = objective
      @provider = provider
    end

    def search(query:, limit: 4)
      vector = provider.embed(model: Ai::Configuration.embedding_model, inputs: [ query ]).first
      candidates = semantic_candidates(vector, limit: limit * 2)
      HybridRanker.rank(candidates:, query:, limit:).map do |result|
        Result.new(chunk: result.record, score: result.score)
      end
    end

    private

    attr_reader :organization, :objective, :provider

    def semantic_candidates(vector, limit:)
      relation = DocumentChunk.where(organization: organization, learning_objective: objective).where.not(embedding: nil)
      quoted_vector = DocumentChunk.connection.quote(Pgvector::Vector.new(vector).to_s)
      relation.select("document_chunks.*, embedding <=> #{quoted_vector}::vector AS vector_distance")
        .order(Arel.sql("vector_distance ASC"))
        .limit(limit)
        .map { |chunk| [ chunk, chunk.attributes.fetch("vector_distance") ] }
    end
  end
end
