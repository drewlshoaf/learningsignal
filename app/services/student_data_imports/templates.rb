module StudentDataImports
  class Templates
    CONTENT = {
      "roster" => <<~CSV,
        student_external_ref,first_name,last_initial
        SYN-1001,Avery,K
        SYN-1002,Jordan,M
      CSV
      "mastery" => <<~CSV,
        student_external_ref,objective_code,score,observed_on,source
        SYN-1001,ALG1.LIN.3,78,2026-07-01,Unit 2 checkpoint
        SYN-1001,ALG1.LIN.3,62,2026-07-18,Linear relationships quiz
      CSV
      "assessment_catalog" => <<~CSV,
        assessment_external_ref,assessment_title,assessment_type,assessment_status,question_external_ref,objective_code,prompt_reference,question_type,maximum_points,answer_key
        ALG1-LIN-Q1,Linear Relationships Check,quiz,published,Q1,ALG1.LIN.3,Slope from points,multiple_choice,1,B
        ALG1-LIN-Q1,Linear Relationships Check,quiz,published,Q2,ALG1.LIN.3,Slope vs intercept,multiple_choice,1,C
      CSV
      "assessment_responses" => <<~CSV
        attempt_external_ref,assessment_external_ref,student_external_ref,attempt_number,question_external_ref,selected_answer,response_text,submitted_at,status
        SYN-1001-LIN-1,ALG1-LIN-Q1,SYN-1001,1,Q1,B,,2026-07-20T15:30:00Z,submitted
        SYN-1001-LIN-1,ALG1-LIN-Q1,SYN-1001,1,Q2,A,,2026-07-20T15:30:00Z,submitted
      CSV
    }.freeze

    def self.fetch(import_type)
      CONTENT.fetch(import_type)
    end
  end
end
