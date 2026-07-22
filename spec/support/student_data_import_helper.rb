module StudentDataImportHelper
  def build_student_data_import(scenario, import_type:, csv:, filename: nil)
    StudentDataImport.new(
      organization: scenario.fetch(:organization),
      school: scenario.fetch(:school),
      section: scenario.fetch(:section),
      uploaded_by: scenario.fetch(:teacher),
      import_type:,
      status: "pending"
    ).tap do |data_import|
      data_import.file.attach(
        io: StringIO.new(csv),
        filename: filename || "#{import_type}.csv",
        content_type: "text/csv"
      )
      data_import.save!
    end
  end
end
