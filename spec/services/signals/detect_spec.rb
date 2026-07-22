require "rails_helper"

RSpec.describe Signals::Detect do
  it "creates one idempotent, high-priority signal for a material decline" do
    scenario = build_learning_scenario

    expect(scenario.fetch(:signal)).to have_attributes(
      priority: "high",
      status: "open",
      kind: "mastery_decline"
    )
    expect { described_class.new(section: scenario.fetch(:section)).call }
      .not_to change(StudentSignal, :count)
  end

  it "does not create a signal when the decline is below the threshold" do
    scenario = build_learning_scenario
    scenario.fetch(:signal).destroy!
    scenario.fetch(:student).mastery_snapshots.order(:observed_on).last.update!(score: 70)

    expect(described_class.new(section: scenario.fetch(:section)).call).to be_empty
  end
end
