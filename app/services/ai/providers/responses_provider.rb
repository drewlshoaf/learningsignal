module Ai
  module Providers
    class ResponsesProvider < Provider
      def initialize(provider_name:, base_url:, api_key:, transport: nil)
        @provider_name = provider_name
        @transport = transport || HttpTransport.new(base_url: base_url, api_key: api_key)
      end

      attr_reader :provider_name
      alias_method :name, :provider_name

      def generate(model:, input:, schema:, instructions:, metadata: {})
        started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        response = @transport.post("responses", response_payload(model:, input:, schema:, instructions:, metadata:))
        output_text = extract_output_text(response)

        {
          data: JSON.parse(output_text),
          request_id: response["id"],
          model: response["model"] || model,
          input_tokens: response.dig("usage", "input_tokens").to_i,
          output_tokens: response.dig("usage", "output_tokens").to_i,
          latency_ms: elapsed_ms(started)
        }
      rescue JSON::ParserError => error
        raise ProviderError, "Structured output was not valid JSON: #{error.message}"
      end

      def embed(model:, inputs:)
        response = @transport.post("embeddings", { model: model, input: inputs })
        response.fetch("data").sort_by { |item| item.fetch("index") }.map { |item| item.fetch("embedding") }
      rescue KeyError => error
        raise ProviderError, "Embedding response was incomplete: #{error.message}"
      end

      private

      def response_payload(model:, input:, schema:, instructions:, metadata:)
        {
          model: model,
          reasoning: { effort: Configuration.reasoning_effort },
          input: [
            { role: "developer", content: [ { type: "input_text", text: instructions } ] },
            { role: "user", content: [ { type: "input_text", text: input } ] }
          ],
          text: {
            format: {
              type: "json_schema",
              name: "learning_signal_investigation",
              strict: true,
              schema: schema
            }
          },
          metadata: metadata.compact.transform_values(&:to_s),
          store: false
        }
      end

      def extract_output_text(response)
        text = response.fetch("output", []).flat_map { |item| item.fetch("content", []) }
          .find { |content| content["type"] == "output_text" }
          &.fetch("text", nil)
        raise ProviderError, "Provider response did not contain output text" if text.blank?

        text
      end

      def elapsed_ms(started)
        ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round
      end
    end
  end
end
