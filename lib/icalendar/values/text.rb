module Icalendar
  module Values

    class Text < Value

      def initialize(value, params = {}, include_value_param = false)
        value.gsub! '\n', "\n"
        value.gsub! '\,', ','
        value.gsub! '\;', ';'
        value.gsub!('\\\\') { '\\' }
        super value, params, include_value_param
      end

      def value_ical
        value.dup.tap do |v|
          v.gsub!('\\') { '\\\\' }
          v.gsub! ';', '\;'
          v.gsub! ',', '\,'
          v.gsub! /\r?\n/, '\n'
        end
      end

    end

  end
end