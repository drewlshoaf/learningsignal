require "time"

module StudentDataImports
  class AssessmentResponsesParser < CsvParser
    HEADERS = %w[
      attempt_external_ref assessment_external_ref student_external_ref attempt_number
      question_external_ref selected_answer response_text submitted_at status
    ].freeze

    private

    def normalize(values, line)
      errors = []
      attempt_external_ref = required_string(values, "attempt_external_ref", line, errors, maximum: 100)
      assessment_external_ref = required_string(values, "assessment_external_ref", line, errors, maximum: 100)
      student_external_ref = required_string(values, "student_external_ref", line, errors, maximum: 100)
      question_external_ref = required_string(values, "question_external_ref", line, errors, maximum: 100)
      selected_answer = values.fetch("selected_answer", "").to_s.strip
      response_text = values.fetch("response_text", "").to_s.strip
      status = required_string(values, "status", line, errors, maximum: 40)
      attempt_number = parse_attempt_number(values.fetch("attempt_number", ""), line, errors)
      submitted_at = parse_timestamp(values.fetch("submitted_at", ""), line, errors)

      errors << error(line, "response", "requires selected_answer or response_text") if selected_answer.blank? && response_text.blank?
      errors << error(line, "selected_answer", "must be 500 characters or fewer") if selected_answer.length > 500
      errors << error(line, "response_text", "must be 2,000 characters or fewer") if response_text.length > 2_000
      errors << error(line, "status", "must be one of: #{AssessmentAttempt::STATUSES.join(', ')}") unless status.in?(AssessmentAttempt::STATUSES)
      validate_reference(attempt_external_ref, "attempt_external_ref", line, errors)
      validate_reference(assessment_external_ref, "assessment_external_ref", line, errors)
      validate_reference(question_external_ref, "question_external_ref", line, errors)

      [
        {
          "attempt_external_ref" => attempt_external_ref,
          "assessment_external_ref" => assessment_external_ref,
          "student_external_ref" => student_external_ref,
          "attempt_number" => attempt_number,
          "question_external_ref" => question_external_ref,
          "selected_answer" => selected_answer,
          "response_text" => response_text,
          "submitted_at" => submitted_at&.iso8601,
          "status" => status
        },
        errors
      ]
    end

    def parse_attempt_number(value, line, errors)
      number = Integer(value.to_s.strip, 10)
      errors << error(line, "attempt_number", "must be a positive whole number") unless number.positive?
      number
    rescue ArgumentError
      errors << error(line, "attempt_number", "must be a positive whole number")
      nil
    end

    def parse_timestamp(value, line, errors)
      Time.iso8601(value.to_s.strip)
    rescue ArgumentError
      errors << error(line, "submitted_at", "must use ISO 8601, for example 2026-07-20T15:30:00Z")
      nil
    end

    def validate_reference(value, field, line, errors)
      return if value.match?(/\A[A-Za-z0-9._-]+\z/)

      errors << error(line, field, "may contain only letters, numbers, dots, underscores, and hyphens")
    end

    def identity_key(row)
      row.values_at("attempt_external_ref", "question_external_ref").join("|")
    end

    def identity_field = "question_external_ref"

    def validate_context(rows)
      students = data_import.section.students
        .where(external_ref: rows.pluck("student_external_ref").uniq)
        .index_by(&:external_ref)
      assessments = data_import.section.course.assessments
        .where(external_ref: rows.pluck("assessment_external_ref").uniq)
        .includes(:assessment_questions)
        .index_by(&:external_ref)
      attempts = AssessmentAttempt.where(
        organization: data_import.organization,
        section: data_import.section,
        external_ref: rows.pluck("attempt_external_ref").uniq
      ).index_by(&:external_ref)

      row_errors = rows.flat_map do |row|
        errors = []
        student = students[row.fetch("student_external_ref")]
        assessment = assessments[row.fetch("assessment_external_ref")]
        attempt = attempts[row.fetch("attempt_external_ref")]
        errors << error(row.fetch("line"), "student_external_ref", "is not enrolled in this section") if student.blank?
        errors << error(row.fetch("line"), "assessment_external_ref", "does not belong to this section's course") if assessment.blank?
        if assessment.present? && assessment.assessment_questions.none? { |question| question.external_ref == row.fetch("question_external_ref") }
          errors << error(row.fetch("line"), "question_external_ref", "does not belong to the referenced assessment")
        end
        if attempt.present? && !attempt.synthetic?
          errors << error(row.fetch("line"), "attempt_external_ref", "belongs to a non-synthetic attempt and cannot be imported here")
        elsif attempt.present? && (attempt.student_id != student&.id || attempt.assessment_id != assessment&.id)
          errors << error(row.fetch("line"), "attempt_external_ref", "already belongs to another student or assessment")
        end
        errors
      end

      row_errors + inconsistent_attempt_errors(rows)
    end

    def inconsistent_attempt_errors(rows)
      rows.group_by { |row| row.fetch("attempt_external_ref") }.flat_map do |_reference, attempt_rows|
        expected = attempt_rows.first.values_at(
          "assessment_external_ref", "student_external_ref", "attempt_number", "submitted_at", "status"
        )
        attempt_rows.drop(1).filter_map do |row|
          next if row.values_at("assessment_external_ref", "student_external_ref", "attempt_number", "submitted_at", "status") == expected

          error(row.fetch("line"), "attempt_external_ref", "uses conflicting student, assessment, attempt, timestamp, or status values")
        end
      end
    end
  end
end
