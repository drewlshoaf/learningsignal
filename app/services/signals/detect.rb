require "digest"

module Signals
  class Detect
    DECLINE_THRESHOLD = 10

    def initialize(section:)
      @section = section
    end

    def call
      section.students.find_each.flat_map { |student| detect_for(student) }
    end

    private

    attr_reader :section

    def detect_for(student)
      section.course.learning_objectives.filter_map do |objective|
        snapshots = student.mastery_snapshots.where(learning_objective: objective).order(:observed_on).last(2)
        next if snapshots.length < 2

        previous, current = snapshots
        decline = previous.score - current.score
        next if decline < DECLINE_THRESHOLD

        fingerprint = Digest::SHA256.hexdigest([ student.id, objective.id, current.observed_on, "mastery_decline" ].join(":"))
        StudentSignal.find_or_create_by!(organization: section.organization, fingerprint: fingerprint) do |signal|
          signal.school = section.school
          signal.student = student
          signal.section = section
          signal.learning_objective = objective
          signal.kind = "mastery_decline"
          signal.priority = decline >= 15 ? "high" : "medium"
          signal.title = "Mastery dropped #{decline.to_i} points"
          signal.explanation = "#{objective.title} declined from #{previous.score.to_i}% to #{current.score.to_i}% across the two latest checks."
          signal.evidence_data = {
            previous_score: previous.score.to_f,
            current_score: current.score.to_f,
            previous_date: previous.observed_on,
            current_date: current.observed_on
          }
          signal.detected_at = Time.current
        end
      end
    end
  end
end
