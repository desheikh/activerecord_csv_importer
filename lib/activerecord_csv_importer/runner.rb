module ActiveRecordCSVImporter
  # Do the actual import.
  #
  # It iterates over the rows' models and persist them. It returns a `Report`.
  class Runner
    def self.call(*args)
      new(*args).call
    end

    include Virtus.model

    attribute :model
    attribute :header
    attribute :rows, Array[CSV::Row]
    attribute :config, Object

    attribute :report, Report, default: proc { Report.new }

    # Persist the csv rows and return a Report
    def call
      report.total_count = rows.count
      report.in_progress!
      persist_rows!
      report.done!

      report
    end

    private

    def persist_rows!
      rows.in_groups_of(config.batch_size, false) do |set|
        response = import_rows(set)

        add_to_report(response, set)
        config.each_batch_blocks.each { |block| block.call(report) }
      end
    end

    def import_rows(set)
      config.model.import(header.columns_with_definition_names.dup, set, config.on_duplicate_key)
    end

    def add_to_report(response, set)
      report.completed_count += set.length

      response.failed_instances.each do |model|
        report.invalid_rows << (columns_for(model) << build_error(model))
      end
    end

    def columns_for(model)
      model.attributes.values_at(*header.columns_with_definition_names)
    end

    # Error from the model mapped back to the CSV header if we can
    def build_error(model)
      Hash[
        model.errors.map do |attribute, errors|
          column_name = header.column_name_for_model_attribute(attribute)
          column_name ? [column_name, errors] : [attribute, errors]
        end
      ]
    end
  end
end
