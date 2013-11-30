module Icalendar

  class Component
    include HasProperties
    include HasComponents

    attr_reader :name
    attr_reader :ical_name
    attr_accessor :parent

    def initialize(name, ical_name = nil)
      @name = name
      @ical_name = ical_name || "V#{name.upcase}"
      super()
    end

    def new_uid
      "#{DateTime.now}_#{rand(999999999)}@#{Socket.gethostname}"
    end

  end

end
