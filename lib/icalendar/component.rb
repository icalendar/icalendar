module Icalendar

  class Component
    include Properties
    include Components

    attr_reader :name
    attr_accessor :parent

    def initialize(name)
      @name = name
      super()
    end

  end

end
