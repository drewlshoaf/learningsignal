module Investigations
  class GroundingValidator
    class InvalidCitation < StandardError; end

    def initialize(result:, evidence:)
      @result = result
      @evidence = evidence
    end

    def validate!
      known_ids = evidence.map(&:citation_id)
      cited_ids = result.dig("observation", "citation_ids").to_a +
        result.dig("plan", "actions").to_a.flat_map { |action| action["citation_ids"].to_a }

      unknown = cited_ids.uniq - known_ids
      raise InvalidCitation, "Unknown citation IDs: #{unknown.join(', ')}" if unknown.any?
      raise InvalidCitation, "Observation requires at least one citation" if result.dig("observation", "citation_ids").blank?
      raise InvalidCitation, "Every plan action requires a citation" if result.dig("plan", "actions").to_a.any? { |action| action["citation_ids"].blank? }

      true
    end

    private

    attr_reader :result, :evidence
  end
end
