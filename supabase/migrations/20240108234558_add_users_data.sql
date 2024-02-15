--------------- USERS DATA ---------------

-- TABLE --

CREATE TABLE IF NOT EXISTS users_data (
    -- ID
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- RELATIONSHIPS
    user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,

    -- METADATA
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ,

    -- REQUIRED
    name TEXT NOT NULL CHECK (char_length(name) <= 100),
    api_key TEXT CHECK (char_length(api_key) <= 1000)
);

-- INDEXES --

CREATE INDEX idx_users_data_user_id ON profiles (user_id);

-- RLS --

ALTER TABLE users_data ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow full access to own user_data"
    ON users_data
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());