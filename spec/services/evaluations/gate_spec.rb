require "rails_helper"

RSpec.describe Evaluations::Gate do
  it "reports every configurable minimum and maximum threshold regression" do
    gate = described_class.new(
      metrics: { "groundedness" => 0.75, "unsupported_claim_rate" => 0.25 },
      thresholds: {
        "minimum" => { "groundedness" => 1.0 },
        "maximum" => { "unsupported_claim_rate" => 0.0 }
      }
    )

    expect(gate).not_to be_passed
    expect(gate.failures.map(&:metric)).to contain_exactly("groundedness", "unsupported_claim_rate")
  end
end
