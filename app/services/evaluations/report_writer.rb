require "fileutils"

module Evaluations
  class ReportWriter
    attr_reader :markdown_path, :json_path

    def initialize(run:, output_dir: Rails.root.join("tmp/evaluation-reports"))
      @run = run
      @output_dir = Pathname(output_dir)
      @markdown_path = @output_dir.join("evaluation-report.md")
      @json_path = @output_dir.join("evaluation-report.json")
    end

    def write
      FileUtils.mkdir_p(output_dir)
      markdown_path.write(markdown)
      json_path.write(JSON.pretty_generate(payload))
      self
    end

    private

    attr_reader :run, :output_dir

    def payload
      {
        run: run.attributes.except("created_at", "updated_at"),
        results: run.evaluation_results.order(:case_id).map do |result|
          result.attributes.except("created_at", "updated_at")
        end
      }
    end

    def markdown
      <<~MARKDOWN
        # LearningSignal evaluation regression report

        **Status:** #{run.status.upcase}<br>
        **Suite:** #{run.suite}<br>
        **Provider / model:** #{run.provider} / #{run.model}<br>
        **Prompt:** #{run.prompt_version} (`#{run.prompt_digest.first(12)}`)<br>
        **Cases:** `#{run.cases_digest.first(12)}`<br>
        **Git revision:** `#{run.git_sha}`

        ## Aggregate metrics

        | Metric | Value |
        | --- | ---: |
        #{metric_rows}

        Tokens: #{run.input_tokens} input / #{run.output_tokens} output<br>
        Estimated cost: $#{format('%.6f', run.estimated_cost_usd)}<br>
        Model and retrieval latency: #{run.latency_ms} ms

        ## Cases

        | Case | Type | Status | Latency | Cost |
        | --- | --- | --- | ---: | ---: |
        #{case_rows}

        ## Gate failures

        #{failure_lines}
      MARKDOWN
    end

    def metric_rows
      run.metrics.sort.map { |name, value| "| #{name} | #{format_metric(value)} |" }.join("\n")
    end

    def case_rows
      run.evaluation_results.order(:case_id).map do |result|
        "| #{result.case_id} | #{result.case_type} | #{result.status} | #{result.latency_ms} ms | $#{format('%.6f', result.estimated_cost_usd)} |"
      end.join("\n")
    end

    def failure_lines
      return "None." if run.gate_failures.empty?

      run.gate_failures.map do |failure|
        "- `#{failure.fetch('metric')}` must be #{failure.fetch('operator')} #{failure.fetch('threshold')}; actual #{failure.fetch('actual')}."
      end.join("\n")
    end

    def format_metric(value)
      value.is_a?(Numeric) ? format("%.4f", value) : value.to_s
    end
  end
end
