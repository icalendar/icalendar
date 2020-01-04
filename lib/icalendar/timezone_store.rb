require 'delegate'
require 'icalendar/downcased_hash'

module Icalendar
  class TimezoneStore < ::SimpleDelegator

    def initialize
      super DowncasedHash.new({})
    end

    def store(timezone)
      self[timezone.tzid] = timezone
    end

    def retrieve(tzid)
      self[tzid]
    end

  end

end
