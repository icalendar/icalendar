## Unreleased
 - Add Ruby 3.3 to the test matrix
 - Move from old History.txt file to modern CHANGELOG.md - Guillaume Briday

## 2.10.1 - 2023-12-01
 - Parsing now handles VTIMEZONE blocks defined after their TZID is used in events and other components

## 2.10.0 - 2023-11-01
 - Add changelog metadata to gemspec - Juri Hahn
 - Attempt to rescue timezone info when given a nonstandard tzid with no VTIMEZONE
 - Move Values classes that shouldn't be directly used into Helpers module

## 2.9.0 - 2023-08-11
 - Always include the VALUE of Event URLs for improved compatibility - Sean Kelley
 - Improved parse performance - Thomas Cannon
 - Add helper methods for other Calendar method verbs
 - bugfix: Require stringio before use in Parser - vwyu

## 2.8.0 - 2022-07-10
 - Fix compatibility with ActiveSupport 7 - Pat Allan
 - Set default action of "DISPLAY" on alarms - Rikson
 - Add license information to gemspec - Robert Reiz
 - Support RFC7986 properties - Daniele Frisanco

## 2.7.1 - 2021-03-14
 - Recover from bad line-wrapping code that splits in the middle of Unicode code points
 - Add a verbose option to the Parser to quiet some of the chattier log entries

## 2.7.0 - 2020-09-12
 - Handle custom component names, with and without X- prefix
 - Fix Component lookup to avoid namespace collisions

## 2.6.1 - 2019-12-07
 - Improve performance when generating large ICS files - Alex Balhatchet

## 2.6.0 - 2019-11-26
 - Improve performance for calculating timezone offsets - Justin Howard
 - Make it possible to de/serialize with Marshal - Pawel Niewiadomski
 - Avoid FrozenError when running with frozen_string_literal
 - Update minimum Ruby version to supported versions

## 2.5.3 - 2019-03-04
 - Improve parsing performance - nehresma
 - Support tzinfo 2.0 - Misty De Meo

## 2.5.2 - 2018-12-08
 - Remove usage of the global TimezoneStore instance, in favor of a local variable in the parser
 - Deprecate TimezoneStore class methods

## 2.5.1 - 2018-10-30
 - Fix usage without ActiveSupport installed.

## 2.5.0 - 2018-09-10
 - Set timezone information from VTIMEZONE components in cases that ActiveSupport can't figure it out (or isn't installed)
 - Prevent rewinding the Parser IO input during parsing - Niels Laukens
 - Update tested/supported ruby versions & documentation updates.

## 2.4.1 - 2016-09-03
 - Fix parsing multiple calendars or components in same file - Patrick Schnetger
 - Fix multi-byte folding bug - Niels Laukens
 - Fix typos across the code - Martin Edenhofer & yuuji.yaginuma

## 2.4.0 - 2016-07-04
 - Enable parsing individual ICalendar components - Patrick Schnetger
 - many bug fixes. Thanks to Quan Sun, Garry Shutler, Ryan Bigg, Patrick Schnetger and others
 - README/documentation updates. Thanks to JonMidhir and Hendrik Sollich

## 2.3.0 - 2015-04-26
 - fix value parameter for properties with multiple values
 - fix error when assigning Icalendar::Values::Array to a component
 - Fall back to Icalendar::Values::Date if Icalendar::Values::DateTime is not given a properly formatted value
 - Downcase the keys in ical_params to ensure we aren't assigning both tzid and TZID

## 2.2.2 - 2014-12-27
 - add a `has_#{component}?` method for testing if component exists - John Hope
 - add documentation & tests for organizer attribute - Ben Walding

## 2.2.1 - 2014-12-03
 - Prevent crashes when using ActiveSupport::TimeWithZone in multi-property DateTime fields - Danny (tdg5)
 - Ensure TimeWithZone is loaded before using, not just ActiveSupport - Jeremy Evans
 - Improve error message on unparseable DateTimes - Garry Shutler

## 2.2.0 - 2014-09-23
 - Default to non-strict parsing
 - Enable sorting events by dtstart - Mark Rickert
 - Better tolerate malformed lines in parser - Garry Shutler
 - Deduplicate timezone code - Jan Vlnas
 - Eliminate warnings - rochefort

## 2.1.2 - 2014-09-10
 - Fix timezone abbreviation generation - Jan Vlnas
 - Fix timezone repeat rules for end of month

## 2.1.1 - 2014-07-23
 - Quiet TimeWithZone support logging
 - Use SecureRandom.uuid - antoinelyset

## 2.1.0 - 2014-06-17
 - Enable parsing all custom properties, not just X- prefixed ones
   Requires non-strict parsing
 - Fixed bugs when using non-MRI ruby interpreters
 - Fix bug copying OpenStruct-backed value types

## 2.0.1 - 2014-04-27
 - Re-add support for ruby 1.9.2

## 2.0.0 - 2014-04-22
 - Add Icalendar.logger class & logging in Parser
 - Support tzinfo ~> 0.3 and ~> 1.1

## 2.0.0.beta.2 - 2014-04-11
 - Add uid & acknowledged fields from valarm extensions
 - Swallow NoMethodError on non-strict parsers
 - Expose a parse_property method on Icalendar::Parser

## 2.0.0.beta.1 - 2014-03-30
 - Rewrite for easier development going forward.

## 1.5.2 - 2014-02-22
 - Output timezone components first
 - Fix undefined local variable or method 'e' - Jason Stirk

## 1.5.1 - 2014-02-27
 - Check for dtend existence before setting timezone - Jonas Grau
 - Clean up and refactor components - Kasper Timm Hansen

## 1.5.0 - 2013-12-06
 - Support for custom x- properties - Jake Craige

## 1.4.5 - 2013-11-14
 - Fix Geo accessor methods - bouzuya
 - Add ical_multiline_property :related_to for Alarm
 - Allow using multi setters to append single values

## 1.4.4 - 2013-11-05
 - Allow user to handle TZInfo::AmbiguousTime error - David Bradford
 - Better handling of multiple exdate and rdate values

## 1.4.3 - 2013-09-18
 - Fix concatenation of multiple BYWEEK or BYMONTH recurrence rules

## 1.4.2 - 2013-09-11
 - Double Quote parameter values that contain forbidden characters
 - Update Component#respond_to? to match Ruby 2.0 - Keith Marcum

## 1.4.1 - 2013-06-25
 - Don't escape semicolon in GEO property - temirov
 - Allow access to various parts of RRule class

## 1.4.0 - 2013-05-21
 - Implement ACKNOWLEDGED property for VALARM - tsuzuki08
 - Output VERSION property as first line after BEGIN:VCALENDAR
 - Check for unbounded timezone transitions in tzinfo

## 1.3.0 - 2013-03-31
 - Lenient parsing mode ignores unknown properties - David Grandinetti
 - VTIMEZONE positive offsets properly have "+" prepended (Fixed issue
#18) - Benjamin Jorgensen (sorry for misspelling your last name)

## 1.2.4 - 2013-03-26
 - Proxy component values now frozen in Ruby 2.0 (Fixed issue #17)
 - Clean up gemspec for cleaner installing via bundler/git

## 1.2.3 - 2013-03-09
 - Call `super` from Component#method_missing
 - Clean up warnings in test suite
 - Add Gemfile for installing development dependencies

## 1.2.2 - 2013-02-16
 - added TZURL property to Timezone component - spacepixels
 - correct days in RRule ("[TU,WE]" -> "TU,WE") - Christoph Finkensiep

## 1.2.1 - 2012-11-12
 - Adds uid property to alarms to support iCloud - Jeroen Jacobs
 - Fix up testing docs - Eric Carty-Fickes
 - Fix parsing property params that have : in them - Sean Dague
 - Clean up warnings in test suite - Sean Dague

## 1.2.0 - 2012-08-30
* Fix calendar handling for dates < 1000 - Ryan Ahearn
* Updated license to GPL/BSD/Ruby at users option

## 1.1.6 - 2011-03-10
* Fix todo handling (thanks to Frank Schwarz)
* clean up a number of warnings during test runs

## 1.1.5 - 2010-06-21
* Fix for windows line endings (thanks to Rowan Collins)

## 1.1.4 - 2010-04-23
* Fix for RRULE escaping
* Fix tests so they run under 1.8.7 in multiple environments
* Readme fix

## 1.1.3 - 2010-03-15
* Revert component sorting behavior that I was trying to make
the tests run more consistantly on different platforms.
* Added new test for multiple events in a calendar which caught that break.

## 1.1.2 - 2010-03-10

* Convert project to newgem to make for easier publishing
