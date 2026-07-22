module Retrieval
  class HybridRanker
    Result = Data.define(:record, :score)

    def self.rank(candidates:, query:, limit:)
      terms = query.downcase.scan(/[a-z0-9]+/).reject { |term| term.length < 4 }.uniq

      candidates.map do |record, distance|
        lexical_matches = terms.count { |term| record.content.downcase.include?(term) }
        semantic_score = 1.0 - [ distance.to_f, 1.0 ].min
        score = semantic_score * 0.8 + [ lexical_matches / 5.0, 0.2 ].min
        Result.new(record:, score: score.round(4))
      end.sort_by { |result| -result.score }.first(limit)
    end
  end
end
