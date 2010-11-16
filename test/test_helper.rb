require 'stringio'
require 'test/unit'
if ENV['UNDER_HUDSON']
  require 'rubygems'
  require 'ci/reporter/rake/test_unit_loader'
end
require File.dirname(__FILE__) + '/../lib/icalendar'
