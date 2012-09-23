require_relative 'store/singleton_class'

module OptionalArgument

  # Not included Enumerable. Because main role is to hold arg-names.
  class Store

    alias_method :__class__, :class

    # @param [Hash, #to_hash] pairs
    def initialize(pairs)
      @pairs = pairs
    end

    # @param [Symbol, String, #to_sym] name
    # @return [Symbol] autonym
    def autonym_for_name(name)
      __class__.autonym_for_name name
    end

    # @param [Symbol, String, #to_sym] name
    def [](name)
      @pairs[autonym_for_name name]
    end

    # @param [Symbol, String, #to_sym] name
    def with?(name)
      @pairs.has_key? autonym_for_name(name)
    end

    alias_method :has_key?, :with?

    # @return [String]
    def inspect
      "#<optargs: #{@pairs.map{|k, v|"#{k}=#{v.inspect}"}.join(', ')}>"
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
