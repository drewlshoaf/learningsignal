require "rails_helper"

RSpec.describe "Responses API providers" do
  class CapturingTransport
    attr_reader :calls

    def initialize
      @calls = []
    end

    def post(path, payload)
      calls << [ path, payload ]
      return { "data" => [ { "index" => 0, "embedding" => [ 0.1, 0.2 ] } ] } if path == "embeddings"

      {
        "id" => "resp_test",
        "model" => "test-model",
        "usage" => { "input_tokens" => 12, "output_tokens" => 34 },
        "output" => [
          {
            "content" => [
              { "type" => "output_text", "text" => JSON.generate("observation" => {}, "plan" => {}) }
            ]
          }
        ]
      }
    end
  end

  [ Ai::Providers::OpenAiProvider, Ai::Providers::CompatibleProvider ].each do |provider_class|
    it "uses the same strict, non-stored Responses contract for #{provider_class.name.demodulize}" do
      transport = CapturingTransport.new
      provider = provider_class.new(transport:)
      schema = Ai::Schemas::InvestigationResult.definition

      result = provider.generate(model: "test-model", input: "Evidence", instructions: "Stay grounded", schema:, metadata: { investigation_id: 7 })
      path, payload = transport.calls.fetch(0)

      expect(path).to eq("responses")
      expect(payload).to include(model: "test-model", store: false, metadata: { investigation_id: "7" })
      expect(payload.dig(:text, :format)).to include(type: "json_schema", strict: true, schema:)
      expect(payload.fetch(:input).map { |message| message.fetch(:role) }).to eq(%w[developer user])
      expect(result).to include(request_id: "resp_test", model: "test-model", input_tokens: 12, output_tokens: 34)
    end

    it "uses the embeddings endpoint for #{provider_class.name.demodulize}" do
      transport = CapturingTransport.new
      provider = provider_class.new(transport:)

      expect(provider.embed(model: "embed-test", inputs: [ "slope" ])).to eq([ [ 0.1, 0.2 ] ])
      expect(transport.calls.fetch(0)).to eq([ "embeddings", { model: "embed-test", input: [ "slope" ] } ])
    end
  end
end
