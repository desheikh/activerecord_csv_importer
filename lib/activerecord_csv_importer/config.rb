module ActiveRecordCSVImporter
  # The configuration of a ActiveRecordCSVImporter
  class Config
    include Virtus.model

    attribute :model
    attribute :column_definitions, Array[ColumnDefinition], default: proc { [] }
    attribute :on_duplicate_key, Hash, default: []
    attribute :batch_size, Integer, default: 500
    attribute :each_batch_blocks, Array[Proc], default: []

    def each_batch(block)
      each_batch_blocks << block
    end
  end
end
