-- Create custom enums for statuses
CREATE TYPE user_role AS ENUM ('admin', 'organizer', 'scorer', 'member');
CREATE TYPE tournament_status AS ENUM ('upcoming', 'ongoing', 'completed');
CREATE TYPE tournament_format AS ENUM ('t20', 'odi', 'test', 't10', 'custom');
CREATE TYPE match_status AS ENUM ('scheduled', 'live', 'completed', 'abandoned');
CREATE TYPE toss_decision AS ENUM ('bat', 'bowl');
CREATE TYPE player_role AS ENUM ('batsman', 'bowler', 'allRounder', 'wicketKeeper');
CREATE TYPE batting_style AS ENUM ('rightHanded', 'leftHanded');
CREATE TYPE bowling_style AS ENUM ('rightArmFast', 'rightArmMedium', 'rightArmSpin', 'leftArmFast', 'leftArmMedium', 'leftArmSpin');

-- Users / Profiles Table (links to Supabase auth.users)
CREATE TABLE profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  email TEXT NOT NULL,
  display_name TEXT,
  role user_role DEFAULT 'member',
  photo_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tournaments Table
CREATE TABLE tournaments (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  status TEXT DEFAULT 'upcoming',
  format TEXT DEFAULT 't20',
  organizer_id UUID REFERENCES profiles(id),
  start_date TIMESTAMPTZ NOT NULL,
  end_date TIMESTAMPTZ,
  venue TEXT,
  teams_count INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Teams Table
CREATE TABLE teams (
  id TEXT PRIMARY KEY,
  tournament_ids TEXT[],
  name TEXT NOT NULL,
  short_name TEXT NOT NULL,
  logo_url TEXT,
  captain_id TEXT, -- Note: player id might be string, defined later
  points INT DEFAULT 0,
  matches_played INT DEFAULT 0,
  won INT DEFAULT 0,
  lost INT DEFAULT 0,
  tied INT DEFAULT 0,
  net_run_rate FLOAT DEFAULT 0.0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Players Table
CREATE TABLE players (
  id TEXT PRIMARY KEY,
  team_id TEXT REFERENCES teams(id) ON DELETE CASCADE,
  tournament_id TEXT REFERENCES tournaments(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  role TEXT DEFAULT 'batsman',
  batting_style TEXT DEFAULT 'rightHanded',
  bowling_style TEXT DEFAULT 'rightArmFast',
  matches_played INT DEFAULT 0,
  runs_scored INT DEFAULT 0,
  balls_faced INT DEFAULT 0,
  fifties INT DEFAULT 0,
  hundreds INT DEFAULT 0,
  fours INT DEFAULT 0,
  sixes INT DEFAULT 0,
  highest_score INT DEFAULT 0,
  wickets INT DEFAULT 0,
  balls_bowled INT DEFAULT 0,
  runs_conceded INT DEFAULT 0,
  maidens INT DEFAULT 0,
  five_wicket_hauls INT DEFAULT 0,
  best_bowling_wickets INT DEFAULT 0,
  best_bowling_runs INT DEFAULT 0,
  catches INT DEFAULT 0,
  run_outs INT DEFAULT 0,
  stumpings INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Alter team captain fk now that players exist
ALTER TABLE teams ADD CONSTRAINT fk_teams_captain FOREIGN KEY (captain_id) REFERENCES players(id) ON DELETE SET NULL;

-- Matches Table
CREATE TABLE matches (
  id TEXT PRIMARY KEY,
  tournament_id TEXT REFERENCES tournaments(id) ON DELETE CASCADE,
  team_a_id TEXT REFERENCES teams(id),
  team_b_id TEXT REFERENCES teams(id),
  team_a TEXT NOT NULL,
  team_b TEXT NOT NULL,
  status TEXT DEFAULT 'scheduled',
  match_date TIMESTAMPTZ NOT NULL,
  venue TEXT,
  total_overs INT DEFAULT 20,
  match_number INT,
  toss_winner_id TEXT REFERENCES teams(id),
  toss_decision TEXT,
  winner_team_id TEXT REFERENCES teams(id),
  result_text TEXT,
  is_tie BOOLEAN DEFAULT false,
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  man_of_the_match_id TEXT REFERENCES players(id),
  man_of_the_match_name TEXT,
  live_score JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Innings Table
CREATE TABLE innings (
  id TEXT PRIMARY KEY,
  match_id TEXT REFERENCES matches(id) ON DELETE CASCADE,
  tournament_id TEXT REFERENCES tournaments(id) ON DELETE CASCADE,
  innings_number INT NOT NULL,
  batting_team_id TEXT REFERENCES teams(id),
  bowling_team_id TEXT REFERENCES teams(id),
  runs INT DEFAULT 0,
  wickets INT DEFAULT 0,
  legal_balls INT DEFAULT 0,
  target_runs INT,
  extras_wides INT DEFAULT 0,
  extras_no_balls INT DEFAULT 0,
  extras_byes INT DEFAULT 0,
  extras_leg_byes INT DEFAULT 0,
  extras_penalty INT DEFAULT 0,
  current_striker_id TEXT REFERENCES players(id),
  current_non_striker_id TEXT REFERENCES players(id),
  current_bowler_id TEXT REFERENCES players(id),
  is_complete BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Ball Events Table
CREATE TABLE ball_events (
  id TEXT PRIMARY KEY,
  match_id TEXT REFERENCES matches(id) ON DELETE CASCADE,
  innings_id TEXT REFERENCES innings(id) ON DELETE CASCADE,
  over_number INT NOT NULL,
  ball_number INT NOT NULL,
  bowler_id TEXT REFERENCES players(id),
  batter_id TEXT REFERENCES players(id),
  non_striker_id TEXT REFERENCES players(id),
  runs_scored INT DEFAULT 0,
  extras_type TEXT,
  extras_runs INT DEFAULT 0,
  wicket_type TEXT,
  player_out_id TEXT REFERENCES players(id),
  fielder_id TEXT REFERENCES players(id),
  is_legal_ball BOOLEAN DEFAULT true,
  is_boundary BOOLEAN DEFAULT false,
  ball_time TIMESTAMPTZ DEFAULT NOW()
);

-- Realtime replication setup
BEGIN;
  DROP PUBLICATION IF EXISTS supabase_realtime;
  CREATE PUBLICATION supabase_realtime;
COMMIT;
ALTER PUBLICATION supabase_realtime ADD TABLE profiles, tournaments, teams, players, matches, innings, ball_events;

-- Disable RLS for now to allow seamless transition (can be enabled later)
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE tournaments DISABLE ROW LEVEL SECURITY;
ALTER TABLE teams DISABLE ROW LEVEL SECURITY;
ALTER TABLE players DISABLE ROW LEVEL SECURITY;
ALTER TABLE matches DISABLE ROW LEVEL SECURITY;
ALTER TABLE innings DISABLE ROW LEVEL SECURITY;
ALTER TABLE ball_events DISABLE ROW LEVEL SECURITY;
