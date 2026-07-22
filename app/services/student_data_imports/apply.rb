require "time"

module StudentDataImports
  class Apply
    def initialize(data_import:, request_id: nil)
      @data_import = data_import
      @request_id = request_id
    end

    def call
      raise ArgumentError, "Only a valid preview can be imported." unless data_import.confirmable?

      data_import.update!(status: "applying", failure_message: nil)
      result = Parse.new(data_import:).call
      return mark_invalid(result) if result.errors.any?

      StudentDataImport.transaction do
        applied = apply_rows(result.rows)
        generated_signals = if data_import.import_type.in?(%w[mastery assessment_responses])
          detect_new_signals
        else
          0
        end
        completed_summary = applied.merge("signals_detected" => generated_signals)
        data_import.update!(
          status: "completed",
          applied_summary: completed_summary,
          completed_at: Time.current,
          failure_message: nil
        )
        record_audit("student_data_import.completed", completed_summary)
        completed_summary
      end
      data_import
    rescue StandardError => error
      mark_failed(error)
      raise
    end

    private

    attr_reader :data_import, :request_id

    def apply_rows(rows)
      case data_import.import_type
      when "roster" then apply_roster(rows)
      when "mastery" then apply_mastery(rows)
      when "assessment_catalog" then apply_assessment_catalog(rows)
      when "assessment_responses" then apply_assessment_responses(rows)
      else raise ArgumentError, "Unsupported import type."
      end
    end

    def apply_roster(rows)
      summary = { "students_created" => 0, "students_updated" => 0, "enrollments_created" => 0 }

      rows.each do |row|
        student = Student.find_or_initialize_by(
          organization: data_import.organization,
          external_ref: row.fetch("student_external_ref")
        )
        student_was_new = student.new_record?
        student.assign_attributes(
          school: data_import.school,
          first_name: row.fetch("first_name"),
          last_initial: row.fetch("last_initial"),
          synthetic: true
        )
        student.save!
        summary[student_was_new ? "students_created" : "students_updated"] += 1

        enrollment = Enrollment.find_or_initialize_by(section: data_import.section, student:)
        if enrollment.new_record?
          enrollment.organization = data_import.organization
          enrollment.status = "active"
          enrollment.save!
          summary["enrollments_created"] += 1
        end
      end

      summary
    end

    def apply_mastery(rows)
      students = data_import.section.students.where(external_ref: rows.pluck("student_external_ref")).index_by(&:external_ref)
      objectives = data_import.section.course.learning_objectives.where(code: rows.pluck("objective_code")).index_by(&:code)
      summary = { "snapshots_created" => 0, "snapshots_updated" => 0 }

      rows.each do |row|
        snapshot = MasterySnapshot.find_or_initialize_by(
          organization: data_import.organization,
          section: data_import.section,
          student: students.fetch(row.fetch("student_external_ref")),
          learning_objective: objectives.fetch(row.fetch("objective_code")),
          observed_on: Date.iso8601(row.fetch("observed_on")),
          source: row.fetch("source")
        )
        summary[snapshot.new_record? ? "snapshots_created" : "snapshots_updated"] += 1
        snapshot.score = row.fetch("score")
        snapshot.save!
      end

      summary
    end

    def apply_assessment_catalog(rows)
      objectives = data_import.section.course.learning_objectives
        .where(code: rows.pluck("objective_code").uniq)
        .index_by(&:code)
      summary = {
        "assessments_created" => 0,
        "assessments_updated" => 0,
        "questions_created" => 0,
        "questions_updated" => 0
      }

      rows.group_by { |row| row.fetch("assessment_external_ref") }.each do |external_ref, assessment_rows|
        first_row = assessment_rows.first
        assessment = Assessment.find_or_initialize_by(
          organization: data_import.organization,
          external_ref:
        )
        summary[assessment.new_record? ? "assessments_created" : "assessments_updated"] += 1
        assessment.assign_attributes(
          course: data_import.section.course,
          title: first_row.fetch("assessment_title"),
          assessment_type: first_row.fetch("assessment_type"),
          status: first_row.fetch("assessment_status"),
          synthetic: true
        )
        assessment.save!

        assessment_rows.each do |row|
          question = assessment.assessment_questions.find_or_initialize_by(
            external_ref: row.fetch("question_external_ref")
          )
          summary[question.new_record? ? "questions_created" : "questions_updated"] += 1
          question.assign_attributes(
            organization: data_import.organization,
            learning_objective: objectives.fetch(row.fetch("objective_code")),
            prompt_reference: row.fetch("prompt_reference"),
            question_type: row.fetch("question_type"),
            maximum_points: row.fetch("maximum_points"),
            metadata: { "answer_key" => row.fetch("answer_key") }
          )
          question.save!
        end
        assessment.recalculate_maximum_score!
      end

      summary
    end

    def apply_assessment_responses(rows)
      students = data_import.section.students
        .where(external_ref: rows.pluck("student_external_ref").uniq)
        .index_by(&:external_ref)
      assessments = data_import.section.course.assessments
        .where(external_ref: rows.pluck("assessment_external_ref").uniq)
        .includes(:assessment_questions)
        .index_by(&:external_ref)
      summary = {
        "attempts_created" => 0,
        "attempts_updated" => 0,
        "responses_created" => 0,
        "responses_updated" => 0,
        "snapshots_created" => 0,
        "snapshots_updated" => 0
      }

      rows.group_by { |row| row.fetch("attempt_external_ref") }.each do |external_ref, attempt_rows|
        first_row = attempt_rows.first
        assessment = assessments.fetch(first_row.fetch("assessment_external_ref"))
        student = students.fetch(first_row.fetch("student_external_ref"))
        attempt = AssessmentAttempt.find_or_initialize_by(
          organization: data_import.organization,
          section: data_import.section,
          external_ref:
        )
        summary[attempt.new_record? ? "attempts_created" : "attempts_updated"] += 1
        submitted_at = Time.iso8601(first_row.fetch("submitted_at"))
        attempt.assign_attributes(
          student:,
          assessment:,
          attempt_number: first_row.fetch("attempt_number"),
          status: first_row.fetch("status"),
          started_at: attempt.started_at || submitted_at,
          submitted_at:,
          synthetic: true
        )
        attempt.save!

        questions = assessment.assessment_questions.index_by(&:external_ref)
        attempt_rows.each do |row|
          question = questions.fetch(row.fetch("question_external_ref"))
          response = attempt.question_responses.find_or_initialize_by(assessment_question: question)
          summary[response.new_record? ? "responses_created" : "responses_updated"] += 1
          answer = row.fetch("selected_answer").presence || row.fetch("response_text")
          correct = normalized_answer(answer) == normalized_answer(question.answer_key)
          response.assign_attributes(
            organization: data_import.organization,
            selected_answer: row.fetch("selected_answer").presence,
            response_text: row.fetch("response_text").presence,
            correct:,
            points_earned: correct ? question.maximum_points : 0,
            submitted_at:
          )
          response.save!
        end

        attempt.recalculate_score!
        remove_stale_attempt_mastery(attempt)
        apply_attempt_mastery(attempt, summary)
      end

      summary
    end

    def apply_attempt_mastery(attempt, summary)
      return unless attempt.status == "submitted"

      responses_by_question_id = attempt.question_responses.index_by(&:assessment_question_id)
      questions = attempt.assessment.assessment_questions.includes(:learning_objective)
      questions.group_by(&:learning_objective).each do |objective, objective_questions|
        possible = objective_questions.sum(&:maximum_points)
        earned = objective_questions.sum do |question|
          responses_by_question_id[question.id]&.points_earned || 0
        end
        score = possible.positive? ? (earned / possible * 100).round(2) : 0
        snapshot = MasterySnapshot.find_or_initialize_by(
          organization: data_import.organization,
          section: data_import.section,
          student: attempt.student,
          learning_objective: objective,
          observed_on: attempt.submitted_at.to_date,
          source: "Assessment attempt #{attempt.external_ref}"
        )
        summary[snapshot.new_record? ? "snapshots_created" : "snapshots_updated"] += 1
        snapshot.score = score
        snapshot.save!
      end
    end

    def remove_stale_attempt_mastery(attempt)
      scope = MasterySnapshot.where(
        organization: data_import.organization,
        section: data_import.section,
        student: attempt.student,
        source: "Assessment attempt #{attempt.external_ref}"
      )
      return scope.delete_all unless attempt.status == "submitted"

      objective_ids = attempt.assessment.assessment_questions.distinct.pluck(:learning_objective_id)
      scope.where.not(observed_on: attempt.submitted_at.to_date).delete_all
      scope.where.not(learning_objective_id: objective_ids).delete_all
    end

    def normalized_answer(value)
      value.to_s.strip.downcase.gsub(/\s+/, " ")
    end

    def detect_new_signals
      previous_count = data_import.section.student_signals.count
      Signals::Detect.new(section: data_import.section).call
      data_import.section.student_signals.count - previous_count
    end

    def mark_invalid(result)
      data_import.update!(
        status: "invalid",
        total_rows: result.total_rows,
        valid_rows: result.rows.length,
        error_count: result.errors.length,
        preview_rows: result.rows.first(10),
        validation_errors: result.errors.first(100)
      )
      record_audit("student_data_import.invalidated", error_count: result.errors.length)
      data_import
    end

    def mark_failed(error)
      return unless data_import.persisted?

      data_import.update_columns(
        status: "failed",
        failure_message: "The import could not be applied. No partial student data was saved.",
        updated_at: Time.current
      )
      record_audit("student_data_import.failed", error_class: error.class.name)
    rescue StandardError
      nil
    end

    def record_audit(action, changes)
      Audit::Record.call(
        organization: data_import.organization,
        school: data_import.school,
        user: data_import.uploaded_by,
        auditable: data_import,
        action:,
        changes:,
        request_id:
      )
    end
  end
end
