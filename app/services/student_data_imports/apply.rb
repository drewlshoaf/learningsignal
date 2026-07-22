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
        applied = data_import.import_type == "roster" ? apply_roster(result.rows) : apply_mastery(result.rows)
        generated_signals = data_import.import_type == "mastery" ? Signals::Detect.new(section: data_import.section).call.length : 0
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
