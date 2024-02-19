--------------- TOOLS ---------------

-- TABLE --

CREATE TABLE IF NOT EXISTS tools (
    -- ID
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- RELATIONSHIPS
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    process_state_id UUID REFERENCES process_states(id) ON DELETE CASCADE,

    -- METADATA
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP

    -- REQUIRED
    name TEXT NOT NULL,
    transition_state_name TEXT NOT NULL
);

-- INDEXES --

CREATE INDEX tools_id_idx ON tools(user_id);

-- RLS --

ALTER TABLE tools ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow full access to own tools"
    ON tools
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- TRIGGERS --

CREATE TRIGGER update_tools_updated_at
BEFORE UPDATE ON tools
FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();
