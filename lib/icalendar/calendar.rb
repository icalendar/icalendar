module Icalendar

  class Calendar < Component
    required_property :prodid
    required_property :version
    optional_single_property :calscale
    optional_single_property :method

    component :event
    component :todo
    component :journal
    component :freebusy
    component :timezone

    def initialize
      super 'vcalendar'
      self.prodid = 'icalendar-ruby'
      self.version = '2.0'
    end

    def event(event = nil, &block)
      add_component event || Component.new('event'), &block
    end

    def todo(todo = nil, &block)
      add_component todo || Component.new('todo'), &block
    end

    def journal(journal = nil, &block)
      add_component journal || Component.new('journal'), &block
    end

    def freebusy(freebusy = nil, &block)
      add_component freebusy || Component.new('freebusy'), &block
    end

    def timezone(timezone = nil, &block)
      add_component timezone || Component.new('timezone'), &block
    end
  end

end
