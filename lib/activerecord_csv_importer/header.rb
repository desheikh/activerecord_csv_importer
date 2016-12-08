module ActiveRecordCSVImporter
  # The CSV Header
  class Header
    include Virtus.model

    attribute :column_definitions, Array[ColumnDefinition]
    attribute :column_names, Array[String]

    def columns
      column_names.map do |column_name|
        Column.new(
          name: column_name,
          definition: find_column_definition(column_name)
        )
      end
    end

    # original csv column names
    def columns_with_definition_names
      columns.select(&:definition).map(&:name)
    end

    # mapped column names
    def column_definition_names
      column_definitions.map(&:name).map(&:to_s)
    end

    def column_name_for_model_attribute(attribute)
      column = columns.find { |c|
        c.definition.attribute == attribute if c.definition
      }
      column.name if column
    end

    def valid?
      missing_required_columns.empty?
    end

    # Returns Array[String]
    def required_columns
      column_definitions.select(&:required?).map(&:name)
    end

    # Returns Array[String]
    def missing_required_columns
      (column_definitions.select(&:required?) - columns.map(&:definition))
        .map(&:name).map(&:to_s)
    end

    # Returns Array[String]
    def missing_columns
      (column_definitions - columns.map(&:definition)).map(&:name).map(&:to_s)
    end

    private

    def find_column_definition(name)
      column_definitions.find { |column_definition|
        column_definition.match?(name)
      }
    end
  end
end
