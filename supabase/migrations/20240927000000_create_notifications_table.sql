CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  type TEXT DEFAULT 'info',
  match_id TEXT REFERENCES matches(id) ON DELETE CASCADE,
  tournament_id TEXT REFERENCES tournaments(id) ON DELETE CASCADE,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add realtime replication
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;

-- Disable RLS for now to match other tables
ALTER TABLE notifications DISABLE ROW LEVEL SECURITY;