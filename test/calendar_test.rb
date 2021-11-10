require 'minitest/autorun'
require_relative '../src/calendar'

class CalendarTest < Minitest::Test
  def setup
    @calendar = Calendar.new
  end

  def test_calendar_list
    @calendar.list
  end
end
