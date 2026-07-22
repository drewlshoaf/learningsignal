class DashboardController < ApplicationController
  def index
    @section = policy_scope(Section).includes(:course, :students).first!
    authorize @section
    @signals = @section.student_signals.includes(:student, :learning_objective, investigations: :intervention_plan).open_first
    @students = @section.students.order(:first_name, :last_initial)
    @students_count = @section.students.count
    @high_priority_count = @signals.count { |signal| signal.priority == "high" }
    @review_count = @signals.count { |signal| signal.investigations.any? { |investigation| investigation.status == "completed" && investigation.intervention_plan&.status == "draft" } }
  end
end
