require "../client.cr"
require "./base.cr"
require "../components/graph.cr"

class StandingsAction < Action
  getter aliases : Set(String) = Set{"standings"}

  def invoke(
    client : Client,
    tx : Channel({String, SourceData}),
    sources : Hash(String, Source),
    line : String
  ) : Nil
    client.writeable = false
    teams_in_season : Hash(String, Array(Int32)) = (client
      .last_source_data
      .not_nil!
      .past_games
      .not_nil!
      .select { |game| game["data"]["finalized"].as_bool }
      .flat_map do |game_wrapper|
        game = game_wrapper["data"]
        away_team_id = game["awayTeam"].as_s
        home_team_id = game["homeTeam"].as_s
        away_score = (game["awayScore"].as_f? || game["awayScore"].as_i?).not_nil!
        home_score = (game["homeScore"].as_f? || game["homeScore"].as_i?).not_nil!

        away_team_win_inc = away_score > home_score ? 1 : -1
        [{away_team_id, away_team_win_inc},
         {home_team_id, -away_team_win_inc}]
      end)
      .group_by { |entry| entry[0] }
      .transform_values do |days|
        days
          .map { |day| day[1] }
          .accumulate { |running_count, win| running_count + win }
      end
    teams_in_season.each do |team_id, team_standings|
      color = client.colorizer.get_colour_for_team team_id

      if !color.nil?
        client.socket << client.last_source_data.not_nil!.teams.not_nil![team_id]["fullName"].colorize.fore(color.not_nil!)
        client.socket << "\r\n"
        client.socket << render_graph(team_standings).colorize.fore(color.not_nil!)
        client.socket << "\r\n"
      end
    end

    client.socket << "\r\ntype resume to return to games\r\n"
  end
end

class RunDifferentialAction < Action
  getter aliases : Set(String) = Set{"runs"}

  def invoke(
    client : Client,
    tx : Channel({String, SourceData}),
    sources : Hash(String, Source),
    line : String
  ) : Nil
    client.writeable = false
    teams_in_season : Hash(String, Array(Float64)) = (client
      .last_source_data
      .not_nil!
      .past_games
      .not_nil!
      .select { |game| game["data"]["finalized"].as_bool }
      .flat_map do |game_wrapper|
        game = game_wrapper["data"]
        away_team_id = game["awayTeam"].as_s
        home_team_id = game["homeTeam"].as_s
        away_score = (game["awayScore"].as_f? || game["awayScore"].as_i?).not_nil!
        home_score = (game["homeScore"].as_f? || game["homeScore"].as_i?).not_nil!

        away_run_differential = (away_score - home_score).to_f

        [{away_team_id, away_run_differential},
         {home_team_id, -away_run_differential}]
      end)
      .group_by { |entry| entry[0] }
      .transform_values do |days|
        days
          .map { |day| day[1] }
          .accumulate { |running_count, win| running_count + win }
      end
    teams_in_season.each do |team_id, team_standings|
      color = client.colorizer.get_colour_for_team team_id

      if !color.nil?
        client.socket << client.last_source_data.not_nil!.teams.not_nil![team_id]["fullName"].colorize.fore(color.not_nil!)
        client.socket << "\r\n"
        client.socket << render_graph(team_standings).colorize.fore(color.not_nil!)
        client.socket << "\r\n"
      end
    end

    client.socket << "\r\ntype resume to return to games\r\n"
  end
end
