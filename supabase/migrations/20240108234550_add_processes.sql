--------------- PROCESSES ---------------

-- TABLE --

CREATE TABLE IF NOT EXISTS processes (
    -- ID
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- RELATIONSHIPS
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    agent_id UUID NOT NULL REFERENCES agents(id) ON DELETE CASCADE,

    -- METADATA
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ,

    -- REQUIRED
    name TEXT NOT NULL CHECK (char_length(name) <= 100),
    tools_class TEXT NOT NULL CHECK (char_length(tools_class) <= 100),
    is_active BOOLEAN NOT NULL DEFAULT FALSE,
);

-- INDEXES --

CREATE INDEX processes_id_idx ON processes(user_id);

-- RLS --

ALTER TABLE processes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow full access to own processes"
    ON profiles
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- TRIGGERS --

CREATE TRIGGER update_processes_updated_at
BEFORE UPDATE ON processes
FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();
