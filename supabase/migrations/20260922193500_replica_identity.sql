-- Enable REPLICA IDENTITY FULL to allow Supabase Realtime to broadcast old data on deletes.
-- This fixes the issue where deleting a row in the app doesn't reflect in the realtime stream.

ALTER TABLE matches REPLICA IDENTITY FULL;
ALTER TABLE players REPLICA IDENTITY FULL;
ALTER TABLE teams REPLICA IDENTITY FULL;
ALTER TABLE tournaments REPLICA IDENTITY FULL;
