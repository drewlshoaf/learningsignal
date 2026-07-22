class DashboardController < ApplicationController
  def index
    @section = policy_scope(Section).includes(:course, :students).first!
    authorize @section
    @signals = @section.student_signals.includes(:student, :learning_objective, investigations: :intervention_plan).open_first
    @students = @section.students.order(:first_name, :last_initial)
    @students_count = @section.students.count
    @high_priority_count = @signals.count { |signal| signal.priority == "high" }
    @review_count = @signals.count { |signal| signal.investigations.any? { |investigation| investigation.status == "completed" && investigation.intervention_plan&.status == "draft" } }
    outcomes = InterventionOutcome.joins(intervention_plan: { investigation: :student_signal })
      .where(student_signals: { section_id: @section.id })
    completed_outcomes = outcomes.completed
    @completed_outcome_count = completed_outcomes.count
    @effective_outcome_count = completed_outcomes.where(effectiveness: "effective").count
    @effectiveness_rate = @completed_outcome_count.positive? ? ((@effective_outcome_count.to_f / @completed_outcome_count) * 100).round : 0
    @outcome_follow_up_count = InterventionPlan
      .joins(investigation: :student_signal)
      .left_joins(:intervention_outcome)
      .where(status: "approved", student_signals: { section_id: @section.id })
      .where(intervention_outcomes: { status: [ nil, "in_progress" ] })
      .count
  end
end
