require 'keyvalidatable'
require 'validation'

module OptionalArgument; class Store

  extend Validation::Condition
  extend Validation::Adjustment

  class << self

    # @param [Hash, Struct, #each_pair] options
    # @return [Store]
    def for_options(options)
      unless options.respond_to? :each_pair
        raise MalformedOptionsError, 'options must be key-value pairs'
      end

      hash = {}
      
      options.each_pair do |key, value|
        key = key.to_sym
        unless @names.has_key? key
          raise MalformedOptionsError, %Q!unknown defined name "#{key}"!
        end
        raise KeyConflictError, key if hash.has_key? key

        autonym = autonym_for_name key
        hash[autonym] = _validate_argument autonym, value
      end
      
      recieved_autonyms = hash.keys.map{|key|autonym_for_name key}
      
      shortage_keys = @must_autonyms - recieved_autonyms
      
      unless shortage_keys.empty?
        raise MalformedOptionsError,
          "shortage option parameter: #{shortage_keys.join(', ')}" 
      end
      
      if conflict = @conflict_autonym_sets.find{|con_set|
          (con_set - recieved_autonyms).empty?
        }
        raise KeyConflictError,
          "conflict conbination thrown: #{conflict.join(', ')}"
      end

      (autonyms - recieved_autonyms).each do |unsetted_autonym|
        if @default_values.has_key? unsetted_autonym
          hash[unsetted_autonym] = \
            _validate_argument unsetted_autonym,
                               @default_values.fetch(unsetted_autonym)
        end
      end
      
      new hash
    end
    
    alias_method :parse, :for_options
    
    # @param [Symbol, String, #to_sym] name
    # @return [Symbol] autonym
    def autonym_for_name(name)
      @names.fetch name.to_sym
    end
    
    # @return [Array<Symbol>]
    def autonyms
      @names.values
    end
    
    private
    
    def _init
      @names = {}                 # {autonym/alias => autonym, ...}
      @must_autonyms = []         # [autonym, autonym, ...]
      @conflict_autonym_sets = [] # [[*autonyms], [*autonyms], ...]
      @default_values = {}        # {autonym => value, ...}
      @conditions = {}            # {autonym => condiiton, ...}
      @adjusters = {}             # {autonym => adjuster, ...}
    end
    
    DEFAULT_ADD_OPT_OPTIONS = {
      must:    false,
      aliases: [].freeze,
      condition: BasicObject
    }.freeze
    
    if respond_to? :private_constant
      private_constant :DEFAULT_ADD_OPT_OPTIONS
    end
    
    # @param [Symbol, String, #to_sym] autonym
    # @param [Hash] options
    # @option options [Boolean] :must
    # @option options :default
    # @option options [Array<Symbol>] :aliases
    # @option options [#===] :condition
    # @option options [#call] :adjuster
    # @return [nil]
    def add_option(autonym, options={})
      autonym = autonym.to_sym
      options = DEFAULT_ADD_OPT_OPTIONS.merge(options).extend KeyValidatable
      options.validate_keys must: [:must, :aliases, :condition],
                            let:  [:default, :adjuster]
      
      condition = options.fetch :condition
      if condition.respond_to? :===
        @conditions[autonym] = condition
      else
        raise TypeError, 'wrong object for condition'
      end
      
      if options.has_key? :adjuster
        adjuster = options.fetch :adjuster
        if adjuster.respond_to? :call
          @adjusters[autonym] = adjuster
        else
          raise TypeError, 'wrong object for adjuster'
        end
      end
      
      if options.fetch :must
        if options.has_key? :default
          raise KeyConflictError, '"must" conflic "default"'
        end
        
        @must_autonyms << autonym
      end

      if options.has_key? :default
        @default_values[autonym] = options.fetch(:default)
      end
      
      [autonym, *options.fetch(:aliases).map(&:to_sym)].each do |name|
        if @names.has_key? name
          raise NameError, "already defined the name: #{name}"
        end
        
        @names[name] = autonym
        
        fetch = :"fetch_by_#{name}"

        define_method fetch do
          @hash[autonym]
        end
        
        alias_method name, fetch
        
        predicate = :"with_#{name}?"

        define_method predicate do
          @hash.has_key? autonym
        end
        
        alias_method :"#{name}?", predicate
      end
      
      nil
    end

    alias_method :opt, :add_option
    alias_method :on, :add_option
    
    # @param [Symbol, String, #to_sym] autonym1
    # @param [Symbol, String, #to_sym] autonym2
    # @param [Symbol, String, #to_sym] autonyms
    # @return [nil]
    def add_conflict(autonym1, autonym2, *autonyms)
      autonyms = [autonym1, autonym2, *autonyms].map(&:to_sym)
      raise ArgumentError unless autonyms == autonyms.uniq
      not_autonyms = (autonyms - @names.values)
      unless not_autonyms.empty?
        raise ArgumentError, "contain not autonym: #{not_autonyms.join(', ')}"
      end
      raise if @conflict_autonym_sets.include? autonyms
      
      @conflict_autonym_sets << autonyms
      nil
    end

    alias_method :conflict, :add_conflict
    
    # @param [#===] condition
    def _valid?(condition, value)
      condition === value
    end

    # @param [Symbol] autonym - !MUST! already converted native autonym
    # @return [value]
    def _validate_argument(autonym, value)
      if @adjusters.has_key? autonym
        adjuster = @adjusters.fetch autonym
        begin
          value = adjuster.call value
        rescue Exception
          raise Validation::InvalidAdjustingError, $!
        end
      end

      condition = @conditions.fetch(autonym)
      
      unless _valid? condition, value
        raise Validation::InvalidWritingError,
          "#{value.inspect} is deficient for #{condition}"
      end

      value
    end
 
  end

end; end
