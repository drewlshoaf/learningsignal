require "digest"

module Ai
  module Providers
    class DeterministicProvider < Provider
      DIMENSIONS = 1536

      def name = "deterministic"

      def generate(model:, input:, schema:, instructions:, metadata: {})
        citations = input.scan(/\b(?:P|C)\d+\b/).uniq
        curriculum_citation = citations.find { |citation| citation.start_with?("C") } || citations.last
        performance_citations = citations.select { |citation| citation.start_with?("P") }.first(2)

        {
          data: {
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
          },
          request_id: "local-#{SecureRandom.hex(6)}",
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
        digest = Digest::SHA256.digest(input.downcase)
        Array.new(DIMENSIONS) { |index| ((digest.getbyte(index % digest.bytesize) / 255.0) * 2 - 1).round(6) }
      end
    end
  end
end
