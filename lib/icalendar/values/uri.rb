module Icalendar
  module Values

    class Uri < Value
      alias_method :value_ical, :value
    end

  end
end