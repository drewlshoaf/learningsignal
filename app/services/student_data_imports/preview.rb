module StudentDataImports
  class Preview
    PREVIEW_LIMIT = 10
    class PreviewError < StandardError; end

    def initialize(data_import:, request_id: nil)
      @data_import = data_import
      @request_id = request_id
    end

    def call
      result = Parse.new(data_import:).call
      data_import.update!(
        status: result.errors.empty? ? "previewed" : "invalid",
        total_rows: result.total_rows,
        valid_rows: result.rows.length,
        error_count: result.errors.length,
        preview_rows: result.rows.first(PREVIEW_LIMIT),
        validation_errors: result.errors.first(100),
        failure_message: nil
      )
      record_audit
      data_import
    rescue StandardError => error
      data_import.update_columns(
        status: "failed",
        failure_message: "The CSV could not be previewed. No student data was changed.",
        updated_at: Time.current
      )
      Audit::Record.call(
        organization: data_import.organization,
        school: data_import.school,
        user: data_import.uploaded_by,
        auditable: data_import,
        action: "student_data_import.preview_failed",
        changes: { error_class: error.class.name },
        request_id:
      )
      raise PreviewError, "The CSV preview failed."
    end

    private

    attr_reader :data_import, :request_id

    def record_audit
      Audit::Record.call(
        organization: data_import.organization,
        school: data_import.school,
        user: data_import.uploaded_by,
        auditable: data_import,
        action: "student_data_import.previewed",
        changes: {
          import_type: data_import.import_type,
          total_rows: data_import.total_rows,
          valid_rows: data_import.valid_rows,
          error_count: data_import.error_count
        },
        request_id:
      )
    end
  end
end
