require "rails_helper"

RSpec.describe Investigations::GroundingValidator do
  let(:evidence) { [ Struct.new(:citation_id).new("P1"), Struct.new(:citation_id).new("C1") ] }
  let(:result) do
    {
      "observation" => { "citation_ids" => [ "P1" ] },
      "plan" => { "actions" => [ { "citation_ids" => [ "C1" ] } ] }
    }
  end

  it "accepts results whose claims cite known evidence" do
    expect(described_class.new(result:, evidence:).validate!).to be(true)
  end

  it "rejects invented citation identifiers" do
    result.fetch("observation")["citation_ids"] = [ "C99" ]

    expect { described_class.new(result:, evidence:).validate! }
      .to raise_error(described_class::InvalidCitation, /C99/)
  end

  it "requires a citation on every action" do
    result.dig("plan", "actions").first["citation_ids"] = []

    expect { described_class.new(result:, evidence:).validate! }
      .to raise_error(described_class::InvalidCitation, /Every plan action/)
  end
end
