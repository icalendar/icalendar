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

    def valid?
      self.class.required_properties.all? do |prop|
        !send(prop).nil?
      end
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
        @required_properties ||= []
      end

      def optional_properties
        @optional_properties ||= []
      end

      def required_property(prop)
        self.required_properties << prop
        define_method prop do
          instance_variable_get "@#{prop}"
        end
        define_method "#{prop}=" do |value|
          instance_variable_set "@#{prop}", value
        end
      end

      def optional_single_property(prop)
        self.optional_properties << prop
        define_method prop do
          instance_variable_get "@#{prop}"
        end
        define_method "#{prop}=" do |value|
          instance_variable_set "@#{prop}", value
        end
      end
    end
  end
end