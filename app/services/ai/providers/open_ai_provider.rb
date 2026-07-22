module Ai
  module Providers
    class OpenAiProvider < ResponsesProvider
      def initialize(transport: nil)
        super(
          provider_name: "openai",
          base_url: ENV.fetch("OPENAI_BASE_URL", "https://api.openai.com/v1"),
          api_key: ENV["OPENAI_API_KEY"],
          transport: transport
        )
      end

      def generate(**)
        ensure_api_key!
        super
      end

      def embed(**)
        ensure_api_key!
        super
      end

      private

      def test_transport?
        Rails.env.test?
      end

      def ensure_api_key!
        return if ENV["OPENAI_API_KEY"].present? || test_transport?

        raise ProviderError, "OPENAI_API_KEY is required for the OpenAI provider"
      end
    end
  end
end
