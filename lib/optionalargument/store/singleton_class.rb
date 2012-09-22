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

      new _base_hash_for(options).tap {|h|
        recieved_autonyms = h.keys.map{|key|autonym_for_name key}
        _validate_autonym_combinations(*recieved_autonyms)
        h.update _default_pairs_for(*(autonyms - recieved_autonyms))
      }
    end
    
    alias_method :for_pairs, :for_options
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
    
    private :new

    private
    
    # @return [void]
    def _init
      @names = {}                 # {autonym/alias => autonym, ...}
      @must_autonyms = []         # [autonym, autonym, ...]
      @conflict_autonym_sets = [] # [[*autonyms], [*autonyms], ...]
      @default_values = {}        # {autonym => value, ...}
      @conditions = {}            # {autonym => condiiton, ...}
      @adjusters = {}             # {autonym => adjuster, ...}

      nil
    end

    # @return [void]
    def _fix
      raise 'no assigned members yet' if @names.empty?

      instance_variables.each do |var|
        instance_variable_get(var).freeze
      end

      nil
    end
    
    DEFAULT_ADD_OPT_OPTIONS = {
      must:      false,
      aliases:   [].freeze,
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
      
      _set_condition autonym, options.fetch(:condition)
      
      if options.has_key? :adjuster
        _set_adjuster autonym, options.fetch(:adjuster)
      end
      
      if options.fetch :must
        if options.has_key? :default
          raise KeyConflictError, '"must" conflic with "default"'
        end
        
        @must_autonyms << autonym
      end

      if options.has_key? :default
        @default_values[autonym] = options.fetch :default
      end
      
      [autonym, *options.fetch(:aliases)].each do |name|
         name = name.to_sym

        if @names.has_key? name
          raise NameError, "already defined the name: #{name}"
        end
        
        @names[name] = autonym
        _def_instance_methods name
      end      

      nil
    end

    alias_method :opt, :add_option
    alias_method :on, :add_option

    # @param [Symbol] name
    # @return [void] nil - but no means this value
    def _def_instance_methods(name)
      autonym = autonym_for_name name
      fetcher = :"fetch_by_#{name}"

      define_method fetcher do
        @hash[autonym]
      end
        
      alias_method name, fetcher
        
      predicator = :"with_#{name}?"

      define_method predicator do
        @hash.has_key? autonym
      end
        
      alias_method :"#{name}?", predicator

      nil
    end
    
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

    def _set_condition(autonym, condition)
      unless condition.respond_to? :===
        raise TypeError, "#{condition.inspect} is wrong object for condition"
      end

      @conditions[autonym] = condition
    end

    def _set_adjuster(autonym, adjuster)
      unless adjuster.respond_to? :call
        raise TypeError, "#{adjuster.inspect} is wrong object for adjuster"
      end

      @adjusters[autonym] = adjuster
    end

    # @param [#each_pair] options
    # @return [Hash]
    def _base_hash_for(options)
      {}.tap {|h|
        options.each_pair do |key, value|
          key = key.to_sym
          unless @names.has_key? key
            raise MalformedOptionsError, %Q!unknown defined name "#{key}"!
          end
          raise KeyConflictError, key if h.has_key? key
          
          autonym = autonym_for_name key
          h[autonym] = _validate_argument autonym, value
        end
      }
    end

    # @raise if invalid autonym combinations
    # @return [void] nil - but no means this value
    def _validate_autonym_combinations(*recieved_autonyms)
      shortage_keys = @must_autonyms - recieved_autonyms
      
      unless shortage_keys.empty?
        raise MalformedOptionsError,
          "shortage option parameter: #{shortage_keys.join(', ')}" 
      end

      conflict = @conflict_autonym_sets.find{|con_set|
        (con_set - recieved_autonyms).empty?
      }

      if conflict
        raise KeyConflictError,
          "conflict conbination thrown: #{conflict.join(', ')}"
      end

      nil
    end

    # @param [Symbol] autonyms
    # @return [Hash] - autonym => default_value
    def _default_pairs_for(*autonyms)
      {}.tap {|h|
        autonyms.each do |auto|
          if @default_values.has_key? auto
            h[auto] = _validate_argument auto, @default_values.fetch(auto)
          end
        end
      }
    end

  end

end; end
