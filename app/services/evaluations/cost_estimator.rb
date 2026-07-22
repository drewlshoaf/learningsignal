module Evaluations
  class CostEstimator
    def initialize(provider_name:)
      @provider_name = provider_name.to_s
    end

    def estimate(input_tokens:, output_tokens:)
      return 0.to_d if provider_name == "deterministic"

      input_cost = input_tokens * decimal_env("AI_INPUT_COST_PER_MILLION") / 1_000_000
      output_cost = output_tokens * decimal_env("AI_OUTPUT_COST_PER_MILLION") / 1_000_000
      (input_cost + output_cost).round(6)
    end

    private

    attr_reader :provider_name

    def decimal_env(name)
      BigDecimal(ENV.fetch(name, "0"))
    rescue ArgumentError
      raise ArgumentError, "#{name} must be a decimal price per million tokens"
    end
  end
end
