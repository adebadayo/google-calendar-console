require "google/apis/calendar_v3"
require "googleauth"
require "googleauth/stores/file_token_store"
require "date"
require "fileutils"

OOB_URI = "urn:ietf:wg:oauth:2.0:oob".freeze
APPLICATION_NAME = "Google Calendar API Ruby Quickstart".freeze
CREDENTIALS_PATH = "credentials.json".freeze
# The file token.yaml stores the user's access and refresh tokens, and is
# created automatically when the authorization flow completes for the first
# time.
TOKEN_PATH = "token.yaml".freeze
SCOPE = Google::Apis::CalendarV3::AUTH_CALENDAR_READONLY

##
# Ensure valid credentials, either by restoring from the saved credentials
# files or intitiating an OAuth2 authorization. If authorization is required,
# the user's default browser will be launched to approve the request.
#
# @return [Google::Auth::UserRefreshCredentials] OAuth2 credentials
def authorize
  client_id = Google::Auth::ClientId.from_file CREDENTIALS_PATH
  token_store = Google::Auth::Stores::FileTokenStore.new file: TOKEN_PATH
  authorizer = Google::Auth::UserAuthorizer.new client_id, SCOPE, token_store
  user_id = "default"
  credentials = authorizer.get_credentials user_id
  if credentials.nil?
    url = authorizer.get_authorization_url base_url: OOB_URI
    puts "Open the following URL in the browser and enter the " \
         "resulting code after authorization:\n" + url
    code = gets
    credentials = authorizer.get_and_store_credentials_from_code(
      user_id: user_id, code: code, base_url: OOB_URI
    )
  end
  credentials
end

# Initialize the API
service = Google::Apis::CalendarV3::CalendarService.new
service.client_options.application_name = APPLICATION_NAME
service.authorization = authorize

# Fetch the next 10 events for the user
calendar_id = "primary"
response = service.list_events(calendar_id,
                               max_results:   10,
                               single_events: true,
                               order_by:      "startTime",
                               time_min:      DateTime.now.rfc3339)
puts "Upcoming events:"
puts "No upcoming events found" if response.items.empty?
response.items.each do |event|
  start = event.start.date || event.start.date_time
  puts "- #{event.summary} (#{start})"
end


require 'dotenv'
Dotenv.load

require 'byebug'


# 1週間先まで空き時間を検索
start_date = Date.today
end_date = start_date.next_day(7)

item = Google::Apis::CalendarV3::FreeBusyRequestItem.new(id: ENV['CALENDAR_ID'])
free_busy_request = Google::Apis::CalendarV3::FreeBusyRequest.new(
  calendar_expansion_max: 50,
  time_min: DateTime.new(start_date.year, start_date.month, start_date.day, 00, 0, 0),
  time_max: DateTime.new(end_date.year, end_date.month, end_date.day, 00, 0, 0),
  items: [item],
  time_zone: "UTC+9"
)

response = service.query_freebusy(free_busy_request)
calendars = response.calendars
busy_list = calendars[ENV['CALENDAR_ID']].busy

# 空き時間を検索する時間の範囲
start_hour = 9
end_hour = 20

puts "Free time:"

(start_date..end_date).each do |date|
  puts "-----#{date.strftime("%Y/%m/%d")}-----"

  start_work_time = Time.new(date.year, date.month, date.day, start_hour, 0, 0)
  end_work_time = Time.new(date.year, date.month, date.day, end_hour, 0, 0)

  start_work_time.to_i.step(end_work_time.to_i, 60*60).map do |t|
    time = Time.at(t)
    is_busy = false
    busy_list.each do |busy|
      busy_start = busy.start
      end_start = busy.end

      if busy_start <= time.to_datetime && time.to_datetime < end_start
        is_busy = true
        break
      end
    end

    unless is_busy
      puts time.strftime("%Y/%m/%d %H:%M")
    end
  end
end


