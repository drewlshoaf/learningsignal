module Ai
  module Providers
    class CompatibleProvider < ResponsesProvider
      def initialize(transport: nil)
        super(
          provider_name: "compatible",
          base_url: ENV.fetch("COMPATIBLE_AI_BASE_URL", "http://host.docker.internal:11434/v1"),
          api_key: ENV["COMPATIBLE_AI_API_KEY"],
          transport: transport
        )
      end
    end
  end
end
