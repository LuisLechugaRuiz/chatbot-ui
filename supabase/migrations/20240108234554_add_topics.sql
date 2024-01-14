--------------- TOPICS ---------------

-- TABLE --

CREATE TABLE IF NOT EXISTS topics (
    -- ID
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- RELATIONSHIPS
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- METADATA
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ,

    -- REQUIRED
    name TEXT NOT NULL CHECK (char_length(name) <= 100),
    content TEXT NOT NULL CHECK (char_length(content) <= 100000),
    description TEXT NOT NULL CHECK (char_length(description) <= 100000)
);

-- INDEXES --

CREATE INDEX topic_id_idx ON topics(user_id);

-- RLS --

ALTER TABLE topics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow full access to own topics"
    ON profiles
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- TRIGGERS -- TODO: VERIFY THIS OVERRIDES CURRENT VALUE

CREATE TRIGGER update_topic_updated_at
BEFORE UPDATE ON topics
FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();
