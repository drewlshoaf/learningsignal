require "rails_helper"

RSpec.describe StudentSignalPolicy do
  it "allows members of the signal organization" do
    scenario = build_learning_scenario

    expect(described_class.new(scenario.fetch(:teacher), scenario.fetch(:signal)).show?).to be(true)
  end

  it "rejects users from another tenant" do
    scenario = build_learning_scenario
    outsider = User.create!(name: "Outsider", email_address: "outside@example.test", password: "test-password")

    expect(described_class.new(outsider, scenario.fetch(:signal)).show?).to be(false)
  end
end
