class InterventionAction < ApplicationRecord
  belongs_to :intervention_plan
  belongs_to :learning_objective, optional: true

  validates :position, :title, :instructions, :duration, :success_criteria, presence: true
  validates :position, uniqueness: { scope: :intervention_plan_id }
end
