require 'csv'
require 'virtus'

require 'activerecord_csv_importer/version'
require 'activerecord_csv_importer/csv_reader'
require 'activerecord_csv_importer/column_definition'
require 'activerecord_csv_importer/column'
require 'activerecord_csv_importer/header'
require 'activerecord_csv_importer/row'
require 'activerecord_csv_importer/report'
require 'activerecord_csv_importer/report_message'
require 'activerecord_csv_importer/runner'
require 'activerecord_csv_importer/config'
require 'activerecord_csv_importer/dsl'

module ActiveRecordCSVImporter
  class Error < StandardError; end

  # Setup DSL and config object
  def self.included(klass)
    klass.extend(Dsl)
    klass.define_singleton_method(:config) do
      @config ||= Config.new
    end
  end

  # Instance level config will run against this configurator
  class Configurator < Struct.new(:config)
    include Dsl
  end

  # Defines the path, file or content of the csv file.
  # Also allows you to overwrite the configuration at runtime.
  #
  # Example:
  #
  #   .new(file: my_csv_file)
  #   .new(path: "subscribers.csv", model: newsletter.subscribers)
  #
  def initialize(*args, &block)
    @csv = CSVReader.new(*args)
    @config = self.class.config.dup
    @config.attributes = args.last
    @report = Report.new
    Configurator.new(@config).instance_exec(&block) if block
  end

  attr_reader :csv, :report, :config

  # Initialize and return the `Header` for the current CSV file
  def header
    @header ||= Header.new(
      column_definitions: config.column_definitions,
      column_names: csv.header
    )
  end

  # Initialize and return the `Row`s for the current CSV file
  def rows
    csv.rows.map { |row_array|
      Row.new(header: header, row_array: row_array).to_a
    }
  end

  def valid_header?
    if @report.pending?
      if header.valid?
        @report = Report.new(status: :pending)
      else
        @report = Report.new(
          status: :invalid_header,
          missing_columns: header.missing_required_columns
        )
      end
    end

    header.valid?
  end

  # Run the import. Return a Report.
  def run!
    if valid_header?
      @report = Runner.call(header: header, rows: rows, config: config)
    else
      @report
    end
  rescue CSV::MalformedCSVError => e
    @report = Report.new(status: :invalid_csv_file, parser_error: e.message)
  end
end
