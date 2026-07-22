require "rails_helper"

RSpec.describe Retrieval::HybridRanker do
  Record = Data.define(:id, :content)

  it "combines semantic distance and lexical evidence in a deterministic order" do
    relevant = Record.new(id: "relevant", content: "Distinguish slope from the y-intercept on a graph")
    unrelated = Record.new(id: "unrelated", content: "Factor a quadratic expression")

    results = described_class.rank(
      candidates: [ [ unrelated, 0.1 ], [ relevant, 0.2 ] ],
      query: "slope y-intercept graph",
      limit: 2
    )

    expect(results.map { |result| result.record.id }).to eq(%w[relevant unrelated])
    expect(results.first.score).to be > results.last.score
  end
end
