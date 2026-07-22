module AssessmentHelper
  def build_assessment_for(scenario, external_ref: "ASSESSMENT-1")
    assessment = Assessment.create!(
      organization: scenario.fetch(:organization),
      course: scenario.fetch(:course),
      external_ref:,
      title: "Linear Relationships Check",
      assessment_type: "quiz",
      status: "published",
      synthetic: true
    )
    questions = [
      [ "Q1", "Find slope from two points", "B", 2 ],
      [ "Q2", "Distinguish slope from y-intercept", "C", 2 ]
    ].map do |question_ref, prompt_reference, answer_key, maximum_points|
      assessment.assessment_questions.create!(
        organization: scenario.fetch(:organization),
        learning_objective: scenario.fetch(:objective),
        external_ref: question_ref,
        prompt_reference:,
        question_type: "multiple_choice",
        maximum_points:,
        metadata: { "answer_key" => answer_key }
      )
    end
    assessment.recalculate_maximum_score!
    { assessment:, questions: }
  end
end
