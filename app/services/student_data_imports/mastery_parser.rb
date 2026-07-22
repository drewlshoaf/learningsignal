require "bigdecimal"

module StudentDataImports
  class MasteryParser < CsvParser
    HEADERS = %w[student_external_ref objective_code score observed_on source].freeze

    private

    def normalize(values, line)
      errors = []
      external_ref = required_string(values, "student_external_ref", line, errors, maximum: 100)
      objective_code = required_string(values, "objective_code", line, errors, maximum: 100)
      source = required_string(values, "source", line, errors, maximum: 120)
      score = parse_score(values.fetch("score", ""), line, errors)
      observed_on = parse_date(values.fetch("observed_on", ""), line, errors)

      [
        {
          "student_external_ref" => external_ref,
          "objective_code" => objective_code,
          "score" => score&.to_s("F"),
          "observed_on" => observed_on&.iso8601,
          "source" => source
        },
        errors
      ]
    end

    def parse_score(value, line, errors)
      score = BigDecimal(value.to_s.strip)
      errors << error(line, "score", "must be between 0 and 100") unless score.between?(0, 100)
      score
    rescue ArgumentError
      errors << error(line, "score", "must be a number between 0 and 100")
      nil
    end

    def parse_date(value, line, errors)
      Date.iso8601(value.to_s.strip)
    rescue Date::Error
      errors << error(line, "observed_on", "must use YYYY-MM-DD")
      nil
    end

    def identity_key(row)
      row.values_at("student_external_ref", "objective_code", "observed_on", "source").join("|")
    end

    def identity_field = "row"

    def validate_context(rows)
      references = rows.pluck("student_external_ref").uniq
      objective_codes = rows.pluck("objective_code").uniq
      enrolled_students = data_import.section.students.where(external_ref: references).index_by(&:external_ref)
      objectives = data_import.section.course.learning_objectives.where(code: objective_codes).index_by(&:code)

      rows.flat_map do |row|
        line_errors = []
        unless enrolled_students.key?(row.fetch("student_external_ref"))
          line_errors << error(row.fetch("line"), "student_external_ref", "is not enrolled in this section")
        end
        unless objectives.key?(row.fetch("objective_code"))
          line_errors << error(row.fetch("line"), "objective_code", "does not belong to this section's course")
        end
        line_errors
      end
    end
  end
end
