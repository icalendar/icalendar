require 'delegate'
require 'icalendar/downcased_hash'

module Icalendar
  class TimezoneStore < ::SimpleDelegator

    def initialize
      super DowncasedHash.new({})
    end

    def self.instance
      @instance ||= new
    end

    def self.store(timezone)
      instance.store timezone
    end

    def self.retrieve(tzid)
      instance.retrieve tzid
    end

    def store(timezone)
      self[timezone.tzid] = timezone
    end

    def retrieve(tzid)
      self[tzid]
    end

  end

end
