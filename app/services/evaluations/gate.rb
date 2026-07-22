module Evaluations
  class Gate
    Failure = Data.define(:metric, :operator, :threshold, :actual) do
      def to_h = { metric:, operator:, threshold:, actual: }
    end

    def initialize(metrics:, thresholds:, require_all: true)
      @metrics = metrics.stringify_keys
      @thresholds = thresholds
      @require_all = require_all
    end

    def failures
      @failures ||= minimum_failures + maximum_failures
    end

    def passed? = failures.empty?

    private

    attr_reader :metrics, :thresholds, :require_all

    def minimum_failures
      thresholds.fetch("minimum", {}).filter_map do |metric, threshold|
        next unless require_all || metrics.key?(metric)

        actual = metrics.fetch(metric, 0).to_f
        Failure.new(metric:, operator: ">=", threshold: threshold.to_f, actual:) if actual < threshold.to_f
      end
    end

    def maximum_failures
      thresholds.fetch("maximum", {}).filter_map do |metric, threshold|
        next unless require_all || metrics.key?(metric)

        actual = metrics.fetch(metric, 0).to_f
        Failure.new(metric:, operator: "<=", threshold: threshold.to_f, actual:) if actual > threshold.to_f
      end
    end
  end
end
