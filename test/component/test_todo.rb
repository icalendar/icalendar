$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

class TestTodo < Test::Unit::TestCase

  def setup
    @cal = Icalendar::Calendar.new
    @todo = Icalendar::Todo.new
  end

  def test_new
    assert(@todo)
  end
end
