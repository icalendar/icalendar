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
  def to_ical(utc = false)
    s = ""
    
    # 4 digit year
    s << self.year.to_s
    
    # Double digit month
    s << "0" unless self.month > 9 
    s << self.month.to_s
    
    # Double digit day
    s << "0" unless self.day > 9 
    s << self.day.to_s

    s << "T"
        
    # Double digit hour
    s << "0" unless self.hour > 9 
    s << self.hour.to_s
    
    # Double digit minute
    s << "0" unless self.min > 9 
    s << self.min.to_s
    
    # Double digit second
    s << "0" unless self.sec > 9 
    s << self.sec.to_s

    # UTC time gets a Z suffix
    if utc
      s << "Z"
    end

    s
  end
end

class Date
  def to_ical(utc = false)
    s = ""
        
    # 4 digit year
    s << self.year.to_s
    
    # Double digit month
    s << "0" unless self.month > 9 
    s << self.month.to_s
    
    # Double digit day
    s << "0" unless self.day > 9 
    s << self.day.to_s
  end
end

class Time
  def to_ical(utc = false)
    s = ""

    # Double digit hour
    s << "0" unless self.hour > 9 
    s << self.hour.to_s
    
    # Double digit minute
    s << "0" unless self.min > 9 
    s << self.min.to_s
    
    # Double digit second
    s << "0" unless self.sec > 9 
    s << self.sec.to_s

    # UTC time gets a Z suffix
    if utc
      s << "Z"
    end

    s
  end
end
