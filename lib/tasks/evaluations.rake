namespace :evaluations do
  desc "Run the version-controlled LearningSignal evaluation suite and enforce quality thresholds"
  task run: :environment do
    result = Evaluations::Runner.new(
      suite: ENV.fetch("SUITE", "fast"),
      provider_name: ENV.fetch("EVALUATION_PROVIDER", Ai::Configuration.provider),
      model: ENV["EVALUATION_MODEL"],
      embedding_model: ENV.fetch("EVALUATION_EMBEDDING_MODEL", Ai::Configuration.embedding_model),
      prompt_version: ENV.fetch("PROMPT_VERSION", "investigation-v1"),
      tags: ENV.fetch("TAGS", "").split(",").compact_blank,
      output_dir: ENV.fetch("REPORT_DIR", Rails.root.join("tmp/evaluation-reports").to_s)
    ).call

    puts result.report.markdown_path
    puts "Evaluation #{result.run.status}: #{result.run.evaluation_results.count} cases, #{result.run.metrics.fetch('pass_rate') * 100}% pass rate"
    abort("Evaluation quality gate failed") unless result.run.passed?
  end
end
