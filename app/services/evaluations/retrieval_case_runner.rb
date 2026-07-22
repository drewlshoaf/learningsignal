module Evaluations
  class RetrievalCaseRunner
    Record = Data.define(:id, :content)

    def initialize(evaluation_case:, provider:, embedding_model:)
      @evaluation_case = evaluation_case
      @provider = provider
      @embedding_model = embedding_model
    end

    def call
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      input = evaluation_case.input
      records = input.fetch("documents").map { |item| Record.new(id: item.fetch("id"), content: item.fetch("content")) }
      vectors = provider.embed(model: embedding_model, inputs: [ input.fetch("query"), *records.map(&:content) ])
      query_vector = vectors.shift
      candidates = records.zip(vectors).map { |record, vector| [ record, cosine_distance(query_vector, vector) ] }
      ranked = Retrieval::HybridRanker.rank(candidates:, query: input.fetch("query"), limit: input.fetch("limit"))
      retrieved_ids = ranked.map { |result| result.record.id }
      expected_ids = input.fetch("expected_document_ids")
      overlap = retrieved_ids & expected_ids
      metrics = {
        "retrieval_precision" => (overlap.size.to_f / [ retrieved_ids.size, 1 ].max).round(4),
        "retrieval_recall" => (overlap.size.to_f / [ expected_ids.size, 1 ].max).round(4)
      }
      gate = Gate.new(metrics:, thresholds: evaluation_case.rubric.fetch("metrics"))

      CaseOutcome.new(
        status: gate.passed? ? "passed" : "failed",
        metrics:,
        details: {
          "query" => input.fetch("query"),
          "expected_document_ids" => expected_ids,
          "retrieved" => ranked.map { |result| { "id" => result.record.id, "score" => result.score } },
          "rubric_failures" => gate.failures.map(&:to_h)
        },
        input_tokens: 0,
        output_tokens: 0,
        estimated_cost_usd: 0.to_d,
        latency_ms: elapsed_ms(started),
        error_message: nil
      )
    rescue StandardError => error
      CaseOutcome.new(
        status: "errored",
        metrics: { "retrieval_precision" => 0.0, "retrieval_recall" => 0.0 },
        details: { "error_class" => error.class.name },
        input_tokens: 0,
        output_tokens: 0,
        estimated_cost_usd: 0.to_d,
        latency_ms: 0,
        error_message: error.message
      )
    end

    private

    attr_reader :evaluation_case, :provider, :embedding_model

    def cosine_distance(left, right)
      dot = left.zip(right).sum { |a, b| a.to_f * b.to_f }
      left_magnitude = Math.sqrt(left.sum { |value| value.to_f**2 })
      right_magnitude = Math.sqrt(right.sum { |value| value.to_f**2 })
      return 1.0 if left_magnitude.zero? || right_magnitude.zero?

      1.0 - (dot / (left_magnitude * right_magnitude))
    end

    def elapsed_ms(started)
      ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round
    end
  end
end
