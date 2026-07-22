class InterventionPlansController < ApplicationController
  before_action :set_plan

  def edit
    authorize @plan
  end

  def update
    authorize @plan
    if @plan.update(plan_params)
      Audit::Record.call(
        organization: @plan.organization,
        school: @plan.investigation.school,
        user: current_user,
        auditable: @plan,
        action: "intervention_plan.edited",
        changes: { snapshot: @plan.snapshot },
        request_id: request.request_id
      )
      redirect_to investigation_path(@plan.investigation), notice: "Plan edits saved."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def approve
    authorize @plan, :approve?
    decide!("approved")
    redirect_to investigation_path(@plan.investigation), notice: "Intervention plan approved."
  end

  def reject
    authorize @plan, :reject?
    decide!("rejected")
    redirect_to investigation_path(@plan.investigation), notice: "Intervention plan rejected."
  end

  private

  def set_plan
    @plan = InterventionPlan.includes(:intervention_actions, investigation: :school).find(params[:id])
  end

  def plan_params
    params.require(:intervention_plan).permit(
      :summary,
      :teacher_notes,
      intervention_actions_attributes: %i[id title instructions duration success_criteria]
    )
  end

  def decide!(decision)
    InterventionPlan.transaction do
      timestamp_attributes = decision == "approved" ? { approved_at: Time.current } : { rejected_at: Time.current }
      @plan.update!({ status: decision }.merge(timestamp_attributes))
      @plan.teacher_decisions.create!(
        organization: @plan.organization,
        user: current_user,
        decision: decision,
        reason: params[:reason],
        plan_snapshot: @plan.snapshot
      )
      Audit::Record.call(
        organization: @plan.organization,
        school: @plan.investigation.school,
        user: current_user,
        auditable: @plan,
        action: "intervention_plan.#{decision}",
        changes: { status: decision },
        request_id: request.request_id
      )
    end
  end
end
