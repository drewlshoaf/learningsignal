module StudentDataImports
  class RosterParser < CsvParser
    HEADERS = %w[student_external_ref first_name last_initial].freeze

    private

    def normalize(values, line)
      errors = []
      external_ref = required_string(values, "student_external_ref", line, errors, maximum: 100)
      first_name = required_string(values, "first_name", line, errors, maximum: 100)
      last_initial = required_string(values, "last_initial", line, errors, maximum: 1).upcase

      errors << error(line, "student_external_ref", "may contain only letters, numbers, dots, underscores, and hyphens") unless external_ref.match?(/\A[A-Za-z0-9._-]+\z/)
      errors << error(line, "last_initial", "must be one letter") unless last_initial.match?(/\A[A-Z]\z/)

      [
        {
          "student_external_ref" => external_ref,
          "first_name" => first_name,
          "last_initial" => last_initial
        },
        errors
      ]
    end

    def identity_key(row) = row.fetch("student_external_ref")
    def identity_field = "student_external_ref"

    def validate_context(rows)
      references = rows.pluck("student_external_ref")
      existing = Student.where(organization: data_import.organization, external_ref: references).index_by(&:external_ref)

      rows.filter_map do |row|
        student = existing[row.fetch("student_external_ref")]
        next if student.blank?

        if !student.synthetic?
          error(row.fetch("line"), "student_external_ref", "belongs to a non-synthetic record and cannot be imported here")
        elsif student.school_id != data_import.school_id
          error(row.fetch("line"), "student_external_ref", "already belongs to another school in this organization")
        end
      end
    end
  end
end
