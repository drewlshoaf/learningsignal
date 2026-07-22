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
      .includes(:learning_objective, :section, investigations: :intervention_plan)
      .order(detected_at: :desc)

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

    (attempt_items + mastery_items + signal_items).sort_by { |item| item.fetch(:at) }.reverse.first(12)
  end
end
