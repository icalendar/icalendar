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

    def to_ical
      [
        "BEGIN:#{ical_name}",
        ical_properties,
        ical_components,
        "END:#{ical_name}\r\n"
      ].compact.join "\r\n"
    end

    private

    def ical_properties
      (self.class.properties + custom_properties.keys).map do |prop|
        value = send prop
        unless value.nil?
          if value.is_a? ::Array
            value.map do |part|
              "#{ical_prop_name prop}#{part.to_ical}"
            end.join "\r\n" unless value.empty?
          else
            "#{ical_prop_name prop}#{value.to_ical}"
          end
        end
      end.compact.map do |property|
        split = property.split ''
        [].tap { |a| a << split.shift(Icalendar::MAX_LINE_LENGTH).join until split.empty? }.join "\r\n "
      end.join "\r\n"
    end

    def ical_prop_name(prop_name)
      prop_name.to_s.gsub(/\Aip_/, '').gsub('_', '-').upcase
    end

    def ical_components
      collection = []
      (self.class.components + custom_components.keys).each do |component_name|
        components = send component_name
        components.each do |component|
          collection << component.to_ical
        end
      end
      collection.empty? ? nil : collection.join.chomp("\r\n")
    end
  end

end
