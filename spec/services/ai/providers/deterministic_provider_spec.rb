require "rails_helper"

RSpec.describe Ai::Providers::DeterministicProvider do
  subject(:provider) { described_class.new }

  it "returns stable, correctly sized embeddings without a network call" do
    first, second = provider.embed(model: "local", inputs: [ "Slope", "Slope" ])

    expect(first.length).to eq(1536)
    expect(first).to eq(second)
  end

  it "only cites identifiers supplied in the input" do
    result = provider.generate(
      model: "local",
      input: "[P1] mastery history\n[C1] curriculum guidance",
      instructions: "grounded",
      schema: {}
    )
    citation_ids = result.dig(:data, "observation", "citation_ids") +
      result.dig(:data, "plan", "actions").flat_map { |action| action.fetch("citation_ids") }

    expect(citation_ids.uniq).to contain_exactly("P1", "C1")
  end
end
