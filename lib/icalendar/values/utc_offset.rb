module Icalendar
  module Values

    class UtcOffset < Value
      alias_method :value_ical, :value
    end
  end
end