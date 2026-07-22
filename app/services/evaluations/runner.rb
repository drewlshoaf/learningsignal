module Evaluations
  class Runner
    Result = Data.define(:run, :report)

    def initialize(
      suite: "fast",
      provider_name: Ai::Configuration.provider,
      model: nil,
      embedding_model: Ai::Configuration.embedding_model,
      prompt_version: "investigation-v1",
      tags: [],
      case_loader: CaseLoader.new,
      output_dir: Rails.root.join("tmp/evaluation-reports"),
      git_sha: GitRevision.current
    )
      @suite = suite.to_s
      @provider_name = provider_name.to_s
      @model = model.presence || (@provider_name == "deterministic" ? "deterministic-v1" : Ai::Configuration.model)
      @embedding_model = embedding_model
      @prompt = PromptCatalog.fetch(prompt_version)
      @tags = Array(tags).map(&:to_s)
      @case_loader = case_loader
      @output_dir = output_dir
      @git_sha = git_sha
    end

    def call
      evaluation_cases = case_loader.load(suite:, tags:)
      raise CaseLoader::InvalidCase, "No evaluation cases selected for suite: #{suite}" if evaluation_cases.empty?

      run = EvaluationRun.create!(
        suite:,
        status: "running",
        provider: provider_name,
        model:,
        prompt_version: prompt.version,
        prompt_digest: prompt.digest,
        cases_digest: case_loader.digest(evaluation_cases),
        git_sha:,
        thresholds: Thresholds.for(suite),
        started_at: Time.current
      )

      provider = Ai::ProviderRegistry.fetch(provider_name)
      cost_estimator = CostEstimator.new(provider_name:)
      evaluation_cases.each do |evaluation_case|
        outcome = run_case(evaluation_case, provider:, cost_estimator:)
        persist_result(run, evaluation_case, outcome)
      end
      finalize(run)
    rescue StandardError => error
      run&.update!(status: "errored", error_message: error.message, finished_at: Time.current)
      raise
    end

    private

    attr_reader :suite, :provider_name, :model, :embedding_model, :prompt, :tags, :case_loader, :output_dir, :git_sha

    def run_case(evaluation_case, provider:, cost_estimator:)
      if evaluation_case.type == "investigation"
        InvestigationCaseRunner.new(evaluation_case:, provider:, model:, prompt:, cost_estimator:).call
      else
        RetrievalCaseRunner.new(evaluation_case:, provider:, embedding_model:).call
      end
    end

    def persist_result(run, evaluation_case, outcome)
      run.evaluation_results.create!(
        case_id: evaluation_case.id,
        case_version: evaluation_case.version,
        case_type: evaluation_case.type,
        tags: evaluation_case.tags,
        status: outcome.status,
        metrics: outcome.metrics,
        details: outcome.details.merge("source" => evaluation_case.source),
        input_tokens: outcome.input_tokens,
        output_tokens: outcome.output_tokens,
        estimated_cost_usd: outcome.estimated_cost_usd,
        latency_ms: outcome.latency_ms,
        error_message: outcome.error_message
      )
    end

    def finalize(run)
      metrics = aggregate_metrics(run.evaluation_results)
      gate = Gate.new(metrics:, thresholds: run.thresholds, require_all: tags.empty?)
      run.update!(
        status: gate.passed? ? "passed" : "failed",
        metrics:,
        gate_failures: gate.failures.map(&:to_h),
        input_tokens: run.evaluation_results.sum(:input_tokens),
        output_tokens: run.evaluation_results.sum(:output_tokens),
        estimated_cost_usd: run.evaluation_results.sum(:estimated_cost_usd),
        latency_ms: run.evaluation_results.sum(:latency_ms),
        finished_at: Time.current
      )
      report = ReportWriter.new(run:, output_dir:).write
      Result.new(run:, report:)
    end

    def aggregate_metrics(results)
      metric_names = results.flat_map { |result| result.metrics.keys }.uniq.sort
      aggregated = metric_names.to_h do |name|
        values = results.filter_map { |result| result.metrics[name] if result.metrics.key?(name) }
        [ name, (values.sum(&:to_f) / values.size).round(4) ]
      end
      aggregated["pass_rate"] = (results.count(&:passed?).to_f / results.size).round(4)
      aggregated
    end
  end
end
