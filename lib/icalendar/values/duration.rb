module Icalendar
  module Values

    class Duration < Value
      alias_method :value_ical, :value
    end

  end
end