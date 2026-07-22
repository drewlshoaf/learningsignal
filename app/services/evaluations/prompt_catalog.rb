require "digest"

module Evaluations
  class PromptCatalog
    UnknownPrompt = Class.new(StandardError)
    PROMPTS = {
      "investigation-v1" => "config/prompts/investigation/v1.txt",
      "degraded-no-citations" => "config/prompts/evaluation/degraded-no-citations.txt"
    }.freeze

    Prompt = Data.define(:version, :content, :digest)

    def self.fetch(version)
      relative_path = PROMPTS[version.to_s]
      raise UnknownPrompt, "Unknown evaluation prompt: #{version}" unless relative_path

      content = Rails.root.join(relative_path).read
      Prompt.new(version: version.to_s, content:, digest: Digest::SHA256.hexdigest(content))
    end
  end
end
