module Icalendar

  module Properties

    def self.included(base)
      base.extend ClassMethods
      base.class_eval do
        attr_reader :custom_properties
      end
    end

    def initialize(*args)
      @custom_properties = {}
      super
    end

    def valid?(strict = false)
      self.class.required_properties.each_pair do |prop, validator|
        validator.call(self, send(prop)) or return false
      end
      self.class.mutex_properties.each do |mutexprops|
        mutexprops.map { |p| send p }.compact.size > 1 and return false
      end
      if strict
        self.class.suggested_single_properties.each do |single_prop|
          send(single_prop).size > 1 and return false
        end
      end
      true
    end

    def method_missing(method, *args, &block)
      method_name = method.to_s
      if method_name.start_with? 'x_'
        if method_name.end_with? '='
          custom_properties[method_name.chomp('=')] = args.first
        else
          custom_properties[method_name]
        end
      else
        super
      end
    end

    def respond_to_missing?(method, include_private = false)
      method.to_s.start_with?('x_') || super
    end

    module ClassMethods
      def required_properties
        @required_properties ||= {}
      end

      def optional_properties
        @optional_properties ||= []
      end

      def suggested_single_properties
        @suggested_single_properties ||= []
      end

      def mutex_properties
        @mutex_properties ||= []
      end

      def required_property(prop, validator = nil)
        validator ||= ->(component, value) { !value.nil? }
        self.required_properties[prop] = validator
        single_property prop
      end

      def required_multi_property(prop, validator = nil)
        validator ||= ->(component, value) { !value.compact.empty? }
        self.required_properties[prop] = validator
        multi_property prop
      end

      def optional_single_property(prop)
        self.optional_properties << prop
        single_property prop
      end

      def mutually_exclusive_properties(*properties)
        self.mutex_properties << properties
        properties.each do |prop|
          optional_single_property prop
        end
      end

      def optional_property(prop, suggested_single = false)
        self.optional_properties << prop
        self.suggested_single_properties << prop if suggested_single
        multi_property prop
      end

      def single_property(prop)
        define_method prop do
          instance_variable_get "@#{prop}"
        end
        define_method "#{prop}=" do |value|
          instance_variable_set "@#{prop}", value
        end
      end

      def multi_property(prop)
        property_var = "@#{prop}"

        define_method "#{prop}=" do |value|
          if value.is_a? Array
            instance_variable_set property_var, value
          else
            instance_variable_set property_var, [value]
          end
        end

        define_method prop do
          if instance_variable_defined? property_var
            instance_variable_get property_var
          else
            send "#{prop}=", []
          end
        end

        define_method "add_#{prop}" do |value|
          send(prop) << value
        end
      end
    end
  end
end
