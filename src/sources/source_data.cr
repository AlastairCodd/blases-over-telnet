require "json"

class SourceData
  property temporal : Hash(String, JSON::Any)? = nil
  property games : Array(JSON::Any)? = nil
  property past_games : Array(JSON::Any)? = nil
  property teams : Hash(String, JSON::Any)? = nil
  property sim : Hash(String, JSON::Any)? = nil

  def initialize
  end

  def initialize(value : JSON::Any)
    from_stream value
  end

  def from_stream(value : JSON::Any)
    @temporal = value["temporal"]?.try &.as_h?
    value["games"]?.try do |games_data|
      @sim = games_data["sim"]?.try &.as_h?
      @games = games_data["schedule"]?.try &.as_a?
    end
  end
end

def get_top_of_next_hour(time : Time) : Time
  result = Time.utc(time.year, time.month, time.day, time.hour, 0, 0)
  result += Time::Span.new(hours: 1)
  return result
end

def get_time(start_time : JSON::Any, end_time : JSON::Any) : Time::Span
  start_time_string = start_time.as_s?
  if !start_time_string.nil?
    start_value = Time::Format::ISO_8601_DATE_TIME.parse(start_time_string)
    end_time_string = end_time.as_s?
    if end_time_string.nil?
      return Time.utc - start_value
    else
      return Time::Format::ISO_8601_DATE_TIME.parse(end_time_string) - start_value
    end
  else
    return Time::Span.new
  end
end
