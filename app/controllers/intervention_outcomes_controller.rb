class InterventionOutcomesController < ApplicationController
  before_action :set_plan
  before_action :set_outcome

  def new
    authorize @outcome
    load_form_context
  end

  def create
    authorize @outcome
    save_outcome("Outcome saved. The intervention feedback loop is now up to date.")
  end

  def edit
    authorize @outcome
    load_form_context
  end

  def update
    authorize @outcome
    save_outcome("Outcome updated.")
  end

  private

  def set_plan
    @plan = InterventionPlan.includes(
      :intervention_actions,
      :intervention_outcome,
      investigation: [ :school, :retrieved_evidences, { student_signal: [ :section, :learning_objective, :student ] } ]
    ).find(params[:intervention_plan_id])
  end

  def set_outcome
    @outcome = @plan.intervention_outcome || @plan.build_intervention_outcome(
      organization: @plan.organization,
      recorded_by: current_user,
      recorded_at: Time.current
    )
  end

  def save_outcome(notice)
    InterventionOutcomes::Record.call(
      outcome: @outcome,
      actor: current_user,
      attributes: outcome_params,
      completed_action_ids: params.dig(:intervention_outcome, :completed_action_ids),
      mastery_snapshot_id: params.dig(:intervention_outcome, :mastery_snapshot_id),
      request_id: request.request_id
    )
    redirect_to investigation_path(@plan.investigation, anchor: "intervention-outcome"), notice: notice
  rescue ActiveRecord::RecordInvalid
    load_form_context
    render(@outcome.persisted? ? :edit : :new, status: :unprocessable_entity)
  end

  def load_form_context
    @baseline_mastery = @plan.baseline_mastery_snapshot
    @mastery_snapshots = @plan.investigation.student.mastery_snapshots
      .where(section: @plan.investigation.section, learning_objective: @plan.investigation.learning_objective)
      .where(observed_on: (@plan.approved_at || @plan.created_at).to_date..)
      .where.not("source LIKE ?", "Intervention outcome %")
      .where.not(id: @baseline_mastery&.id)
      .order(observed_on: :desc)
  end

  def outcome_params
    params.require(:intervention_outcome).permit(
      :status,
      :effectiveness,
      :follow_up_mastery_score,
      :teacher_assessment,
      :student_completed,
      :notes
    )
  end
end
