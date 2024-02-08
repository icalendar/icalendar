# frozen_string_literal: true

module Icalendar

  module HasComponents

    def self.included(base)
      base.extend ClassMethods
      base.class_eval do
        attr_reader :custom_components
      end
    end

    def initialize(*args)
      @custom_components = Hash.new
      super
    end

    def add_component(c)
      c.parent = self
      yield c if block_given?
      send("#{c.name.downcase}s") << c
      c
    end

    def add_custom_component(component_name, c)
      c.parent = self
      yield c if block_given?
      (custom_components[component_name.downcase.gsub("-", "_")] ||= []) << c
      c
    end

    def custom_component(component_name)
      custom_components[component_name.downcase.gsub("-", "_")] || []
    end

    METHOD_MISSING_ADD_REGEX = /^add_(x_\w+)$/.freeze
    METHOD_MISSING_X_FLAG_REGEX = /^x_/.freeze

    def method_missing(method, *args, &block)
      method_name = method.to_s
      if method_name =~ METHOD_MISSING_ADD_REGEX
        component_name = $1
        custom = args.first || Component.new(component_name, component_name.upcase)
        add_custom_component(component_name, custom, &block)
      elsif method_name =~ METHOD_MISSING_X_FLAG_REGEX && custom_component(method_name).size > 0
        custom_component method_name
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      string_method = method_name.to_s
      string_method.start_with?('add_x_') || custom_component(string_method).size > 0 || super
    end

    module ClassMethods
      def components
        @components ||= []
      end

      def component(singular_name, find_by = :uid, klass = nil)
        components = "#{singular_name}s"
        self.components << components
        component_var = "@#{components}"

        define_method components do
          if instance_variable_defined? component_var
            instance_variable_get component_var
          else
            instance_variable_set component_var, []
          end
        end

        define_method singular_name do |c = nil, &block|
          if c.nil?
            c = begin
              klass ||= Icalendar.const_get singular_name.capitalize
              klass.new
            rescue NameError => ne
              Icalendar.logger.warn ne.message
              Component.new singular_name
            end
          end

          add_component c, &block
        end

        define_method "find_#{singular_name}" do |id|
          send(components).find { |c| c.send(find_by) == id }
        end if find_by

        define_method "add_#{singular_name}" do |c|
          send singular_name, c
        end

        define_method "has_#{singular_name}?" do
          !send(components).empty?
        end
      end
    end
  end

end
