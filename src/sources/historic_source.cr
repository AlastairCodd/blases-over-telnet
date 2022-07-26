class ChroniclerSource < Source
  property tx : Channel({String, SourceData})
  property ident : String
  property clients : Int32 = 0
  property current_data : SourceData
  property running : Bool = false

  property current_time : Time

  property current_sim : Hash(String, JSON::Any)? = nil

  property historic_sims : Array(Hash(String, JSON::Any))? = nil

  def initialize(
    start_time : Time,
    @ident : String,
    @tx : Channel({String, SourceData})
  )
    @current_time = start_time
    @current_data = SourceData.new

    start
  end

  def add_client
    @clients += 1
  end

  def rm_client
    @clients -= 1
  end

  def n_clients
    @clients
  end

  def start
    if @running
      return
    end

    current_sim = get_sim
    if current_sim.nil?
      Log.error { "failed to get historic data" }
      return
    end
    current_sim = current_sim.not_nil!
    @current_data.sim = current_sim

    @current_data.teams = get_teams
    
    all_games = get_all_games new_sim["season"].as_i, new_sim["id"].as_s
    if !all_games.nil?
      Log.trace { "past game data fetched" }
      @current_data.past_games = all_games
    else
      Log.error { "failed to get games" }
    end

    spawn do
      while @running
        
      end
    end
  end

  def close
    @running = false
  end

  def get_sim : Hash(String, JSON::Any)?
    if @current_sim.nil? || @current_sim.not_nil!["valid_to"] > @current_time
      if @historic_sims.nil? || @historic_sims.count == 0
        fetched_historic_sims = get_chron_versions("sim", @current_time)
        if fetched_historic_sims.count == 0
          Log.error { "requested sim data but got nothing back" }
          @historic_sims = nil
          return nil
        end
        @historic_sims = fetched_historic_sims
      end
      @current_sim = @historic_sims.not_nil!.shift
    end
    @current_sim
  end

  def get_teams : Hash(String, JSON::Any)?
    if @current_teams.nil? || @current_teams.not_nil!["valid_to"] > @current_time
      if @historic_teams.nil? || @historic_teams.count == 0
        fetched_historic_teams = get_chron_versions("team", @current_time)
        if fetched_historic_teams.count == 0
          Log.error { "requested team data but got nothing back" }
          @historic_teams = nil
          return nil
        end
        @historic_teams = fetched_historic_teams
      end
      @current_teams = @historic_teams.not_nil!.shift
    end
    @current_teams
  end

  def get_chron_versions(entity_type : String, from_time : Time) : Array(JSON::Any)?
    url = URI.parse(ENV["CHRON_API_URL"])
    url.query = URI::Params.encode({
      "type"  => entity_type,
      "after" => Time::Format::ISO_8601_DATE_TIME.format(from_time),
    })
    url.path = (Path.new(url.path) / "v2" / "versions").to_s

    begin
      response = HTTP::Client.get url
      if response.success?
        messages = JSON.parse response.body
        return messages["items"].as_a
      else
        Log.error { "http request failed" }
        Log.error { url }
        Log.error { response.status_code }
        return
      end
    rescue ex
      Log.error(exception: ex) { }
      return
    end
  end

  def last_data : SourceData
    @current_data
  end
end
