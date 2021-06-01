# coding: us-ascii
# frozen_string_literal: true

module OptionalArgument
  class << self
    # @yieldreturn [Class] subclass of Store
    # @return [void] must block given
    def define(&block)
      raise ArgumentError, 'block was not given' unless block

      Class.new(Store) {
        _init
        class_eval(&block)
        _fix
      }
    end

    # @see OptionalArgument::Store.parse
    def parse(opts, **kwargs, &block)
      raise ArgumentError, 'block was not given' unless block

      define(&block).parse(opts, **kwargs)
    end
  end
end
