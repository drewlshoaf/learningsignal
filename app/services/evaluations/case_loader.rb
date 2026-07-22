require "digest"
require "yaml"

module Evaluations
  class CaseLoader
    InvalidCase = Class.new(StandardError)
    CaseDefinition = Data.define(:id, :version, :type, :tags, :suites, :input, :rubric, :source) do
      def digest_payload
        { id:, version:, type:, tags:, suites:, input:, rubric: }
      end
    end

    def initialize(root: Rails.root.join("config/evaluations/cases"))
      @root = Pathname(root)
    end

    def load(suite:, tags: [])
      cases = root.glob("*.yml").sort.flat_map { |path| load_file(path) }
      duplicate_ids = cases.group_by(&:id).select { |_id, matches| matches.many? }.keys
      raise InvalidCase, "Duplicate evaluation case IDs: #{duplicate_ids.join(', ')}" if duplicate_ids.any?

      selected = cases.select { |evaluation_case| evaluation_case.suites.include?(suite.to_s) }
      requested_tags = Array(tags).map(&:to_s)
      return selected if requested_tags.empty?

      selected.select { |evaluation_case| (requested_tags - evaluation_case.tags).empty? }
    end

    def digest(cases)
      Digest::SHA256.hexdigest(JSON.generate(cases.map(&:digest_payload)))
    end

    private

    attr_reader :root

    def load_file(path)
      document = YAML.safe_load(path.read, aliases: false)
      Array(document.fetch("cases")).map { |attributes| build_case(attributes, path) }
    rescue KeyError, Psych::Exception => error
      raise InvalidCase, "#{path}: #{error.message}"
    end

    def build_case(attributes, path)
      required = %w[id version type tags suites input rubric]
      missing = required - attributes.keys
      raise InvalidCase, "#{path}: missing #{missing.join(', ')}" if missing.any?
      raise InvalidCase, "#{path}: unsupported type #{attributes['type']}" unless EvaluationResult::CASE_TYPES.include?(attributes["type"])
      raise InvalidCase, "#{path}: rubric metrics must be a map" unless attributes.dig("rubric", "metrics").is_a?(Hash)

      CaseDefinition.new(
        id: attributes.fetch("id"),
        version: attributes.fetch("version"),
        type: attributes.fetch("type"),
        tags: Array(attributes.fetch("tags")).map(&:to_s).sort,
        suites: Array(attributes.fetch("suites")).map(&:to_s).sort,
        input: attributes.fetch("input"),
        rubric: attributes.fetch("rubric"),
        source: path.relative_path_from(Rails.root).to_s
      )
    end
  end
end
