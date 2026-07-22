module Investigations
  class Orchestrator
    PROMPT_VERSION = "investigation-v1"

    def initialize(investigation:, provider: Ai::ProviderRegistry.fetch)
      @investigation = investigation
      @provider = provider
    end

    def call
      investigation.update!(status: "running", current_step: "collecting_evidence", started_at: Time.current)
      collect_performance_evidence
      retrieve_curriculum_evidence
      investigation.update!(current_step: "analyzing_evidence")
      result = generate_result
      GroundingValidator.new(result: result.fetch(:data), evidence: investigation.retrieved_evidences).validate!
      persist_result(result.fetch(:data))
      investigation.update!(status: "completed", current_step: "ready_for_review", completed_at: Time.current)
      investigation.student_signal.update!(status: "open")
      Audit::Record.call(
        organization: investigation.organization,
        school: investigation.school,
        user: investigation.teacher,
        auditable: investigation,
        action: "investigation.completed",
        changes: { citations: investigation.retrieved_evidences.count }
      )
    rescue StandardError => error
      investigation.update_columns(status: "failed", current_step: "failed", failure_message: error.message, completed_at: Time.current, updated_at: Time.current)
      Audit::Record.call(
        organization: investigation.organization,
        school: investigation.school,
        user: investigation.teacher,
        auditable: investigation,
        action: "investigation.failed",
        changes: { error_class: error.class.name, message: error.message }
      )
      raise
    end

    private

    attr_reader :investigation, :provider

    def collect_performance_evidence
      snapshots = investigation.student.mastery_snapshots
        .where(learning_objective: investigation.learning_objective)
        .order(observed_on: :desc)
        .limit(2)
        .reverse

      snapshots.each_with_index do |snapshot, index|
        investigation.retrieved_evidences.create!(
          organization: investigation.organization,
          citation_id: "P#{index + 1}",
          evidence_type: "performance",
          source_type: "MasterySnapshot",
          source_id: snapshot.id,
          excerpt: "#{investigation.learning_objective.title} mastery was #{snapshot.score.to_i}% on #{snapshot.observed_on.to_fs(:long)}.",
          locator: "Mastery timeline · #{snapshot.observed_on.to_fs(:long)}",
          relevance_score: 1.0,
          metadata: { source: snapshot.source }
        )
      end
    end

    def retrieve_curriculum_evidence
      investigation.update!(current_step: "retrieving_curriculum")
      query = "#{investigation.learning_objective.title} #{investigation.student_signal.explanation}"
      results = Retrieval::HybridSearch.new(
        organization: investigation.organization,
        objective: investigation.learning_objective,
        provider: provider
      ).search(query: query, limit: 3)

      results.each_with_index do |result, index|
        chunk = result.chunk
        investigation.retrieved_evidences.create!(
          organization: investigation.organization,
          citation_id: "C#{index + 1}",
          evidence_type: "curriculum",
          source_type: "DocumentChunk",
          source_id: chunk.id,
          excerpt: chunk.content,
          locator: "#{chunk.curriculum_document.title} · #{chunk.locator}",
          relevance_score: result.score,
          metadata: { document_id: chunk.curriculum_document_id }
        )
      end
    end

    def generate_result
      evidence_payload = investigation.retrieved_evidences.order(:citation_id).map do |item|
        "[#{item.citation_id}] #{item.locator}: #{item.excerpt}"
      end.join("\n\n")

      input = <<~INPUT
        Student: #{investigation.student.display_name} (synthetic record)
        Course: #{investigation.section.course.name}
        Signal: #{investigation.student_signal.explanation}
        Objective: #{investigation.learning_objective.code} — #{investigation.learning_objective.title}

        Evidence:
        #{evidence_payload}
      INPUT

      run = investigation.agent_runs.create!(
        organization: investigation.organization,
        agent_name: "evidence_analyst",
        provider: provider.name,
        model: Ai::Configuration.model,
        prompt_version: PROMPT_VERSION,
        status: "running",
        input_data: { evidence_ids: investigation.retrieved_evidences.pluck(:citation_id) },
        started_at: Time.current
      )

      result = provider.generate(
        model: Ai::Configuration.model,
        input: input,
        instructions: Rails.root.join("config/prompts/investigation/v1.txt").read,
        schema: Ai::Schemas::InvestigationResult.definition,
        metadata: { investigation_id: investigation.id, organization_id: investigation.organization_id }
      )

      run.update!(
        status: "completed",
        output_data: result.fetch(:data),
        input_tokens: result.fetch(:input_tokens),
        output_tokens: result.fetch(:output_tokens),
        latency_ms: result.fetch(:latency_ms),
        provider_request_id: result.fetch(:request_id),
        model: result.fetch(:model),
        finished_at: Time.current
      )
      result
    rescue StandardError => error
      run&.update!(status: "failed", error_message: error.message, finished_at: Time.current)
      raise
    end

    def persist_result(data)
      Investigation.transaction do
        observation_data = data.fetch("observation")
        observation = investigation.investigation_observations.create!(
          organization: investigation.organization,
          statement: observation_data.fetch("statement"),
          confidence: observation_data.fetch("confidence"),
          limitations: observation_data.fetch("limitations")
        )
        evidence_by_id = investigation.retrieved_evidences.index_by(&:citation_id)
        observation_data.fetch("citation_ids").each do |citation_id|
          observation.observation_evidences.create!(retrieved_evidence: evidence_by_id.fetch(citation_id))
        end

        plan_data = data.fetch("plan")
        plan = investigation.create_intervention_plan!(
          organization: investigation.organization,
          summary: plan_data.fetch("summary"),
          status: "draft"
        )
        plan_data.fetch("actions").each_with_index do |action, index|
          plan.intervention_actions.create!(
            learning_objective: investigation.learning_objective,
            position: index + 1,
            title: action.fetch("title"),
            instructions: action.fetch("instructions"),
            duration: action.fetch("duration"),
            success_criteria: action.fetch("success_criteria")
          )
        end
        plan.update!(original_snapshot: plan.snapshot)
      end
    end
  end
end
