require 'delegate'

module Icalendar

  class Value < ::SimpleDelegator

    attr_accessor :ical_params, :include_value_param

    def initialize(value, params = {}, include_value_param = false)
      @ical_params = params.dup
      @include_value_param = include_value_param
      super value
    end

    def ical_param(key, value)
      @ical_params[key] = value
    end

    def value
      __getobj__
    end

    # TODO ensure EVERYTHING is properly escaped
    def to_ical
      "#{params_ical}:#{value_ical}"
    end

    def params_ical
      ical_param 'value', self.class.value_type if include_value_param
      unless ical_params.empty?
        ";#{ical_params.map { |name, value| param_ical name, value }.join ';'}"
      end
    end

    def self.value_type
      name.gsub(/\A.*::/, '').gsub(/(?<!\A)[A-Z]/, '-\0').upcase
    end

    private

    def param_ical(name, value)
      if value.is_a? Array
        value = value.map { |v| escape_param_value v }.join ','
      else
        value = escape_param_value value
      end
      "#{name.to_s.gsub('_', '-').upcase}=#{value}"
    end

    def escape_param_value(value)
      v = value.gsub '"', "'"
      v =~ /[;:,]/ ? %("#{v}") : v
    end

  end

end

# helper; not actual iCalendar value type
require_relative 'values/array'

# iCalendar value types
require_relative 'values/binary'
require_relative 'values/boolean'
require_relative 'values/date'
require_relative 'values/date_time'
require_relative 'values/duration'
require_relative 'values/float'
require_relative 'values/integer'
require_relative 'values/period'
require_relative 'values/recur'
require_relative 'values/text'
require_relative 'values/time'
require_relative 'values/uri'
require_relative 'values/utc_offset'

# further refine above classes
require_relative 'values/cal_address'