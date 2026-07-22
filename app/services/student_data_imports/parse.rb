module StudentDataImports
  class Parse
    PARSERS = {
      "roster" => RosterParser,
      "mastery" => MasteryParser
    }.freeze

    def initialize(data_import:)
      @data_import = data_import
    end

    def call
      data_import.file.open do |file|
        PARSERS.fetch(data_import.import_type).new(data_import:, path: file.path).call
      end
    end

    private

    attr_reader :data_import
  end
end
