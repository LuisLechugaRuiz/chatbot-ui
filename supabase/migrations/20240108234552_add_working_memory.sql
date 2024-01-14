--------------- WORKING MEMORY ---------------

-- TABLE --

CREATE TABLE IF NOT EXISTS working_memory (
    -- ID
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- RELATIONSHIPS
    chat_id UUID NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- METADATA
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ,

    -- REQUIRED
    user_name TEXT NOT NULL CHECK (char_length(user_name) <= 100),
    context TEXT NOT NULL CHECK (char_length(context) <= 100000),
    thought TEXT NOT NULL CHECK (char_length(thought) <= 100000)
    --- TODO: ADD REQUESTS ----
);

-- INDEXES --

CREATE INDEX working_memory_user_id_idx ON working_memory(user_id);

-- RLS --

ALTER TABLE working_memory ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow full access to own memory"
    ON profiles
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- TRIGGERS --

CREATE TRIGGER update_working_memory_updated_at
BEFORE UPDATE ON working_memory
FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();