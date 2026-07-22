class StudentsController < ApplicationController
  def show
    @student = policy_scope(Student).find(params[:id])
    authorize @student
    @sections = policy_scope(Section)
      .joins(:enrollments)
      .where(enrollments: { student_id: @student.id })
      .includes(:course)
      .order(:name)

    @mastery_snapshots = @student.mastery_snapshots
      .where(section: @sections)
      .includes(:learning_objective, section: :course)
      .order(observed_on: :desc)
    @latest_mastery = @mastery_snapshots
      .group_by(&:learning_objective)
      .values
      .map { |snapshots| snapshots.max_by(&:observed_on) }
      .sort_by { |snapshot| snapshot.learning_objective.code }

    @assessment_attempts = @student.assessment_attempts
      .where(section: @sections)
      .includes(:assessment, :section, question_responses: { assessment_question: :learning_objective })
      .order(submitted_at: :desc, created_at: :desc)
    @signals = @student.student_signals
      .where(section: @sections)
      .includes(:learning_objective, :section, investigations: { intervention_plan: :intervention_outcome })
      .order(detected_at: :desc)
    @intervention_outcomes = InterventionOutcome
      .joins(intervention_plan: { investigation: :student_signal })
      .where(student_signals: { student_id: @student.id, section_id: @sections.select(:id) })
      .includes(:recorded_by, intervention_plan: { investigation: [ :retrieved_evidences, { student_signal: :learning_objective } ] })
      .order(recorded_at: :desc)

    @average_mastery = if @latest_mastery.any?
      (@latest_mastery.sum(&:score) / @latest_mastery.length).round
    else
      0
    end
    @activity_items = build_activity_items
  end

  private

  def build_activity_items
    attempt_items = @assessment_attempts.filter_map do |attempt|
      next if attempt.submitted_at.blank?

      {
        at: attempt.submitted_at,
        kind: "Assessment",
        title: attempt.assessment.title,
        detail: "#{attempt.score.to_i}/#{attempt.maximum_score.to_i} points · #{attempt.percentage.to_i}%"
      }
    end
    mastery_items = @mastery_snapshots.map do |snapshot|
      {
        at: snapshot.observed_on.in_time_zone,
        kind: "Mastery",
        title: snapshot.learning_objective.title,
        detail: "#{snapshot.score.to_i}% · #{snapshot.source}"
      }
    end
    signal_items = @signals.map do |signal|
      { at: signal.detected_at, kind: "Signal", title: signal.title, detail: signal.explanation }
    end
    outcome_items = @intervention_outcomes.map do |outcome|
      {
        at: outcome.recorded_at,
        kind: "Outcome",
        title: outcome.intervention_plan.investigation.learning_objective.title,
        detail: "#{outcome.status.humanize} · #{outcome.follow_up_mastery_score ? "#{outcome.follow_up_mastery_score.to_i}% follow-up mastery" : 'Follow-up mastery pending'} · #{outcome.effectiveness&.humanize || 'Not rated'}"
      }
    end

    (attempt_items + mastery_items + signal_items + outcome_items).sort_by { |item| item.fetch(:at) }.reverse.first(12)
  end
end
