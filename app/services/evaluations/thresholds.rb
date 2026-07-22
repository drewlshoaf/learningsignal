require "erb"
require "yaml"

module Evaluations
  class Thresholds
    UnknownSuite = Class.new(StandardError)

    def self.for(suite, path: Rails.root.join("config/evaluations/thresholds.yml"))
      settings = YAML.safe_load(ERB.new(Pathname(path).read).result, aliases: false)
      settings.fetch(suite.to_s)
    rescue KeyError
      raise UnknownSuite, "No evaluation thresholds configured for suite: #{suite}"
    end
  end
end
