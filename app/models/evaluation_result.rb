class EvaluationResult < ApplicationRecord
  STATUSES = %w[passed failed errored].freeze
  CASE_TYPES = %w[investigation retrieval].freeze

  belongs_to :evaluation_run

  validates :case_id, :case_version, presence: true
  validates :case_id, uniqueness: { scope: :evaluation_run_id }
  validates :case_type, inclusion: { in: CASE_TYPES }
  validates :status, inclusion: { in: STATUSES }
  validates :input_tokens, :output_tokens, :latency_ms, numericality: { greater_than_or_equal_to: 0 }
  validates :estimated_cost_usd, numericality: { greater_than_or_equal_to: 0 }

  def passed? = status == "passed"
end
