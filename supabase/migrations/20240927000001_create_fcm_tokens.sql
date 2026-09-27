CREATE TABLE fcm_tokens (
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  token TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (user_id, token)
);

ALTER TABLE fcm_tokens DISABLE ROW LEVEL SECURITY;