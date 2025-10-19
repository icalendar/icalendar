# frozen_string_literal: true

require 'delegate'

module Icalendar
  class DowncasedHash

    def initialize(base)
      @obj = Hash.new
      base.each do |key, value|
        self[key] = value
      end
    end

    def []=(key, value)
      obj[key.to_s.downcase] = value
    end

    def [](key)
      obj[key.to_s.downcase]
    end

    def has_key?(key)
      obj.has_key? key.to_s.downcase
    end
    alias_method :include?, :has_key?
    alias_method :member?, :has_key?

    def delete(key, &block)
      obj.delete key.to_s.downcase, &block
    end

    def merge(*other_hashes)
      Icalendar::DowncasedHash.new(obj).merge!(*other_hashes)
    end

    def merge!(*other_hashes)
      other_hashes.each do |hash|
        hash.each do |key, value|
          self[key] = value
        end
      end
      self
    end

    def empty?
      obj.empty?
    end

    def each(&block)
      obj.each &block
    end

    def map(&block)
      obj.map &block
    end

    def ==(other)
      obj == Icalendar::DowncasedHash(other).obj
    end

    protected

    attr_reader :obj
  end

  def self.DowncasedHash(base)
    case base
    when Icalendar::DowncasedHash then base
    when Hash then Icalendar::DowncasedHash.new(base)
    else
      fail ArgumentError
    end
  end
end
