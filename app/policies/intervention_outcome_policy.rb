class InterventionOutcomePolicy < ApplicationPolicy
  def show? = educator_for_plan?
  def create? = educator_for_plan? && record.intervention_plan.status == "approved"
  def update? = create?
  def new? = create?
  def edit? = update?

  private

  def educator_for_plan?
    plan = record.intervention_plan
    return false unless user.present? && plan.present?
    return true if plan.investigation.section.teacher_id == user.id

    user.memberships.exists?(
      organization_id: plan.organization_id,
      school_id: plan.investigation.school_id,
      role: %w[instructional_coach school_admin platform_admin]
    )
  end
end
