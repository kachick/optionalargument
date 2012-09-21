require_relative 'store/singleton_class'

module OptionalArgument

  class Store

    #def_delegators :self.class, :autonyms

    # @param [Hash] hash
    def initialize(hash)
      @hash = hash
    end

    # @param [Symbol, String, #to_sym] name
    def [](name)
      __send__ :"fetch_by_#{self.class.autonym_for_name name}"
    end

    # @return [String]
    def inspect
      body = @hash.each_pair.map{|k, v|"#{k}=#{v.inspect}"}.join(', ')
      "#<#{self.class.name}: #{body}>"
    end

    alias_method :to_s, :inspect

  end

end
