require "bigdecimal"

module StudentDataImports
  class AssessmentCatalogParser < CsvParser
    HEADERS = %w[
      assessment_external_ref assessment_title assessment_type assessment_status
      question_external_ref objective_code prompt_reference question_type maximum_points answer_key
    ].freeze

    private

    def normalize(values, line)
      errors = []
      assessment_external_ref = required_string(values, "assessment_external_ref", line, errors, maximum: 100)
      assessment_title = required_string(values, "assessment_title", line, errors, maximum: 200)
      assessment_type = required_string(values, "assessment_type", line, errors, maximum: 40)
      assessment_status = required_string(values, "assessment_status", line, errors, maximum: 40)
      question_external_ref = required_string(values, "question_external_ref", line, errors, maximum: 100)
      objective_code = required_string(values, "objective_code", line, errors, maximum: 100)
      prompt_reference = required_string(values, "prompt_reference", line, errors, maximum: 300)
      question_type = required_string(values, "question_type", line, errors, maximum: 40)
      answer_key = required_string(values, "answer_key", line, errors, maximum: 500)
      maximum_points = parse_points(values.fetch("maximum_points", ""), line, errors)

      validate_reference(assessment_external_ref, "assessment_external_ref", line, errors)
      validate_reference(question_external_ref, "question_external_ref", line, errors)
      errors << error(line, "assessment_type", "must be one of: #{Assessment::TYPES.join(', ')}") unless assessment_type.in?(Assessment::TYPES)
      errors << error(line, "assessment_status", "must be one of: #{Assessment::STATUSES.join(', ')}") unless assessment_status.in?(Assessment::STATUSES)
      errors << error(line, "question_type", "must be one of: #{AssessmentQuestion::TYPES.join(', ')}") unless question_type.in?(AssessmentQuestion::TYPES)

      [
        {
          "assessment_external_ref" => assessment_external_ref,
          "assessment_title" => assessment_title,
          "assessment_type" => assessment_type,
          "assessment_status" => assessment_status,
          "question_external_ref" => question_external_ref,
          "objective_code" => objective_code,
          "prompt_reference" => prompt_reference,
          "question_type" => question_type,
          "maximum_points" => maximum_points&.to_s("F"),
          "answer_key" => answer_key
        },
        errors
      ]
    end

    def parse_points(value, line, errors)
      points = BigDecimal(value.to_s.strip)
      errors << error(line, "maximum_points", "must be greater than 0 and no more than 100") unless points.positive? && points <= 100
      points
    rescue ArgumentError
      errors << error(line, "maximum_points", "must be a number greater than 0 and no more than 100")
      nil
    end

    def validate_reference(value, field, line, errors)
      return if value.match?(/\A[A-Za-z0-9._-]+\z/)

      errors << error(line, field, "may contain only letters, numbers, dots, underscores, and hyphens")
    end

    def identity_key(row)
      row.values_at("assessment_external_ref", "question_external_ref").join("|")
    end

    def identity_field = "question_external_ref"

    def validate_context(rows)
      objectives = data_import.section.course.learning_objectives
        .where(code: rows.pluck("objective_code").uniq)
        .index_by(&:code)
      assessments = Assessment.where(
        organization: data_import.organization,
        external_ref: rows.pluck("assessment_external_ref").uniq
      ).includes(assessment_questions: :question_responses).index_by(&:external_ref)

      row_errors = rows.flat_map do |row|
        errors = []
        assessment = assessments[row.fetch("assessment_external_ref")]
        errors << error(row.fetch("line"), "objective_code", "does not belong to this section's course") unless objectives.key?(row.fetch("objective_code"))
        if assessment.present? && assessment.course_id != data_import.section.course_id
          errors << error(row.fetch("line"), "assessment_external_ref", "already belongs to another course")
        elsif assessment.present? && !assessment.synthetic?
          errors << error(row.fetch("line"), "assessment_external_ref", "belongs to a non-synthetic assessment and cannot be imported here")
        end
        question = assessment&.assessment_questions&.find { |candidate| candidate.external_ref == row.fetch("question_external_ref") }
        if question.present? && question.question_responses.any? && protected_question_change?(question, row, objectives)
          errors << error(row.fetch("line"), "question_external_ref", "has recorded responses, so its answer key, points, type, and objective are locked")
        end
        errors
      end

      row_errors + inconsistent_assessment_errors(rows)
    end

    def inconsistent_assessment_errors(rows)
      rows.group_by { |row| row.fetch("assessment_external_ref") }.flat_map do |_reference, assessment_rows|
        expected = assessment_rows.first.values_at("assessment_title", "assessment_type", "assessment_status")
        assessment_rows.drop(1).filter_map do |row|
          next if row.values_at("assessment_title", "assessment_type", "assessment_status") == expected

          error(row.fetch("line"), "assessment_external_ref", "uses conflicting assessment title, type, or status values")
        end
      end
    end

    def protected_question_change?(question, row, objectives)
      question.answer_key != row.fetch("answer_key") ||
        question.maximum_points != BigDecimal(row.fetch("maximum_points")) ||
        question.question_type != row.fetch("question_type") ||
        question.learning_objective_id != objectives[row.fetch("objective_code")]&.id
    end
  end
end
