#!/usr/bin/env ruby

# NOTE: you must have installed ruby-breakpoint in order to use this script.
# Grab it using gem with "gem install ruby-breakpoint --remote" or download
# from the website (http://ruby-breakpoint.rubyforge.org/) then run setup.rb

$:.unshift(File.dirname(__FILE__) + '/../lib')

require 'rubygems'
require 'breakpoint'

require 'icalendar'

cal = Icalendar::Parser.new(File.new("life.ics")).parse
#cal = Icalendar::Calendar.new

breakpoint
