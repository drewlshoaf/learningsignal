module StudentDataImports
  class Templates
    CONTENT = {
      "roster" => <<~CSV,
        student_external_ref,first_name,last_initial
        SYN-1001,Avery,K
        SYN-1002,Jordan,M
      CSV
      "mastery" => <<~CSV
        student_external_ref,objective_code,score,observed_on,source
        SYN-1001,ALG1.LIN.3,78,2026-07-01,Unit 2 checkpoint
        SYN-1001,ALG1.LIN.3,62,2026-07-18,Linear relationships quiz
      CSV
    }.freeze

    def self.fetch(import_type)
      CONTENT.fetch(import_type)
    end
  end
end
