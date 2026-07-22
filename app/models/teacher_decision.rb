class TeacherDecision < ApplicationRecord
  DECISIONS = %w[approved rejected].freeze

  belongs_to :organization
  belongs_to :intervention_plan
  belongs_to :user

  validates :decision, inclusion: { in: DECISIONS }
end
