=begin
  Copyright (C) 2005 Jeff Rose

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

$:.unshift(File.dirname(__FILE__))

### Base classes and mixin modules

# to_ical methods for built-in classes
require 'icalendar/conversions'

# Meta-programming helper methods
require 'meta'

# Hash attributes mixin module
require 'hash_attrs'

require 'icalendar/base'
require 'icalendar/component'
require 'icalendar/rrule'

# Calendar and components
require 'icalendar/calendar'
require 'icalendar/component/event'
require 'icalendar/component/journal'
require 'icalendar/component/todo'
require 'icalendar/component/freebusy'
require 'icalendar/component/timezone'
require 'icalendar/component/alarm'

# Calendar parser
require 'icalendar/parser'

# TZINFO support
# require 'icalendar/tzinfo'
