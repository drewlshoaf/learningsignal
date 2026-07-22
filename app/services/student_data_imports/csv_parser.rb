require "csv"
require "set"

module StudentDataImports
  class CsvParser
    Result = Data.define(:rows, :errors, :total_rows)
    MAX_ROWS = 2_000

    def initialize(data_import:, path:)
      @data_import = data_import
      @path = path
    end

    def call
      table = CSV.read(path, headers: true, encoding: "bom|utf-8")
      header_errors = validate_headers(table.headers)
      return Result.new(rows: [], errors: header_errors, total_rows: 0) if header_errors.any?

      source_rows = table.each_with_index.filter_map do |row, index|
        values = row.to_h.transform_keys { |header| header.to_s.strip.downcase }
        next if values.values.all? { |value| value.to_s.strip.empty? }

        [ index + 2, values ]
      end

      if source_rows.length > MAX_ROWS
        return Result.new(
          rows: [],
          errors: [ error(1, "file", "contains more than #{MAX_ROWS} data rows") ],
          total_rows: source_rows.length
        )
      end

      rows = []
      errors = []
      seen_keys = {}
      source_rows.each do |line, values|
        row, row_errors = normalize(values, line)
        duplicate_key = row_errors.empty? ? identity_key(row) : nil
        if duplicate_key.present? && seen_keys.key?(duplicate_key)
          row_errors << error(line, identity_field, "duplicates row #{seen_keys.fetch(duplicate_key)}")
        elsif duplicate_key.present?
          seen_keys[duplicate_key] = line
        end

        errors.concat(row_errors)
        rows << row.merge("line" => line) if row_errors.empty?
      end

      context_errors = validate_context(rows)
      invalid_lines = context_errors.pluck("line").to_set
      errors.concat(context_errors)

      Result.new(
        rows: rows.reject { |row| invalid_lines.include?(row.fetch("line")) },
        errors: errors,
        total_rows: source_rows.length
      )
    rescue CSV::MalformedCSVError, Encoding::InvalidByteSequenceError, Encoding::UndefinedConversionError => error
      Result.new(rows: [], errors: [ self.error(1, "file", "is not valid UTF-8 CSV: #{error.message.truncate(180)}") ], total_rows: 0)
    end

    private

    attr_reader :data_import, :path

    def validate_headers(headers)
      normalized = Array(headers).map { |header| header.to_s.strip.downcase }
      return [] if normalized.sort == self.class::HEADERS.sort && normalized.uniq.length == normalized.length

      missing = self.class::HEADERS - normalized
      unexpected = normalized - self.class::HEADERS
      details = []
      details << "missing: #{missing.join(', ')}" if missing.any?
      details << "unexpected: #{unexpected.join(', ')}" if unexpected.any?
      details << "duplicate headers are not allowed" if normalized.uniq.length != normalized.length
      [ error(1, "headers", details.join("; ")) ]
    end

    def required_string(values, field, line, errors, maximum: 120)
      value = values.fetch(field, "").to_s.strip
      errors << error(line, field, "is required") if value.empty?
      errors << error(line, field, "must be #{maximum} characters or fewer") if value.length > maximum
      value
    end

    def error(line, field, message)
      { "line" => line, "field" => field, "message" => message }
    end
  end
end
