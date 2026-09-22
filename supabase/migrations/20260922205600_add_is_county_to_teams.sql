-- Add is_county column to teams table
ALTER TABLE teams ADD COLUMN is_county BOOLEAN DEFAULT false;

-- Update existing dummy county teams
-- We identify them by checking if they are part of a match where live_score->>'isCounty' is 'true'
UPDATE teams
SET is_county = true
WHERE id IN (
  SELECT team_a_id 
  FROM matches 
  WHERE live_score->>'isCounty' = 'true'
  
  UNION
  
  SELECT team_b_id 
  FROM matches 
  WHERE live_score->>'isCounty' = 'true'
);
