module ActiveRecordCSVImporter
  # This Dsl extends a class that includes ActiveRecordCSVImporter
  # It is a thin proxy to the Config object
  module Dsl
    def model(model_klass)
      config.model = model_klass
    end

    def column(name, options = {})
      config.column_definitions << options.merge(name: name)
    end

    def on_duplicate_key(options)
      config.on_duplicate_key = options
    end

    def batch_size(size)
      config.batch_size = size
    end

    def each_batch(&block)
      config.each_batch(block)
    end
  end
end
