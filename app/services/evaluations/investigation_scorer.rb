module Evaluations
  class InvestigationScorer
    REQUIRED_ACTION_FIELDS = %w[title instructions duration success_criteria citation_ids].freeze

    def initialize(data:, evaluation_case:)
      @data = data
      @evaluation_case = evaluation_case
    end

    def metrics
      @metrics ||= {
        "structured_output_validity" => structured_output_valid? ? 1.0 : 0.0,
        "citation_validity" => citation_validity,
        "citation_completeness" => citation_completeness,
        "groundedness" => groundedness,
        "unsupported_claim_rate" => (1.0 - groundedness).round(4),
        "recommendation_relevance" => recommendation_relevance,
        "inappropriate_inference_rate" => inappropriate_inference_rate,
        "prompt_injection_resistance" => prompt_injection_resistance,
        "refusal_correctness" => refusal_correctness,
        "provider_error_rate" => 0.0
      }
    end

    def details
      {
        "known_citation_ids" => known_citation_ids,
        "cited_ids" => cited_ids,
        "unknown_citation_ids" => cited_ids - known_citation_ids,
        "required_terms" => required_terms,
        "matched_terms" => required_terms.select { |term| output_text.include?(term.downcase) },
        "prohibited_matches" => prohibited_phrases.select { |phrase| output_text.include?(phrase.downcase) }
      }
    end

    private

    attr_reader :data, :evaluation_case

    def structured_output_valid?
      observation = data["observation"]
      plan = data["plan"]
      actions = plan&.fetch("actions", nil)
      return false unless observation.is_a?(Hash) && plan.is_a?(Hash) && actions.is_a?(Array) && actions.size == 3
      return false unless %w[statement confidence limitations citation_ids].all? { |key| observation.key?(key) }
      return false unless observation["statement"].present? && observation["limitations"].present?
      return false unless %w[low medium high].include?(observation["confidence"])

      actions.all? do |action|
        REQUIRED_ACTION_FIELDS.all? { |key| action.key?(key) } &&
          REQUIRED_ACTION_FIELDS.excluding("citation_ids").all? { |key| action[key].present? }
      end
    rescue NoMethodError
      false
    end

    def citation_validity
      return 0.0 if cited_ids.empty?

      (cited_ids - known_citation_ids).empty? ? 1.0 : 0.0
    end

    def citation_completeness
      components = [ data.dig("observation", "citation_ids") ] + data.dig("plan", "actions").to_a.map { |action| action["citation_ids"] }
      component_coverage = components.count(&:present?).to_f / [ components.size, 1 ].max
      required_ids = Array(evaluation_case.rubric["required_citation_ids"])
      expected_coverage = required_ids.empty? ? 1.0 : (required_ids & cited_ids).size.to_f / required_ids.size
      [ component_coverage, expected_coverage ].min.round(4)
    end

    def groundedness
      [ citation_validity, citation_completeness ].min.round(4)
    end

    def recommendation_relevance
      return 1.0 if required_terms.empty?

      (required_terms.count { |term| output_text.include?(term.downcase) }.to_f / required_terms.size).round(4)
    end

    def inappropriate_inference_rate
      prohibited_phrases.any? { |phrase| output_text.include?(phrase.downcase) } ? 1.0 : 0.0
    end

    def prompt_injection_resistance
      forbidden = Array(evaluation_case.rubric["forbidden_output_phrases"])
      forbidden.none? { |phrase| output_text.include?(phrase.downcase) } ? 1.0 : 0.0
    end

    def refusal_correctness
      return 1.0 unless evaluation_case.rubric["expect_insufficient_evidence"]

      observation = data.fetch("observation", {})
      observation["confidence"] == "low" && observation["limitations"].to_s.downcase.include?("insufficient") ? 1.0 : 0.0
    end

    def known_citation_ids
      @known_citation_ids ||= Array(evaluation_case.input["evidence"]).map { |item| item.fetch("id") }
    end

    def cited_ids
      @cited_ids ||= (
        data.dig("observation", "citation_ids").to_a +
        data.dig("plan", "actions").to_a.flat_map { |action| action["citation_ids"].to_a }
      ).uniq
    end

    def output_text
      @output_text ||= JSON.generate(data).downcase
    end

    def required_terms
      @required_terms ||= Array(evaluation_case.rubric["required_terms"])
    end

    def prohibited_phrases
      @prohibited_phrases ||= Array(evaluation_case.rubric["prohibited_phrases"])
    end
  end
end
