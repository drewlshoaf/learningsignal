module InterventionHelper
  def build_approved_plan(scenario, suffix: SecureRandom.hex(4))
    investigation = Investigation.create!(
      organization: scenario.fetch(:organization),
      school: scenario.fetch(:school),
      student_signal: scenario.fetch(:signal),
      teacher: scenario.fetch(:teacher),
      status: "completed",
      current_step: "ready_for_review",
      started_at: 1.day.ago,
      completed_at: Time.current
    )
    investigation.investigation_observations.create!(
      organization: scenario.fetch(:organization),
      statement: "The student needs targeted slope practice.",
      confidence: "high",
      limitations: "Based on the available mastery evidence."
    )
    investigation.agent_runs.create!(
      organization: scenario.fetch(:organization),
      agent_name: "evidence_analyst",
      provider: "deterministic",
      model: "test-model",
      prompt_version: "investigation-v1",
      status: "completed",
      started_at: 1.day.ago,
      finished_at: Time.current
    )
    plan = investigation.create_intervention_plan!(
      organization: scenario.fetch(:organization),
      summary: "Targeted slope intervention #{suffix}",
      status: "approved",
      approved_at: Time.current
    )
    [
      [ "Review slope", "Review rise and run with a worked example." ],
      [ "Reassess", "Complete a three-question exit ticket." ]
    ].each_with_index do |(title, instructions), index|
      plan.intervention_actions.create!(
        learning_objective: scenario.fetch(:objective),
        position: index + 1,
        title: title,
        instructions: instructions,
        duration: "15 minutes",
        success_criteria: "Complete at least two of three examples correctly."
      )
    end
    plan.update!(original_snapshot: plan.snapshot)
    plan
  end
end
