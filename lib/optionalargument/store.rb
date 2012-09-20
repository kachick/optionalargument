require 'keyvalidatable'

module OptionalArgument

  class Store

    class << self

      # @param [Hash] options
      # @return [Store]
      def for_options(options)
        hash = {}
  
        options.each_pair do |key, value|
          key = key.to_sym
          unless @names.has_key? key
            raise MalformedOptionsError, %Q!unknown defined name "#{key}"!
          end
          raise KeyConflictError, key if hash.has_key? key
          autonym = autonym_for_name key

          hash[autonym] = value
        end

        recieved_autonyms = hash.keys.map{|key|autonym_for_name key}

        shortage_keys = @must_autonyms - recieved_autonyms

        unless shortage_keys.empty?
          raise TypeError,
            "shortage option parameter: #{shortage_keys.join(', ')}" 
        end

        if conflict = @conflict_autonyms.find{|con|
            (con - recieved_autonyms).empty?
          }
          raise KeyConflictError,
            "conflict conbination thrown: #{conflict.join(', ')}"
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

      DEFAULT_ADD_OPT_OPTIONS = {
        must:    false,
        aliases: [].freeze
      }.freeze

      if respond_to? :private_constant
        private_constant :DEFAULT_ADD_OPT_OPTIONS
      end

      # @param [Symbol, String, #to_sym] autonym
      # @param [Hash] options
      # @return [nil]
      def add_option(autonym, options={})
        autonym = autonym.to_sym
        options = DEFAULT_ADD_OPT_OPTIONS.merge(options).extend KeyValidatable
        options.validate_keys must: [:must, :aliases], let: [:default]

        if options[:must]
          if options.has_key? :default
            raise KeyConflictError, '"must" conflic "default"'
          end

          @must_autonyms << autonym
        end

        [autonym, *options[:aliases].map(&:to_sym)].each do |name|
          raise KeyError if @names.has_key? name

          @names[name] = autonym

          define_method name do
            if options.has_key? :default
              @hash.has_key?(autonym) ? @hash[autonym] : options[:default]
            else
              @hash[autonym]
            end
          end

          predicate = :"with_#{name}?"

          define_method predicate do
            if options.has_key? :default
              true
            else
              @hash.has_key? autonym
            end
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
        raise if @conflict_autonyms.include? autonyms
        
        @conflict_autonyms << autonyms
        nil
      end

      alias_method :conflict, :add_conflict

    end

    # @param [Hash] hash
    def initialize(hash)
      @hash = hash
    end

    # @param [Symbol, String, #to_sym] name
    def [](name)
      @hash.fetch self.class.autonym_for_name(name)
    end

    # @return [String]
    def inspect
      body = @hash.each_pair.map{|k, v|"#{k}=#{v.inspect}"}.join(', ')
      "#<#{self.class.name}: #{body}>"
    end

    alias_method :to_s, :inspect

  end

end
