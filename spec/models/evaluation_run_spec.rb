require "rails_helper"

RSpec.describe EvaluationRun do
  it "owns versioned case results and only accepts lifecycle statuses" do
    run = described_class.create!(
      suite: "fast",
      status: "running",
      provider: "deterministic",
      model: "local",
      prompt_version: "investigation-v1",
      prompt_digest: "prompt-digest",
      cases_digest: "cases-digest",
      git_sha: "test-sha",
      started_at: Time.current
    )
    result = run.evaluation_results.create!(
      case_id: "case-1",
      case_version: 1,
      case_type: "investigation",
      status: "passed"
    )

    expect(result).to be_passed
    expect { run.update!(status: "unknown") }.to raise_error(ActiveRecord::RecordInvalid)
  end
end
