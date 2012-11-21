require File.dirname(__FILE__) + '/../test_helper.rb'

require 'date'

class TestTodo < Test::Unit::TestCase
  include Icalendar

  def test_todo_fields

    cal = Calendar.new

    cal.todo do
      summary      "Plan next vacations"
      description  "Let's have a break"
      percent      50
      seq          1
      add_category "TRAVEL"
      add_category "SPORTS"
    end

    calString = cal.to_ical

    assert_match(/PERCENT-COMPLETE:50/, calString)
    assert_match(/DESCRIPTION:Let's have a break/, calString)
    assert_match(/CATEGORIES:TRAVEL,SPORTS/, calString)
    assert_match(/SEQUENCE:1/, calString)

  end
end


