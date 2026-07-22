module Ai
  module Schemas
    class InvestigationResult
      def self.definition
        {
          type: "object",
          additionalProperties: false,
          required: %w[observation plan],
          properties: {
            observation: {
              type: "object",
              additionalProperties: false,
              required: %w[statement confidence limitations citation_ids],
              properties: {
                statement: { type: "string" },
                confidence: { type: "string", enum: %w[low medium high] },
                limitations: { type: "string" },
                citation_ids: { type: "array", minItems: 1, items: { type: "string" } }
              }
            },
            plan: {
              type: "object",
              additionalProperties: false,
              required: %w[summary actions],
              properties: {
                summary: { type: "string" },
                actions: {
                  type: "array",
                  minItems: 3,
                  maxItems: 3,
                  items: {
                    type: "object",
                    additionalProperties: false,
                    required: %w[title instructions duration success_criteria citation_ids],
                    properties: {
                      title: { type: "string" },
                      instructions: { type: "string" },
                      duration: { type: "string" },
                      success_criteria: { type: "string" },
                      citation_ids: { type: "array", minItems: 1, items: { type: "string" } }
                    }
                  }
                }
              }
            }
          }
        }
      end
    end
  end
end
