module Investigations
  class Create
    def self.call(...) = new(...).call

    def initialize(signal:, teacher:, request_id: nil)
      @signal = signal
      @teacher = teacher
      @request_id = request_id
    end

    def call
      investigation = nil
      StudentSignal.transaction do
        signal.lock!
        investigation = signal.investigations.create!(
          organization: signal.organization,
          school: signal.school,
          teacher: teacher,
          status: "queued",
          current_step: "queued"
        )
        signal.update!(status: "investigating")
        Audit::Record.call(
          organization: signal.organization,
          school: signal.school,
          user: teacher,
          auditable: investigation,
          action: "investigation.created",
          request_id: request_id
        )
      end

      InvestigationJob.perform_later(investigation.id)
      investigation
    end

    private

    attr_reader :signal, :teacher, :request_id
  end
end
