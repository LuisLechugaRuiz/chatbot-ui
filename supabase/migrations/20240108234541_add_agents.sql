--------------- AGENTS ---------------

-- TABLE --

CREATE TABLE IF NOT EXISTS agents (
    -- ID
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- RELATIONSHIPS
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- METADATA
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ,

    -- REQUIRED
    name TEXT NOT NULL CHECK (char_length(name) <= 100),
    tools_class TEXT NOT NULL CHECK (char_length(tools_class) <= 100),
    identity TEXT NOT NULL CHECK (char_length(identity) <= 10000),
    task TEXT NOT NULL CHECK (char_length(task) <= 10000),
    instructions TEXT NOT NULL CHECK (char_length(instructions) <= 100000),
    state TEXT NOT NULL DEFAULT 'idle'::text CHECK (state = ANY (ARRAY['idle'::text, 'main_process'::text, 'thought_generator'::text])),
    thought_generator_mode TEXT NOT NULL DEFAULT 'post'::text CHECK (thought_generator_mode = ANY (ARRAY['pre'::text, 'parallel'::text, 'post'::text])),
    context TEXT NOT NULL DEFAULT '',

    is_active BOOLEAN NOT NULL DEFAULT FALSE
);

-- INDEXES --

CREATE INDEX agents_id_idx ON agents(user_id);

-- RLS --

ALTER TABLE agents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow full access to own agents"
    ON agents
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- TRIGGERS --

CREATE TRIGGER update_agents_updated_at
BEFORE UPDATE ON agents
FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();