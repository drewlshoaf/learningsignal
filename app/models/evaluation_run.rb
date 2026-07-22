class EvaluationRun < ApplicationRecord
  STATUSES = %w[running passed failed errored].freeze

  has_many :evaluation_results, dependent: :destroy

  validates :suite, :provider, :model, :prompt_version, :prompt_digest, :cases_digest, :git_sha, :started_at, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :input_tokens, :output_tokens, :latency_ms, numericality: { greater_than_or_equal_to: 0 }
  validates :estimated_cost_usd, numericality: { greater_than_or_equal_to: 0 }

  scope :recent_first, -> { order(created_at: :desc) }

  def passed? = status == "passed"
end
