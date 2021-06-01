# coding: us-ascii
# frozen_string_literal: true

require 'eqq'

module OptionalArgument
  class Error < StandardError; end
  class InvalidAdjustingError < Error; end
  class InvalidWritingError < Error; end

  class Store
    extend Eqq::Buildable

    # Store's singleton class should behave as builder & parser
    class << self
      private :new

      # @group Specific Constructor

      # @param [Boolean] defined_only
      # @param [Exception] exception
      # @return [Store] instance of a Store's subclass
      def parse(options, defined_only: true, exception: nil)
        begin
          unless options.respond_to?(:each_pair)
            raise MalformedOptionsError, 'options must be key-value pairs'
          end

          autonym_hash = _autonym_hash_for(options, defined_only)
          _scan_hash!(autonym_hash)

          new(autonym_hash)
        rescue MalformedOptionsError, InvalidWritingError => err
          if replacement = exception
            raise replacement.new, err
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
        @names.fetch(name.to_sym)
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
        @names.each_key.select { |name| aliased?(name) }
      end

      # @return [Array<Symbol>]
      def deprecateds
        @deprecateds.dup
      end

      # @param name [Symbol, String, #to_sym]
      def autonym?(name)
        @names.value?(name.to_sym)
      end

      # @param name [Symbol, String, #to_sym]
      def member?(name)
        @names.key?(name.to_sym)
      end

      # @param name [Symbol, String, #to_sym]
      def aliased?(name)
        member?(name) && !autonym?(name) && !deprecated?(name)
      end

      # @param name [Symbol, String, #to_sym]
      def deprecated?(name)
        @deprecateds.include?(name.to_sym)
      end

      # @param name [Symbol, String, #to_sym]
      def default?(name)
        member?(name) && @default_values.key?(autonym_for_name(name))
      end

      # @param name [Symbol, String, #to_sym]
      def condition?(name)
        member?(name) && @conditions.key?(autonym_for_name(name))
      end

      # @param name [Symbol, String, #to_sym]
      def adjuster?(name)
        member?(name) && @adjusters.key?(autonym_for_name(name))
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
        @conditions = {}            # {autonym => condition, ...}
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

      # @param [Symbol, String, #to_sym] autonym
      # @param [Boolean] must
      # @param [#===] condition
      # @param [Array<Symbol, String, #to_sym>] aliases
      # @param [Array<Symbol, String, #to_sym>] deprecateds
      # @param [Array<Symbol, String, #to_sym>] requirements
      # @param [#call] adjuster
      # @return [void]
      def add_option(autonym, condition: nil, adjuster: nil, must: false, default: nil, requirements: [].freeze, deprecateds: [].freeze, aliases: [].freeze)
        autonym = autonym.to_sym

        if condition
          _add_condition(autonym, condition)
        end

        if adjuster
          _add_adjuster(autonym, adjuster)
        end

        if must
          unless default.nil?
            raise KeyConflictError, '"must" conflict with "default"'
          end

          _add_must(autonym)
        end

        unless default.nil?
          _add_default(autonym, default)
        end

        _add_requirements(autonym, requirements)

        _add_deprecated(*deprecateds)

        [autonym, *aliases, *deprecateds].each do |name|
          _add_member(autonym, name.to_sym)
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
        raise if @conflict_autonym_sets.include?(autonyms)

        @conflict_autonym_sets << autonyms
        nil
      end

      alias_method :conflict, :add_conflict

      # @endgroup

      # @group Define options - Inner API

      # if `_func autonym [Symbol]` requires a coerced symbol.
      # Don't pass [String, #to_str].

      # @param name [Symbol]
      # @return [nil]
      def _def_instance_methods(name)
        autonym = autonym_for_name(name)
        fetcher = :"fetch_by_#{name}"

        define_method(fetcher) do
          self[autonym]
        end

        alias_method(name, fetcher)

        with_predicator = :"with_#{name}?"

        define_method(with_predicator) do
          with?(autonym)
        end

        predicator = :"#{name}?"
        alias_method(predicator, with_predicator)

        overrides = [name, fetcher, with_predicator, predicator].select { |callee|
          Store.method_defined?(callee) || Store.private_method_defined?(callee)
        }

        unless overrides.empty?
          warn("override methods: #{overrides.join(', ')}")
        end

        nil
      end

      # @param autonym [Symbol]
      # @return [value]
      def _validate_value(autonym, value)
        if adjuster?(autonym)
          adjuster = @adjusters.fetch(autonym)
          begin
            value = adjuster.call(value)
          rescue Exception => err
            raise InvalidAdjustingError, err
          end
        end

        if condition?(autonym)
          condition = @conditions.fetch(autonym)

          unless condition === value
            raise InvalidWritingError, "#{value.inspect} is deficient for #{condition}"
          end
        end

        value
      end

      # @param autonym [Symbol]
      # @return [autonym]
      def _add_must(autonym)
        @must_autonyms << autonym
      end

      # @param names [Array<Symbol>]
      # @return [nil]
      def _add_deprecated(*names)
        @deprecateds.concat(names)
        nil
      end

      # @param autonym [Symbol]
      # @param name [Symbol]
      # @return [name]
      def _add_member(autonym, name)
        if member?(name)
          raise NameError, "already defined the name: #{name}"
        end

        @names[name] = autonym
        _def_instance_methods(name)
      end

      # @param autonym [Symbol]
      # @param requirements [Array<Symbol, String, #to_sym>]
      # @return [nil]
      def _add_requirements(autonym, requirements)
        unless requirements.kind_of?(Array) && requirements.all? { |name| name.respond_to?(:to_sym) }
          raise ArgumentError, '`requirements` requires to be Array<Symbol, String>'
        end

        @requirements[autonym] = requirements.map(&:to_sym).uniq
        nil
      end

      # @param autonym [Symbol]
      # @return [value]
      def _add_default(autonym, value)
        @default_values[autonym] = value
      end

      # @param autonym [Symbol]
      # @param condition [#===]
      # @return [condition]
      def _add_condition(autonym, condition)
        unless condition.respond_to?(:===)
          raise TypeError, "#{condition.inspect} is wrong object for condition"
        end

        @conditions[autonym] = condition
      end

      # @param autonym [Symbol]
      # @param adjuster [#call]
      # @return [adjuster]
      def _add_adjuster(autonym, adjuster)
        unless adjuster.respond_to?(:call)
          raise TypeError, "#{adjuster.inspect} is wrong object for adjuster"
        end

        @adjusters[autonym] = adjuster
      end

      # @param autonym_hash [Hash]
      # @return [autonym_hash]
      def _scan_hash!(autonym_hash)
        received_autonyms = autonym_hash.keys.map { |key| autonym_for_name(key) }
        _validate_autonym_combinations(*received_autonyms)
        autonym_hash.update(_default_pairs_for(*(autonyms - received_autonyms)))
        autonym_hash
      end

      # @param options [#each_pair]
      # @param defined_only [Boolean]
      # @return [Hash]
      def _autonym_hash_for(options, defined_only)
        hash = {}

        options.each_pair do |key, value|
          key = key.to_sym

          if member?(key)
            autonym = autonym_for_name(key)
            raise KeyConflictError, key if hash.key?(autonym)

            if deprecated?(key)
              warn("`#{key}` is deprecated, use `#{autonym}`")
            end

            hash[autonym] = _validate_value(autonym, value)
          else
            if defined_only
              raise MalformedOptionsError, %Q!unknown defined name "#{key}"!
            end
          end
        end

        hash
      end

      # @param received_autonyms [Array<Symbol>]
      # @raise [MalformedOptionsError, KeyConflictError] if invalid autonym combinations
      # @return [nil]
      def _validate_autonym_combinations(*received_autonyms)
        _validate_shortage_keys(*received_autonyms)
        _validate_requirements(*received_autonyms)
        _validate_conflicts(*received_autonyms)
        nil
      end

      # @param received_autonyms [Array<Symbol>]
      # @raise [MalformedOptionsError]
      # @return [nil]
      def _validate_shortage_keys(*received_autonyms)
        shortage_keys = @must_autonyms - received_autonyms

        unless shortage_keys.empty?
          raise MalformedOptionsError,
                "shortage option parameter: #{shortage_keys.join(', ')}"
        end

        nil
      end

      # @param received_autonyms [Array<Symbol>]
      # @raise [MalformedOptionsError]
      # @return [nil]
      def _validate_requirements(*received_autonyms)
        received_autonyms.each do |autonym|
          shortage_keys = @requirements.fetch(autonym) - received_autonyms
          unless shortage_keys.empty?
            raise MalformedOptionsError,
                  "shortage option parameter for #{autonym}: #{shortage_keys.join(', ')}"
          end
        end

        nil
      end

      # @param received_autonyms [Array<Symbol>]
      # @raise [KeyConflictError]
      # @return [nil]
      def _validate_conflicts(*received_autonyms)
        conflicts = @conflict_autonym_sets.find { |conflict_autonym_set|
          (conflict_autonym_set - received_autonyms).empty?
        }

        if conflicts
          raise KeyConflictError,
                "conflict combination thrown: #{conflicts.join(', ')}"
        end

        nil
      end

      # @param autonyms [Array<Symbol>]
      # @return [Hash]  autonym => default_value
      def _default_pairs_for(*autonyms)
        {}.tap { |h|
          autonyms.each do |autonym|
            if default?(autonym)
              h[autonym] = _validate_value(autonym, @default_values.fetch(autonym))
            end
          end
        }
      end

      # @return [nil]
      def _check_requirements
        @requirements.each_pair do |autonym, names|
          names.map! { |name|
            if member?(name)
              autonym_for_name(name)
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
  end
end
