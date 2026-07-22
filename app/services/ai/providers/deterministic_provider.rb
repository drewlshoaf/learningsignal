require "digest"

module Ai
  module Providers
    class DeterministicProvider < Provider
      DIMENSIONS = 1536

      def name = "deterministic"

      def generate(model:, input:, schema:, instructions:, metadata: {})
        citations = input.scan(/\b(?:P|A|C)\d+\b/).uniq
        curriculum_citation = citations.find { |citation| citation.start_with?("C") } || citations.last
        performance_citations = citations.select { |citation| citation.start_with?("P", "A") }.first(3)
        data = if input.include?("EVIDENCE_STATUS: insufficient")
          insufficient_evidence_result(citations.first)
        else
          standard_result(curriculum_citation:, performance_citations:)
        end
        mark_contradictory!(data) if input.include?("EVIDENCE_STATUS: contradictory")
        remove_citations!(data) if instructions.include?("Citations are optional for this evaluation mutation.")

        {
          data:,
          request_id: "local-#{Digest::SHA256.hexdigest([ model, input, instructions ].join("\n"))[0, 12]}",
          model: model,
          input_tokens: input.split.size,
          output_tokens: 184,
          latency_ms: 25
        }
      end

      def embed(model:, inputs:)
        inputs.map { |input| vector_for(input) }
      end

      private

      def vector_for(input)
        vector = Array.new(DIMENSIONS, 0.0)
        input.downcase.scan(/[a-z0-9]+/).each do |token|
          digest = Digest::SHA256.digest(token)
          index = digest.unpack1("L>") % DIMENSIONS
          vector[index] += digest.getbyte(4).even? ? 1.0 : -1.0
        end
        magnitude = Math.sqrt(vector.sum { |value| value**2 })
        return vector if magnitude.zero?

        vector.map { |value| (value / magnitude).round(6) }
      end

      def standard_result(curriculum_citation:, performance_citations:)
        {
          "observation" => {
            "statement" => "The evidence indicates that the student can plot ordered pairs but is inconsistently distinguishing slope from the y-intercept.",
            "confidence" => "high",
            "limitations" => "This conclusion is limited to the supplied mastery history and curriculum evidence.",
            "citation_ids" => (performance_citations + [ curriculum_citation ]).compact.uniq
          },
          "plan" => {
            "summary" => "A focused seven-day sequence to rebuild slope reasoning and verify transfer.",
            "actions" => [
              {
                "title" => "Reconnect slope to rate of change",
                "instructions" => "Review the worked example and ask the student to label rise, run, slope, and y-intercept separately.",
                "duration" => "15 minutes",
                "success_criteria" => "Student correctly identifies slope and y-intercept in four of five examples.",
                "citation_ids" => [ curriculum_citation ].compact
              },
              {
                "title" => "Practice from two points",
                "instructions" => "Complete three scaffolded slope-from-two-points problems, explaining each step aloud.",
                "duration" => "20 minutes",
                "success_criteria" => "Student calculates slope correctly on three consecutive problems.",
                "citation_ids" => (performance_citations + [ curriculum_citation ]).compact.uniq
              },
              {
                "title" => "Run a targeted reassessment",
                "instructions" => "Administer a three-question exit ticket covering graph, table, and equation representations.",
                "duration" => "10 minutes",
                "success_criteria" => "Student answers at least two questions correctly and explains the remaining error.",
                "citation_ids" => performance_citations
              }
            ]
          }
        }
      end

      def insufficient_evidence_result(citation)
        {
          "observation" => {
            "statement" => "The supplied evidence is insufficient to identify a specific learning gap.",
            "confidence" => "low",
            "limitations" => "Insufficient evidence is available; collect another mastery sample before selecting a targeted explanation.",
            "citation_ids" => [ citation ].compact
          },
          "plan" => {
            "summary" => "A cautious evidence-gathering sequence for teacher review before a targeted intervention is selected.",
            "actions" => [
              evidence_gathering_action("Collect a current mastery sample", "Administer a brief teacher-selected check aligned to the objective.", citation),
              evidence_gathering_action("Review the response with the student", "Ask the student to explain the strategy used without suggesting a diagnosis.", citation),
              evidence_gathering_action("Reassess intervention readiness", "Compare the new response with the existing evidence and decide whether a targeted plan is justified.", citation)
            ]
          }
        }
      end

      def evidence_gathering_action(title, instructions, citation)
        {
          "title" => title,
          "instructions" => instructions,
          "duration" => "10 minutes",
          "success_criteria" => "The teacher has one additional objective-aligned evidence point for review.",
          "citation_ids" => [ citation ].compact
        }
      end

      def remove_citations!(data)
        data.dig("observation", "citation_ids").clear
        data.dig("plan", "actions").each { |action| action.fetch("citation_ids").clear }
      end

      def mark_contradictory!(data)
        data.dig("observation", "confidence").replace("medium")
        data.dig("observation", "limitations").replace(
          "The supplied evidence is contradictory across representations, so the teacher should verify transfer before drawing a stronger conclusion."
        )
      end
    end
  end
end
