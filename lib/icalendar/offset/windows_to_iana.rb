# frozen_string_literal: true

# This module contains mappings from Windows timezone identifiers to Olson timezone identifiers.
#
# The data is taken from the unicode consortium [0], the proposal and rationale
# for this mapping is also available at the unicode consortium [1].
#
# [0] https://www.unicode.org/cldr/cldr-aux/charts/29/supplemental/zone_tzid.html
# [1] https://cldr.unicode.org/development/development-process/design-proposals/extended-windows-olson-zid-mapping

module Icalendar
  class Offset
    class WindowsToIana < Offset
      WINDOWS_TO_IANA = {
        'AUS Central Standard Time' => 'Australia/Darwin',
        'AUS Eastern Standard Time' => 'Australia/Sydney',
        'Afghanistan Standard Time' => 'Asia/Kabul',
        'Alaskan Standard Time' => 'America/Anchorage',
        'Arab Standard Time' => 'Asia/Riyadh',
        'Arabian Standard Time' => 'Asia/Dubai',
        'Arabic Standard Time' => 'Asia/Baghdad',
        'Argentina Standard Time' => 'America/Argentina/Buenos_Aires',
        'Atlantic Standard Time' => 'America/Halifax',
        'Azerbaijan Standard Time' => 'Asia/Baku',
        'Azores Standard Time' => 'Atlantic/Azores',
        'Bahia Standard Time' => 'America/Bahia',
        'Bangladesh Standard Time' => 'Asia/Dhaka',
        'Belarus Standard Time' => 'Europe/Minsk',
        'Canada Central Standard Time' => 'America/Regina',
        'Cape Verde Standard Time' => 'Atlantic/Cape_Verde',
        'Caucasus Standard Time' => 'Asia/Yerevan',
        'Cen. Australia Standard Time' => 'Australia/Adelaide',
        'Central America Standard Time' => 'America/Guatemala',
        'Central Asia Standard Time' => 'Asia/Almaty',
        'Central Brazilian Standard Time' => 'America/Cuiaba',
        'Central Europe Standard Time' => 'Europe/Budapest',
        'Central European Standard Time' => 'Europe/Warsaw',
        'Central Pacific Standard Time' => 'Pacific/Guadalcanal',
        'Central Standard Time' => 'America/Chicago',
        'Central Standard Time (Mexico)' => 'America/Mexico_City',
        'China Standard Time' => 'Asia/Shanghai',
        'Dateline Standard Time' => 'Etc/GMT+12',
        'E. Africa Standard Time' => 'Africa/Nairobi',
        'E. Australia Standard Time' => 'Australia/Brisbane',
        'E. Europe Standard Time' => 'Europe/Chisinau',
        'E. South America Standard Time' => 'America/Sao_Paulo',
        'Eastern Standard Time' => 'America/New_York',
        'Eastern Standard Time (Mexico)' => 'America/Cancun',
        'Egypt Standard Time' => 'Africa/Cairo',
        'Ekaterinburg Standard Time' => 'Asia/Yekaterinburg',
        'FLE Standard Time' => 'Europe/Kyiv',
        'Fiji Standard Time' => 'Pacific/Fiji',
        'GMT Standard Time' => 'Europe/London',
        'GTB Standard Time' => 'Europe/Bucharest',
        'Georgian Standard Time' => 'Asia/Tbilisi',
        'Greenland Standard Time' => 'America/Nuuk',
        'Greenwich Standard Time' => 'Atlantic/Reykjavik',
        'Hawaiian Standard Time' => 'Pacific/Honolulu',
        'India Standard Time' => 'Asia/Kolkata',
        'Iran Standard Time' => 'Asia/Tehran',
        'Israel Standard Time' => 'Asia/Jerusalem',
        'Jordan Standard Time' => 'Asia/Amman',
        'Kaliningrad Standard Time' => 'Europe/Kaliningrad',
        'Korea Standard Time' => 'Asia/Seoul',
        'Libya Standard Time' => 'Africa/Tripoli',
        'Line Islands Standard Time' => 'Pacific/Kiritimati',
        'Magadan Standard Time' => 'Asia/Magadan',
        'Mauritius Standard Time' => 'Indian/Mauritius',
        'Middle East Standard Time' => 'Asia/Beirut',
        'Montevideo Standard Time' => 'America/Montevideo',
        'Morocco Standard Time' => 'Africa/Casablanca',
        'Mountain Standard Time' => 'America/Denver',
        'Mountain Standard Time (Mexico)' => 'America/Chihuahua',
        'Myanmar Standard Time' => 'Asia/Yangon',
        'N. Central Asia Standard Time' => 'Asia/Novosibirsk',
        'Namibia Standard Time' => 'Africa/Windhoek',
        'Nepal Standard Time' => 'Asia/Kathmandu',
        'New Zealand Standard Time' => 'Pacific/Auckland',
        'Newfoundland Standard Time' => 'America/St_Johns',
        'North Asia East Standard Time' => 'Asia/Irkutsk',
        'North Asia Standard Time' => 'Asia/Krasnoyarsk',
        'North Korea Standard Time' => 'Asia/Pyongyang',
        'Pacific SA Standard Time' => 'America/Santiago',
        'Pacific Standard Time' => 'America/Los_Angeles',
        'Pakistan Standard Time' => 'Asia/Karachi',
        'Paraguay Standard Time' => 'America/Asuncion',
        'Romance Standard Time' => 'Europe/Paris',
        'Russia Time Zone 10' => 'Asia/Srednekolymsk',
        'Russia Time Zone 11' => 'Asia/Kamchatka',
        'Russia Time Zone 3' => 'Europe/Samara',
        'Russian Standard Time' => 'Europe/Moscow',
        'SA Eastern Standard Time' => 'America/Cayenne',
        'SA Pacific Standard Time' => 'America/Bogota',
        'SA Western Standard Time' => 'America/La_Paz',
        'SE Asia Standard Time' => 'Asia/Bangkok',
        'Samoa Standard Time' => 'Pacific/Apia',
        'Singapore Standard Time' => 'Asia/Singapore',
        'South Africa Standard Time' => 'Africa/Johannesburg',
        'Sri Lanka Standard Time' => 'Asia/Colombo',
        'Syria Standard Time' => 'Asia/Damascus',
        'Taipei Standard Time' => 'Asia/Taipei',
        'Tasmania Standard Time' => 'Australia/Hobart',
        'Tokyo Standard Time' => 'Asia/Tokyo',
        'Tonga Standard Time' => 'Pacific/Tongatapu',
        'Turkey Standard Time' => 'Europe/Istanbul',
        'US Eastern Standard Time' => 'America/Indiana/Indianapolis',
        'US Mountain Standard Time' => 'America/Phoenix',
        'UTC' => 'Etc/GMT',
        'UTC+12' => 'Etc/GMT-12',
        'UTC-02' => 'Etc/GMT+2',
        'UTC-11' => 'Etc/GMT+11',
        'Ulaanbaatar Standard Time' => 'Asia/Ulaanbaatar',
        'Venezuela Standard Time' => 'America/Caracas',
        'Vladivostok Standard Time' => 'Asia/Vladivostok',
        'W. Australia Standard Time' => 'Australia/Perth',
        'W. Central Africa Standard Time' => 'Africa/Lagos',
        'W. Europe Standard Time' => 'Europe/Berlin',
        'West Asia Standard Time' => 'Asia/Tashkent',
        'West Pacific Standard Time' => 'Pacific/Port_Moresby',
        'Yakutsk Standard Time' => 'Asia/Yakutsk'
      }.freeze

      def valid?
        support_classes_defined? && tz
      end

      def normalized_value
        Icalendar.logger.debug("Plan a - parsing #{value}/#{tzid} as ActiveSupport::TimeWithZone")
        # plan a - use ActiveSupport::TimeWithZone
        Icalendar::Values::Helpers::ActiveSupportTimeWithZoneAdapter.new(nil, tz, value)
      end

      def normalized_tzid
        [WINDOWS_TO_IANA[tzid]].compact
      end

      private

      def tz
        @tz ||= ActiveSupport::TimeZone[normalized_tzid.first || '']
      end
    end
  end
end
