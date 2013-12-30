require 'delegate'

module Icalendar

  class Value < ::SimpleDelegator

    attr_accessor :ical_params

    def initialize(value, params = {})
      @ical_params = params.dup
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
      unless ical_params.empty?
        ";#{ical_params.map { |name, value| "#{name.to_s.gsub('_', '-').upcase}=#{value}" }.join ';'}"
      end
    end

  end

end

require_relative 'values/array'
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