require 'delegate'
require 'icalendar/downcased_hash'

module Icalendar
  class TimezoneStore < ::SimpleDelegator

    def initialize
      super DowncasedHash.new({})
    end

    def self.instance
      Thread.current[:timezone_store] ||= new
    end
    def self.instance=(store)
      Thread.current[:timezone_store] = store
    end
    def self.reset
      instance = nil
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
