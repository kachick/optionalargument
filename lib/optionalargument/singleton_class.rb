module OptionalArgument

  class << self

    # @yieldreturn [Class] subclass of Store
    # @return [void] must block given
    def define(&block)
      raise ArgumentError, 'block was not given' unless block_given?

      Class.new Store do
        @names = {}          # autonym/alias => autonym
        @must_autonyms = []
        @conflict_autonyms = []
        class_eval(&block)
      end   
    end

  end

end
