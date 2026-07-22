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
      terms = query.downcase.scan(/[a-z0-9]+/).reject { |term| term.length < 4 }.uniq

      candidates.map do |chunk, distance|
        lexical_matches = terms.count { |term| chunk.content.downcase.include?(term) }
        semantic_score = 1.0 - [ distance.to_f, 1.0 ].min
        Result.new(chunk: chunk, score: (semantic_score * 0.8 + [ lexical_matches / 5.0, 0.2 ].min).round(4))
      end.sort_by { |result| -result.score }.first(limit)
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
