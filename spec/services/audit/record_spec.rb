require "rails_helper"

RSpec.describe Audit::Record do
  it "links tenant events into a tamper-evident hash chain" do
    scenario = build_learning_scenario
    first = described_class.call(
      organization: scenario.fetch(:organization),
      school: scenario.fetch(:school),
      user: scenario.fetch(:teacher),
      auditable: scenario.fetch(:signal),
      action: "signal.reviewed"
    )
    second = described_class.call(
      organization: scenario.fetch(:organization),
      school: scenario.fetch(:school),
      user: scenario.fetch(:teacher),
      auditable: scenario.fetch(:signal),
      action: "signal.reopened"
    )

    expect(first.previous_hash).to be_nil
    expect(second.previous_hash).to eq(first.event_hash)
    expect(second.event_hash).not_to eq(first.event_hash)
  end
end
