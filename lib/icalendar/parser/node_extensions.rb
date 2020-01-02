require 'treetop'

module Ics
  class Component < Treetop::Runtime::SyntaxNode
    def body
      componentbody
    end

    def properties
      body.properties
    end

    def components
      body.components
    end
  end

  class CalendarComponent < Component
    def component
      @component ||= Icalendar::Calendar.new
    end

    def body
      calbody
    end
  end

  class EventComponent < Component
    def component
      @component ||= Icalendar::Event.new
    end

    def body
      eventbody
    end
  end

  class TodoComponent < Component
    def component
      @component ||= Icalendar::Todo.new
    end

    def body
      todobody
    end
  end

  class JournalComponent < Component
    def component
      @component ||= Icalendar::Journal.new
    end
  end

  class FreeBusyComponent < Component
    def component
      @component ||= Icalendar::Freebusy.new
    end
  end

  class TimezoneComponent < Component
    def component
      @component ||= Icalendar::Timezone.new
    end

    def body
      timezonebody
    end
  end

  class DaylightComponent < Component
    def component
      @component ||= Icalendar::Timezone::Daylight.new
    end
  end

  class StandardComponent < Component
    def component
      @component ||= Icalendar::Timezone::Standard.new
    end
  end

  class IanaComponent < Component
    def component
      @component ||= Icalendar::Component.new(ianatoken.text_value, ianatoken.text_value)
    end
  end

  class CustomComponent < Component
    def component
      @component ||= Icalendar::Component.new(xname.text_value, xname.text_value)
    end
  end

  class ComponentBody < Treetop::Runtime::SyntaxNode
    def properties
      elements.select { |e| e.is_a?(PropertyLine) }
    end

    def components
      elements.select { |e| !e.is_a?(PropertyLine) }
    end
  end

  class AlarmComponent < Component
    def component
      @component ||= Icalendar::Alarm.new
    end
  end

  class PropertyLine < Treetop::Runtime::SyntaxNode
    def property_name
      name.text_value.downcase.gsub('-', '_')
    end

    def property_value
      if elements[3].empty?
        ""
      else
        elements[3].value.text_value
      end
    end

    def property_params
      @property_params ||= params.map { |p| [p.param_name, p.param_value] }.to_h
    end

    def params
      elements[1].elements.map(&:param)
    end
  end

  class PropertyParam < Treetop::Runtime::SyntaxNode
    def param_name
      paramname.text_value.downcase
    end

    def param_value
      [paramvalue.value, *othervalues]
    end

    def othervalues
      elements[3].elements.map(&:paramvalue).map(&:value)
    end
  end

  class ParamText < Treetop::Runtime::SyntaxNode
    def value
      text_value
    end
  end

  class QuotedString < Treetop::Runtime::SyntaxNode
    def value
      elements[1].text_value
    end
  end
end
