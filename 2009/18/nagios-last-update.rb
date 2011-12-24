#!/usr/bin/env ruby
# Author: Jordan Sissel
# License: BSD
#
# Usage:
# nagios-last-update.rb <nagioshost[:port]> <maxage>
#   nagioshost should be the web server in front of nagios
#   maxage is a value in seconds.
#

require 'rubygems'
require 'mechanize'
require 'date'

HTTP_TIMEOUT = 30

def warn(message)
  puts message
  exit 1
end

def critical(message)
  puts message
  exit 2
end

def main(args)
  nagioshost = args[0]
  maxage = args[1].to_f

  mech = WWW::Mechanize.new
  url = "http://#{nagioshost}/nagios/cgi-bin/extinfo.cgi?type=0"
  page = nil
  begin
    Timeout.timeout(HTTP_TIMEOUT) do
      page = mech.get(url)
    end
  rescue Errno::ECONNREFUSED
    critical "Connection refused when fetching #{url}"
  rescue Timeout::Error
    critical "Timeout (#{HTTP_TIMEOUT}) while fetching #{url}"
  end

  # find the row like this:
  # <TR><TD CLASS='dataVar'>Last External Command Check:</TD>
  #     <TD CLASS='dataVal'>12-18-2009 03:47:22</TD></TR>
  # And get that 2nd column.
  rowtext = "Last External Command Check:"
  xpath = "//tr[contains(td/text(), '#{rowtext}')]/td[@class='dataVal']/text()"
  last_update_str = page.search(xpath).to_s
  case last_update_str
  when ""
    critical "extinfo.cgi returned bad data. Nagios is probably down?"
  when "N/A"
    warn "last external command time is 'N/A'. Nagios may have just restarted."
  end

  now = Time.now
  last_update_time = Time.parse(DateTime.strptime(last_update_str,
                                                  "%m-%d-%Y %H:%M:%S").to_s)

  # Since the time reported by nagios doesn't include a zone, and parsing it
  # defaults to GMT, add local timezone offset.
  last_update_time -= now.gmt_offset

  # Require last check run to be less than 15 minutes ago.
  age = now - last_update_time
  if age > maxage
    critical "Time of last Nagios check is older than #{maxage} seconds: #{age}"
  end

  puts "OK. Nagios last-update #{age} seconds ago."
  return 0
end

exit(main(ARGV))
