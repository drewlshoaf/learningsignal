module Ai
  class ProviderRegistry
    PROVIDERS = {
      "deterministic" => Providers::DeterministicProvider,
      "openai" => Providers::OpenAiProvider,
      "compatible" => Providers::CompatibleProvider
    }.freeze

    def self.fetch(name = Configuration.provider)
      provider_class = PROVIDERS[name.to_s]
      raise ProviderError, "Unknown AI provider: #{name}" unless provider_class

      provider_class.new
    end
  end
end
