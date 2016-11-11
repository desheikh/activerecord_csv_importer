module ActiveRecordCSVImporter
  # Generate a human readable message for the given report.
  class ReportMessage
    def self.call(report)
      new(report).to_s
    end

    def initialize(report)
      @report = report
    end

    attr_accessor :report

    def to_s
      send("report_#{report.status}")
    end

    private

    def report_pending
      "Import hasn't started yet"
    end

    def report_in_progress
      'Import in progress'
    end

    def report_done
      'Import completed'
    end

    def report_invalid_header
      "The following columns are required: #{report.missing_columns.join(', ')}"
    end

    def report_invalid_csv_file
      report.parser_error
    end

    def report_aborted
      'Import aborted'
    end
  end
end
