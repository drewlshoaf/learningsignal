require "rails_helper"

RSpec.describe Evaluations::Runner do
  it "persists a reproducible full run with metrics, usage, latency, and reports" do
    Dir.mktmpdir do |report_dir|
      result = described_class.new(suite: "full", output_dir: report_dir, git_sha: "test-revision").call
      run = result.run

      expect(run).to be_passed
      expect(run).to have_attributes(
        provider: "deterministic",
        model: "deterministic-v1",
        prompt_version: "investigation-v1",
        git_sha: "test-revision",
        input_tokens: be_positive,
        output_tokens: be_positive,
        estimated_cost_usd: 0
      )
      expect(run.evaluation_results.count).to eq(8)
      expect(run.metrics).to include(
        "pass_rate" => 1.0,
        "retrieval_precision" => 1.0,
        "retrieval_recall" => 1.0,
        "citation_validity" => 1.0,
        "groundedness" => 1.0,
        "prompt_injection_resistance" => 1.0
      )
      expect(result.report.markdown_path.read).to include("Status:** PASSED", "Gate failures", "None.")
      expect(JSON.parse(result.report.json_path.read).dig("run", "cases_digest")).to eq(run.cases_digest)
    end
  end

  it "persists and reports a blocking regression for the deliberately degraded prompt" do
    Dir.mktmpdir do |report_dir|
      result = described_class.new(
        suite: "fast",
        prompt_version: "degraded-no-citations",
        output_dir: report_dir
      ).call

      expect(result.run).to have_attributes(status: "failed")
      expect(result.run.metrics.fetch("pass_rate")).to eq(0.25)
      expect(result.run.gate_failures.map { |failure| failure.fetch("metric") }).to include(
        "pass_rate",
        "citation_validity",
        "citation_completeness",
        "groundedness"
      )
      expect(result.report.markdown_path.read).to include("Status:** FAILED", "citation_validity")
    end
  end

  it "supports focused tag runs without requiring metrics from excluded case types" do
    Dir.mktmpdir do |report_dir|
      result = described_class.new(
        suite: "full",
        tags: %w[prompt-injection safety],
        output_dir: report_dir
      ).call

      expect(result.run).to be_passed
      expect(result.run.evaluation_results.pluck(:case_id)).to eq([ "slope-prompt-injection-resistance" ])
      expect(result.run.metrics).to include("prompt_injection_resistance" => 1.0, "pass_rate" => 1.0)
      expect(result.run.metrics).not_to include("retrieval_precision")
    end
  end
end
