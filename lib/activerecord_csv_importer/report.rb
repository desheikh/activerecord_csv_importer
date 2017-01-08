module ActiveRecordCSVImporter
  # The Report you get back from an import.
  #
  # * It has a status (pending, invalid_csv_file, invalid_header, in_progress, done, aborted)
  # * It lists out missing columns
  # * It reports parser_error
  # * It lists out (created / updated) * (success / failed) records
  # * It provides a human readable message
  #
  class Report
    include Virtus.model

    attribute :status, Symbol, default: proc { :pending }

    attribute :missing_columns, Array[Symbol], default: proc { [] }

    attribute :parser_error, String

    attribute :ids, Array, default: []
    attribute :total_count, Integer, default: 0
    attribute :completed_count, Integer, default: 0
    attribute :invalid_rows, Array[Array], default: {}

    attribute :message_generator, Class, default: proc { ReportMessage }

    def progress_percentage
      return 0 if total_count.zero?
      (completed_count.to_f / total_count * 100).round
    end

    def success?
      done? && invalid_rows.empty?
    end

    def pending?
      status == :pending
    end

    def in_progress?
      status == :in_progress
    end

    def done?
      status == :done
    end

    def aborted?
      status == :aborted
    end

    def invalid_header?
      status == :invalid_header
    end

    def invalid_csv_file?
      status == :invalid_csv_file
    end

    def pending!
      self.status = :pending
      self
    end

    def in_progress!
      self.status = :in_progress
      self
    end

    def done!
      self.status = :done
      self
    end

    def aborted!
      self.status = :aborted
      self
    end

    def invalid_header!
      self.status = :invalid_header
      self
    end

    def invalid_csv_file!
      self.status = :invalid_csv_file
      self
    end

    def message
      message_generator.call(self)
    end
  end
end
