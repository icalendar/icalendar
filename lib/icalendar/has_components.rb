module Icalendar

  module HasComponents

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
        custom = args.first || Component.new(component_name, component_name.upcase)
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
            begin
              klass ||= Icalendar.const_get singular_name.capitalize
              add_component klass.new, &block
            rescue NameError => ne
              puts "WARN: #{ne.message}"
              add_component Component.new(singular_name), &block
            end
          else
            add_component c, &block
          end
        end

        define_method "find_#{singular_name}" do |id|
          send(components).find { |c| c.send(find_by) == id }
        end if find_by

        define_method "add_#{singular_name}" do |c|
          send singular_name, c
        end
      end
    end
  end

end
