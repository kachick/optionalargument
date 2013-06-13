# coding: us-ascii

require 'keyvalidatable'
require 'validation'

module OptionalArgument; class Store

  extend Validation::Condition
  extend Validation::Adjustment

  class << self

    private :new

    # @group Specific Constructor

    DEFAULT_PARSE_OPTIONS = {
      defined_only: true,
      exception: nil
    }.freeze
    
    if respond_to? :private_constant
      private_constant :DEFAULT_PARSE_OPTIONS
    end

    # @param options [Hash, Struct, #each_pair]
    # @option options [Boolean] :defined_only
    # @option options [Exception] :exception
    # @param parsing_options [Hash]
    # @return [Store]
    def parse(options, parsing_options={})
      parsing_options = DEFAULT_PARSE_OPTIONS.merge parsing_options
      KeyValidatable.validate_keys parsing_options,
                                   must: [:defined_only, :exception]

      begin
        unless options.respond_to? :each_pair
          raise MalformedOptionsError, 'options must be key-value pairs'
        end

        autonym_hash = _autonym_hash_for options, parsing_options.fetch(:defined_only)
        _scan_hash! autonym_hash

        new autonym_hash
      rescue MalformedOptionsError, Validation::InvalidError => err
        if replacemet = parsing_options.fetch(:exception)
          raise replacemet.new, err
        else
          raise err
        end
      end
    end
    
    alias_method :for_options, :parse
    alias_method :for_pairs, :parse

    # @endgroup

    # @group Access option names
    
    # @param name [Symbol, String, #to_sym]
    # @return [Symbol]
    def autonym_for_name(name)
      @names.fetch name.to_sym
    end

    alias_method :autonym_for, :autonym_for_name
    
    # @return [Array<Symbol>] - autonym, autonym, ...
    def autonyms
      @names.values.uniq
    end

    # @return [Array<Symbol>]
    def members
      @names.keys
    end

    # @return [Array<Symbol>]
    def aliases
      @names.each_key.select{|name|aliased? name}
    end

    # @return [Array<Symbol>]
    def deprecateds
      @deprecateds.dup
    end

    # @param name [Symbol, String, #to_sym]
    def autonym?(name)
      @names.has_value? name.to_sym
    end

    # @param name [Symbol, String, #to_sym]
    def member?(name)
      @names.has_key? name.to_sym
    end

    # @param name [Symbol, String, #to_sym]
    def aliased?(name)
      member?(name) && !autonym?(name) && !deprecated?(name)
    end

    # @param name [Symbol, String, #to_sym]
    def deprecated?(name)
      @deprecateds.include? name.to_sym
    end

    # for debug
    # @return [Hash] - autonym/alias/deprecated => autonym, ...
    def names_with_autonym
      @names.dup
    end

    # @endgroup

    private

    # @group Build and Fix Class's structure - Inner API
    
    # @return [nil]
    def _init
      @names = {}                 # {autonym/alias/deprecated => autonym, ...}
      @must_autonyms = []         # [autonym, autonym, ...]
      @conflict_autonym_sets = [] # [[*autonyms], [*autonyms], ...]
      @requirements = {}          # {autonym => [*requirements], ...]
      @deprecateds = []           # [deprecated, deprecated, ...]
      @default_values = {}        # {autonym => value, ...}
      @conditions = {}            # {autonym => condiiton, ...}
      @adjusters = {}             # {autonym => adjuster, ...}

      nil
    end

    # @return [nil]
    def _fix
      raise 'no assigned members yet' if @names.empty?

      instance_variables.each do |var|
        instance_variable_get(var).freeze
      end

      _check_requirements

      nil
    end

    # @endgroup
    
    # @group Define options

    DEFAULT_ADD_OPT_OPTIONS = {
      must:         false,
      aliases:      [].freeze,
      deprecateds:  [].freeze,
      requirements: [].freeze,
      condition:    BasicObject
    }.freeze
    
    if respond_to? :private_constant
      private_constant :DEFAULT_ADD_OPT_OPTIONS
    end
    
    # @param autonym [Symbol, String, #to_sym]
    # @param options [Hash]
    # @option options [Boolean] :must
    # @option options :default
    # @option options [Array<Symbol, String, #to_sym>] :aliases
    # @option options [Array<Symbol, String, #to_sym>] :deprecateds
    # @option options [Array<Symbol, String, #to_sym>] :requirements
    # @option options [#===] :condition
    # @option options [#call] :adjuster
    # @return [nil]
    def add_option(autonym, options={})
      autonym = autonym.to_sym
      options = DEFAULT_ADD_OPT_OPTIONS.merge options
      KeyValidatable.validate_keys(
        options,
        must: [:must, :aliases, :deprecateds, :requirements, :condition],
        let:  [:default, :adjuster]
      )
      
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

      requirements = options.fetch :requirements

      unless requirements.kind_of?(Array) && requirements.all?{|name|name.respond_to?(:to_sym)}
        raise ArgumentError, "`requirements` requires to be Array<Symbol, String>"
      end

      @requirements[autonym] = requirements.map(&:to_sym).uniq

      deprecateds = options.fetch :deprecateds

      @deprecateds.concat deprecateds

      [autonym, *options.fetch(:aliases), *deprecateds].each do |name|
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

    # @param autonym1 [Symbol, String, #to_sym]
    # @param autonym2 [Symbol, String, #to_sym]
    # @param autonyms [Symbol, String, #to_sym]
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

    # @endgroup

    # @group Define options - Inner API

    # @param _name [Symbol]
    # @return [nil]
    def _def_instance_methods(_name)
      autonym = autonym_for_name _name
      fetcher = :"fetch_by_#{_name}"

      define_method fetcher do
        self[autonym]
      end
        
      alias_method _name, fetcher

      with_predicator = :"with_#{_name}?"

      define_method with_predicator do
        with? autonym
      end

      predicator = :"#{_name}?"
      alias_method predicator, with_predicator

      overrides = [_name, fetcher, with_predicator, predicator].select{|callee|
        Store.method_defined?(callee) || Store.private_method_defined?(callee)
      }

      unless overrides.empty?
        warn "override methods: #{overrides.join(', ')}"
      end

      nil
    end

    # @endgroup
    
    # @group Constructor - Inner API

    # @param condition [#===]
    def _valid?(condition, value)
      condition === value
    end

    # @param autonym [Symbol] !MUST! already converted native autonym
    # @return [value]
    def _validate_value(autonym, value)
      if @adjusters.has_key? autonym
        adjuster = @adjusters.fetch autonym
        begin
          value = adjuster.call value
        rescue Exception => err
          raise Validation::InvalidAdjustingError, err
        end
      end

      condition = @conditions.fetch(autonym)
      
      unless _valid? condition, value
        raise Validation::InvalidWritingError,
          "#{value.inspect} is deficient for #{condition}"
      end

      value
    end
    
    # @param autonym [Symbol]
    # @param condition [#===]
    # @return [condition]
    def _set_condition(autonym, condition)
      unless condition.respond_to? :===
        raise TypeError, "#{condition.inspect} is wrong object for condition"
      end

      @conditions[autonym] = condition
    end

    # @param autonym [Symbol]
    # @param adjuster [#call]
    # @return [adjuster]
    def _set_adjuster(autonym, adjuster)
      unless adjuster.respond_to? :call
        raise TypeError, "#{adjuster.inspect} is wrong object for adjuster"
      end

      @adjusters[autonym] = adjuster
    end

    # @param autonym_hash [Hash]
    # @return [autonym_hash]
    def _scan_hash!(autonym_hash)
      recieved_autonyms = autonym_hash.keys.map{|key|autonym_for_name key}
      _validate_autonym_combinations(*recieved_autonyms)
      autonym_hash.update _default_pairs_for(*(autonyms - recieved_autonyms))
      autonym_hash
    end

    # @param options [#each_pair]
    # @param defined_only [Boolean]
    # @return [Hash]
    def _autonym_hash_for(options, defined_only)
      hash = {}

      options.each_pair do |key, value|
        key = key.to_sym
        
        if @names.has_key? key
          autonym = autonym_for_name key
          raise KeyConflictError, key if hash.has_key? autonym

          if deprecated? key
            warn "`#{key}` is deprecated, use `#{autonym}`"
          end

          hash[autonym] = _validate_value autonym, value
        else
          if defined_only
            raise MalformedOptionsError, %Q!unknown defined name "#{key}"!
          end
        end
      end

      hash
    end

    # @param recieved_autonyms [Array<Symbol>]
    # @raise [MalformedOptionsError, KeyConflictError] if invalid autonym combinations
    # @return [nil]
    def _validate_autonym_combinations(*recieved_autonyms)
      _validate_shortage_keys(*recieved_autonyms)
      _validate_requirements(*recieved_autonyms)
      _validate_conflicts(*recieved_autonyms)
      nil
    end

    # @param recieved_autonyms [Array<Symbol>]
    # @raise [MalformedOptionsError]
    # @return [nil]
    def _validate_shortage_keys(*recieved_autonyms)
      shortage_keys = @must_autonyms - recieved_autonyms
      
      unless shortage_keys.empty?
        raise MalformedOptionsError,
          "shortage option parameter: #{shortage_keys.join(', ')}"
      end

      nil
    end

    # @param recieved_autonyms [Array<Symbol>]
    # @raise [MalformedOptionsError]
    # @return [nil]
    def _validate_requirements(*recieved_autonyms)
      recieved_autonyms.each do |autonym|
        shortage_keys = @requirements.fetch(autonym) - recieved_autonyms
        unless shortage_keys.empty?
          raise MalformedOptionsError,
            "shortage option parameter for #{autonym}: #{shortage_keys.join(', ')}"
        end
      end

      nil
    end

    # @param recieved_autonyms [Array<Symbol>]
    # @raise [KeyConflictError]
    # @return [nil]
    def _validate_conflicts(*recieved_autonyms)
      conflicts = @conflict_autonym_sets.find{|conflict_autonym_set|
        (conflict_autonym_set - recieved_autonyms).empty?
      }

      if conflicts
        raise KeyConflictError,
          "conflict conbination thrown: #{conflicts.join(', ')}"
      end

      nil
    end

    # @param autonyms [Array<Symbol>]
    # @return [Hash]  autonym => default_value
    def _default_pairs_for(*autonyms)
      {}.tap {|h|
        autonyms.each do |auto|
          if @default_values.has_key? auto
            h[auto] = _validate_value auto, @default_values.fetch(auto)
          end
        end
      }
    end

    # @return [nil]
    def _check_requirements
      @requirements.each_pair do |autonym, names|
        names.map!{|name|
          if @names.has_key? name
            autonym_for_name name
          else
            raise ArgumentError,
              "`#{autonym}` with invalid requirements `#{names}`"
          end
        }
      end

      nil
    end

    # @endgroup

  end

end; end