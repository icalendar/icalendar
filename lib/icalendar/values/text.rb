module Icalendar
  module Values

    class Text < Value

      def value_ical
        value.dup.tap do |v|
          v.gsub!(/\\/) { '\\\\' }
          v.gsub! /;/, '\;'
          v.gsub! /,/, '\,'
          v.gsub! /\r?\n/, '\n'
        end
      end

    end

  end
end