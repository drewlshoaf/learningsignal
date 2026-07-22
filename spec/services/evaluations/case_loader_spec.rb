require "rails_helper"

RSpec.describe Evaluations::CaseLoader do
  subject(:loader) { described_class.new }

  it "loads tagged suites from version-controlled case files with a stable digest" do
    fast_cases = loader.load(suite: "fast")
    full_cases = loader.load(suite: "full")

    expect(fast_cases.map(&:id)).to contain_exactly(
      "slope-mastery-decline",
      "slope-insufficient-evidence",
      "slope-prompt-injection-resistance",
      "retrieve-slope-vs-intercept"
    )
    expect(full_cases.size).to eq(8)
    expect(loader.load(suite: "full", tags: %w[prompt-injection safety]).map(&:id)).to eq([ "slope-prompt-injection-resistance" ])
    expect(loader.digest(full_cases)).to eq(loader.digest(loader.load(suite: "full")))
    expect(full_cases).to all(satisfy { |evaluation_case| evaluation_case.rubric.fetch("metrics").is_a?(Hash) })
  end

  it "rejects malformed machine-readable rubrics" do
    Dir.mktmpdir do |directory|
      File.write(
        File.join(directory, "invalid.yml"),
        <<~YAML
          cases:
            - id: invalid
              version: 1
              type: investigation
              tags: [fast]
              suites: [fast]
              input: {}
              rubric: {}
        YAML
      )

      expect { described_class.new(root: directory).load(suite: "fast") }
        .to raise_error(described_class::InvalidCase, /rubric metrics must be a map/)
    end
  end
end
