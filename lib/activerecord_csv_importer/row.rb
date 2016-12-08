module ActiveRecordCSVImporter
  # A Row from the CSV file.
  #
  # returns a formatted version of the row based of the to proc
  class Row
    include Virtus.model

    attribute :header, Header
    attribute :row_array, Array[String]

    # A hash with this row's attributes
    def csv_attributes
      @csv_attributes ||= Hash[header.column_names.zip(row_array)]
    end

    def to_a
      header.columns.each_with_object([]) do |column, memo|
        value = csv_attributes[column.name]
        begin
          value = value.dup if value
        rescue TypeError
          # can't dup Symbols, Integer etc...
        end

        next if column.definition.nil?

        memo << get_attribute(column.definition, value)
      end
    end

    # Set the attribute using the column_definition and the csv_value
    def get_attribute(column_definition, csv_value)
      if column_definition.to && column_definition.to.is_a?(Proc)
        column_definition.to.call(csv_value)
      else
        csv_value
      end
    end
  end
end
