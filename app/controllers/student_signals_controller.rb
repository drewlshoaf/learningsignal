class StudentSignalsController < ApplicationController
  def show
    @signal = StudentSignal.includes(:student, :section, :learning_objective, :investigations).find(params[:id])
    authorize @signal
    @mastery_snapshots = @signal.student.mastery_snapshots.where(learning_objective: @signal.learning_objective).order(:observed_on)
    @investigation = @signal.investigations.order(created_at: :desc).first
  end
end
