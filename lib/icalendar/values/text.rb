module Icalendar
  module Values

    class Text < Value

      def initialize(value, params = {})
        value = value.gsub '\n', "\n"
        value.gsub! '\,', ','
        value.gsub! '\;', ';'
        value.gsub!('\\\\') { '\\' }
        super value, params
      end

      def value_ical
        value.dup.tap do |v|
          v.gsub!('\\') { '\\\\' }
          v.gsub! ';', '\;'
          v.gsub! ',', '\,'
          v.gsub! /\r?\n/, '\n'
        end
      end

      def to_ary
        [ self ]
      end

    end

  end
end
