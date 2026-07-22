class InterventionPlanPolicy < ApplicationPolicy
  def approve? = update?
  def reject? = update?
end
