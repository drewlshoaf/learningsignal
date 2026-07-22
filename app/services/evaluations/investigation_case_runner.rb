module Evaluations
  class InvestigationCaseRunner
    def initialize(evaluation_case:, provider:, model:, prompt:, cost_estimator:)
      @evaluation_case = evaluation_case
      @provider = provider
      @model = model
      @prompt = prompt
      @cost_estimator = cost_estimator
    end

    def call
      result = provider.generate(
        model:,
        input: formatted_input,
        instructions: prompt.content,
        schema: Ai::Schemas::InvestigationResult.definition,
        metadata: { evaluation_case_id: evaluation_case.id, evaluation_case_version: evaluation_case.version }
      )
      scorer = InvestigationScorer.new(data: result.fetch(:data), evaluation_case:)
      metrics = scorer.metrics
      gate = Gate.new(metrics:, thresholds: evaluation_case.rubric.fetch("metrics"))
      input_tokens = result.fetch(:input_tokens).to_i
      output_tokens = result.fetch(:output_tokens).to_i

      CaseOutcome.new(
        status: gate.passed? ? "passed" : "failed",
        metrics:,
        details: scorer.details.merge(
          "output" => result.fetch(:data),
          "request_id" => result.fetch(:request_id),
          "model" => result.fetch(:model),
          "rubric_failures" => gate.failures.map(&:to_h)
        ),
        input_tokens:,
        output_tokens:,
        estimated_cost_usd: cost_estimator.estimate(input_tokens:, output_tokens:),
        latency_ms: result.fetch(:latency_ms).to_i,
        error_message: nil
      )
    rescue StandardError => error
      error_outcome(error)
    end

    private

    attr_reader :evaluation_case, :provider, :model, :prompt, :cost_estimator

    def formatted_input
      input = evaluation_case.input
      evidence = Array(input.fetch("evidence")).map do |item|
        "[#{item.fetch('id')}] #{item.fetch('locator')}: #{item.fetch('content')}"
      end.join("\n\n")

      <<~INPUT
        Student: #{input.fetch('student')} (synthetic record)
        Course: #{input.fetch('course')}
        Signal: #{input.fetch('signal')}
        Objective: #{input.fetch('objective')}
        EVIDENCE_STATUS: #{input.fetch('evidence_status', 'sufficient')}

        Evidence:
        #{evidence}
      INPUT
    end

    def error_outcome(error)
      CaseOutcome.new(
        status: "errored",
        metrics: { "provider_error_rate" => 1.0 },
        details: { "error_class" => error.class.name },
        input_tokens: 0,
        output_tokens: 0,
        estimated_cost_usd: 0.to_d,
        latency_ms: 0,
        error_message: error.message
      )
    end
  end
end
