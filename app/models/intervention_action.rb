class InterventionAction < ApplicationRecord
  COMPLETION_STATUSES = %w[pending completed].freeze

  belongs_to :intervention_plan
  belongs_to :learning_objective, optional: true

  validates :position, :title, :instructions, :duration, :success_criteria, presence: true
  validates :completion_status, inclusion: { in: COMPLETION_STATUSES }
  validates :required, inclusion: { in: [ true, false ] }
  validates :position, uniqueness: { scope: :intervention_plan_id }
end
