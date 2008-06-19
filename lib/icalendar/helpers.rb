=begin
  Copyright (C) 2005 Jeff Rose
  Copyright (C) 2005 Sam Roberts

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

module Icalendar
  module DateProp
    # date = date-fullyear date-month date-mday
    # date-fullyear = 4 DIGIT
    # date-month = 2 DIGIT
    # date-mday = 2 DIGIT
    DATE = '(\d\d\d\d)(\d\d)(\d\d)'

    # time = time-hour [":"] time-minute [":"] time-second [time-secfrac] [time-zone]
    # time-hour = 2 DIGIT
    # time-minute = 2 DIGIT
    # time-second = 2 DIGIT
    # time-secfrac = "," 1*DIGIT
    # time-zone = "Z" / time-numzone
    # time-numzome = sign time-hour [":"] time-minute
    #  TIME = '(\d\d)(\d\d)(\d\d)(Z)?'
    TIME = '(\d\d)(\d\d)(\d\d)'

    # This method is called automatically when the module is mixed in.
    # I guess you have to do this to mixin class methods rather than instance methods.
    def self.append_features(base)
      super
      klass.extend(ClassMethods)
    end

    # This is made a sub-module just so it can be added as class 
    # methods rather than instance methods.
    module ClassMethods
      def date_property(dp, alias_name = nil)
        dp = "#{dp}".strip.downcase
        getter = dp
        setter = "#{dp}="
        query = "#{dp}?"

        unless instance_methods.include? getter
          code = <<-code
            def #{getter}(*a)
              if a.empty?
                @properties[#{dp.upcase}]
              else
                self.#{dp} = a.first
              end 
            end
          code

          module_eval code
        end
           
        unless instance_methods.include? setter
          code = <<-code
            def #{setter} a
              @properties[#{dp.upcase}] = a
            end
          code

          module_eval code
        end

        unless instance_methods.include? query
          code = <<-code
            def #{query}
              @properties.has_key?(#{dp.upcase})
            end
          code

          module_eval code
        end

        # Define the getter
        getter = "get#{property.to_s.capitalize}"
        define_method(getter.to_sym) do
          puts "inside getting..."
          getDateProperty(property.to_s.upcase)  
        end
        
        # Define the setter
        setter = "set#{property.to_s.capitalize}"        
        define_method(setter.to_sym) do |*params|
          date = params[0]
          utc = params[1]
          puts "inside setting..."
          setDateProperty(property.to_s.upcase, date, utc)
        end

        # Create aliases if a name was specified
#         if not aliasName.nil?
#           gasym = "get#{aliasName.to_s.capitalize}".to_sym 
#           gsym = getter.to_sym
#           alias gasym gsym 
          
#           sasym = "set#{aliasName.to_s.capitalize}".to_sym 
#           ssym = setter.to_sym
#           alias sasym ssym 
#        end
      end

    end
    
  end
end
