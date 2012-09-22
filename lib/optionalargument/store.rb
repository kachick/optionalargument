require_relative 'store/singleton_class'

module OptionalArgument

  # Not included Enumerable. Because main role is to hold arg-names.
  class Store

    # @param [Hash, #to_hash] pairs
    def initialize(pairs)
      @pairs = pairs
    end

    # @param [Symbol, String, #to_sym] name
    def [](name)
      __send__ :"fetch_by_#{self.class.autonym_for_name name}"
    end

    # @return [String]
    def inspect
      body = @pairs.each_pair.map{|k, v|"#{k}=#{v.inspect}"}.join(', ')
      "#<options #{self.class.name}: #{body}>"
    end

    alias_method :to_s, :inspect

    # @yield [autonym, value]
    # @yieldparam [Symbol] autonym
    # @yieldreturn [self]
    # @return [Enumerator]
    def each_pair(&block)
      return to_enum(__method__) unless block_given?
      
      @pairs.each_pair(&block)
      self
    end

    # @return [Hash]
    def to_h
      @pairs.to_hash.dup
    end

    # @return [Integer]
    def hash
      @pairs.hash
    end

    def eql?(other)
      other.instance_of?(self.class) && (other._pairs.eql? @pairs)
    end

    # @return [Boolean]
    def ==(other)
      other.instance_of?(self.class) && (other._pairs === @pairs)
    end

    alias_method :===, :==

    protected

    def _pairs
      @pairs
    end

  end

end
