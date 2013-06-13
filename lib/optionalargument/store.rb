# coding: us-ascii

require_relative 'store/singleton_class'

module OptionalArgument

  # @note
  # *  Don't include Enumerable
  #   "To be Enumerable" is not necessary for this class.
  #   Because main role is just to hold options.
  #
  # * Depends only `/\A_+func_*\z/` on implementing for this class.
  #   Because `func` is keeped for public API of options.
  class Store

    alias_method :__class__, :class

    alias_method :_to_enum, :to_enum
    private :_to_enum

    # @param pairs [Hash, #to_hash]
    def initialize(pairs)
      @pairs = pairs
    end

    # @param name [Symbol, String, #to_sym]
    # @return [Symbol]
    def autonym_for_name(name)
      __class__.autonym_for_name name
    end

    alias_method :_autonym_for_name, :autonym_for_name
    private :_autonym_for_name

    # @param name [Symbol, String, #to_sym]
    def [](name)
      @pairs[_autonym_for_name name]
    end

    # @param name [Symbol, String, #to_sym]
    def with?(name)
      @pairs.has_key? _autonym_for_name(name)
    end

    alias_method :has_key?, :with?

    # @return [String]
    def inspect
      "#<optargs: #{@pairs.map{|k, v|"#{k}=#{v.inspect}"}.join(', ')}>"
    end

    alias_method :to_s, :inspect

    # @yield [autonym, value]
    # @yieldparam autonym [Symbol]
    # @yieldreturn [self]
    # @return [Enumerator]
    def each_pair(&block)
      return _to_enum(__method__) unless block_given?
      
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
      other.instance_of?(__class__) && (other._pairs.eql? @pairs)
    end

    # @return [Boolean]
    def ==(other)
      other.instance_of?(__class__) && (other._pairs === @pairs)
    end

    alias_method :===, :==

    protected

    def _pairs
      @pairs
    end

  end

end