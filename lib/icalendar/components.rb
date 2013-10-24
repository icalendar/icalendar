module Icalendar

  module Components

    def self.included(base)
      base.extend ClassMethods
      base.class_eval do
        attr_reader :custom_components
      end
    end

    def initialize(*args)
      @custom_components = Hash.new { |h, k| h[k] = [] }
      super
    end

    def add_component(c)
      c.parent = self
      yield c if block_given?
      send("#{c.name.downcase}s") << c
      c
    end

    def method_missing(method, *args, &block)
      method_name = method.to_s
      if method_name =~ /^add_(x_\w+)$/
        component_name = $1
        custom = args.first || Component.new(component_name)
        custom_components[component_name] << custom
        yield custom if block_given?
        custom
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      method_name.to_s.start_with?('add_x_') || super
    end

    module ClassMethods
      def components
        @components ||= []
      end

      def component(singular_name)
        component = "#{singular_name}s"
        self.components << component
        component_var = "@#{component}"
        define_method component do
          if instance_variable_defined? component_var
            instance_variable_get component_var
          else
            instance_variable_set component_var, []
          end
        end
        define_method "find_#{singular_name}" do |uid|
          send(component).find { |c| c.uid == uid }
        end
        define_method "add_#{singular_name}" do |c|
          send singular_name, c
        end
      end
    end
  end

end