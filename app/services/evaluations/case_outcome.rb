module Evaluations
  CaseOutcome = Data.define(
    :status,
    :metrics,
    :details,
    :input_tokens,
    :output_tokens,
    :estimated_cost_usd,
    :latency_ms,
    :error_message
  )
end
