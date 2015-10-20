# coding: us-ascii

module OptionalArgument

  class << self

    # @yieldreturn [Class] subclass of Store
    # @return [void] must block given
    def define(&block)
      raise ArgumentError, 'block was not given' unless block_given?

      Class.new(Store) {
        _init
        class_eval(&block)
        _fix
      }
    end
    
    # @see OptionalArgument::Store.parse
    def parse(opts, parsing_options={}, &block)
      raise ArgumentError, 'block was not given' unless block_given?
      
      define(&block).parse opts, parsing_options
    end

  end

end
