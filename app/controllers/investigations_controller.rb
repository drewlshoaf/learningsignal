class InvestigationsController < ApplicationController
  def create
    signal = StudentSignal.find(params[:student_signal_id])
    authorize signal, :investigate?
    investigation = Investigations::Create.call(signal: signal, teacher: current_user, request_id: request.request_id)
    redirect_to investigation_path(investigation), notice: "Investigation started."
  end

  def show
    @investigation = Investigation.includes(
      :student_signal,
      :agent_runs,
      :retrieved_evidences,
      investigation_observations: :retrieved_evidences,
      intervention_plan: :intervention_actions
    ).find(params[:id])
    authorize @investigation
  end
end
