#!/usr/bin/ruby

# NOTE: you must have installed ruby-breakpoint in order to use this script.
# Grab it using gem with "gem install ruby-breakpoint --remote" or download
# from the website (http://ruby-breakpoint.rubyforge.org/) then run setup.rb

$:.unshift(File.dirname(__FILE__) + '/../lib')

require 'breakpoint'
require 'icalendar'

cals = Icalendar::Parser.new(File.new(ARGV[0])).parse
puts "Parsed #{cals.size} calendars"

cal = cals.first
puts "First calendar has:"
puts "#{cal.events.size} events"
puts "#{cal.todos.size} todos"
puts "#{cal.journals.size} journals"

test = File.new("rw.ics", "w")
test.write(cal.to_ical)
test.close
