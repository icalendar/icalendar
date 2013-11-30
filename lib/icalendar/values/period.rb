module Icalendar
  module Values

    class Period < Value
      alias_method :value_ical, :value
    end
  end
end