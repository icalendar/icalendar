=begin
  Copyright (C) 2005 Jeff Rose

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

require 'date'

### Add some to_ical methods to classes

# class Object
#   def to_ical
#     raise(NotImplementedError, "This object does not implement the to_ical method!")
#   end
# end

module Icalendar
  module TzidSupport
    attr_accessor :icalendar_tzid
  end

  require 'delegate'
  class FrozenProxy < SimpleDelegator
    attr_accessor :ical_params
  end
end

require 'uri/generic'

class String
  def to_ical
    self
  end
end

class Fixnum
  def to_ical
    "#{self}"
  end
end

class Bignum
  def to_ical
    "#{self}"
  end
end

class Float
  def to_ical
    "#{self}"
  end
end

# From the spec: "Values in a list of values MUST be separated by a COMMA
# character (US-ASCII decimal 44)."
class Array
  def to_ical
    map{|elem| elem.to_ical}.join ','
  end
end

module URI
  class Generic
    def to_ical
      "#{self}"
    end
  end
end

class DateTime < Date
  attr_accessor :ical_params
  include Icalendar::TzidSupport

  def to_ical
    s = strftime '%Y%m%dT%H%M%S'

    # UTC time gets a Z suffix
    if icalendar_tzid == "UTC"
      s << "Z"
    end

    s
  end
end

class Date
  attr_accessor :ical_params
  def to_ical(utc = false)
    strftime '%Y%m%d'
  end
end

class Time
  attr_accessor :ical_params
  def to_ical(utc = false)
    s = strftime '%H%M%S'

    # UTC time gets a Z suffix
    if utc
      s << "Z"
    end

    s
  end
end
