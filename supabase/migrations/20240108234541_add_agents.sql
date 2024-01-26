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
    task TEXT NOT NULL CHECK (char_length(task) <= 10000),
    instructions TEXT NOT NULL DEFAULT '',
    thought TEXT NOT NULL DEFAULT '',
    context TEXT NOT NULL DEFAULT '',
    profile JSONB NOT NULL DEFAULT '{}'
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

-- FUNCTIONS --

CREATE OR REPLACE FUNCTION create_agent(
    p_user_id UUID,
    p_name TEXT,
    p_task TEXT,
    p_tools_class TEXT,
    p_instructions TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    new_agent_id UUID;
BEGIN
    -- Insert into agents table and return the new agent_id
    INSERT INTO agents (user_id, name, task, instructions)
    VALUES (p_user_id, p_name, p_task, p_instructions)
    --- RETURNING id INTO new_agent_id;
    RETURNING *;

    -- TODO: REFACTOR!

    -- Create 'main' process
    INSERT INTO processes (user_id, agent_id, module_name, name, tools_class, is_active)
    VALUES (p_user_id, new_agent_id, module_name, main_prompt_name, tools_class, FALSE)

    --- Create 'thought_generator' process
    INSERT INTO processes (user_id, agent_id, module_name, name, tools_class, is_active)
    VALUES (p_user_id, new_agent_id, module_name, 'thought_generator', 'ThoughtGenerator', FALSE)

    --- Create 'data_storage_manager' process
    INSERT INTO processes (user_id, agent_id, module_name, name, tools_class, is_active)
    VALUES (p_user_id, new_agent_id, module_name, 'data_storage_manager', 'DataStorageManager', FALSE)

    RETURN new_agent_id; --- TODO: FULL TABLE!
END;
$$ LANGUAGE plpgsql;