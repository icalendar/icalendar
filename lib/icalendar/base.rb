=begin
  Copyright (C) 2005 Jeff Rose
  Copyright (C) 2009-2010 Sean Dague
  Copyright (C) 2013- Ryan Ahearn

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end
require 'logger'

module Icalendar #:nodoc:

  VERSION = '1.5.4'

  # A simple error class to differentiate iCalendar library exceptions
  # from ruby language exceptions or others.
  class IcalendarError < StandardError #:nodoc:
  end

  # Exception used when the library encounters a bogus calendar component.
  class UnknownComponentClass < IcalendarError
  end

  # Exception used when the library encounters a bogus property type.
  class UnknownPropertyMethod< IcalendarError
  end

  # Exception used when the library encounters a bogus property value.
  class InvalidPropertyValue < IcalendarError
  end

  # This class serves as the base class for just about everything in
  # the library so that the logging system can be configured in one place.
  class Base
    @@logger = Logger.new(STDERR)
    @@logger.level = Logger::FATAL

    def self.debug
      @@logger.level = Logger::DEBUG
    end

    def self.quiet
      @@logger.level = Logger::FATAL
    end
  end
end
