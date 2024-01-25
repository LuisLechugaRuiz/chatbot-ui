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
    thought TEXT NOT NULL DEFAULT '',
    context TEXT NOT NULL DEFAULT '',
    profile JSONB NOT NULL DEFAULT '{}'

    --- INTERNAL PROCESSES
    main_process_id UUID REFERENCES processes(id) ON DELETE SET NULL,
    thought_generator_process_id UUID REFERENCES processes(id) ON DELETE SET NULL,
    context_manager_process_id UUID REFERENCES processes(id) ON DELETE SET NULL,
    data_storage_manager_process_id UUID REFERENCES processes(id) ON DELETE SET NULL,
);

-- INDEXES --

CREATE INDEX agents_id_idx ON agents(user_id);

-- RLS --

ALTER TABLE agents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow full access to own agents"
    ON profiles
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- TRIGGERS --

CREATE TRIGGER update_agents_updated_at
BEFORE UPDATE ON agents
FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();

-- FUNCTIONS --

CREATE OR REPLACE FUNCTION create_agent(user_id UUID, tools_class TEXT)
RETURNS UUID AS $$
DECLARE
    new_agent_id UUID;
    main_process_id UUID;
    thought_generator_process_id UUID;
    context_manager_process_id UUID;
    data_storage_manager_process_id UUID;
BEGIN
    -- Insert into agents table and return the new agent_id
    INSERT INTO agents (user_id, name)
    VALUES (user_id, tools_class)
    RETURNING id INTO new_agent_id;

    -- Create 'main' process and get its ID
    INSERT INTO processes (user_id, agent_id, name, tools_class, is_active)
    VALUES (user_id, new_agent_id, 'main', tools_class, FALSE)
    RETURNING id INTO main_process_id;

    --- Create 'thought_generator' process and get its ID
    INSERT INTO processes (user_id, agent_id, name, tools_class, is_active)
    VALUES (user_id, new_agent_id, 'thought_generator', "ThoughtGenerator", FALSE)
    RETURNING id INTO thought_generator_process_id;

    --- Create 'context_manager' process and get its ID
    INSERT INTO processes (user_id, agent_id, name, tools_class, is_active)
    VALUES (user_id, new_agent_id, 'context_manager', "ContextManager", FALSE)
    RETURNING id INTO context_manager_process_id;

    --- Create 'data_storage_manager' process and get its ID
    INSERT INTO processes (user_id, agent_id, name, tools_class, is_active)
    VALUES (user_id, new_agent_id, 'data_storage_manager', "DataStorageManager", FALSE)
    RETURNING id INTO data_storage_manager_process_id;

    -- Update the agent record with the process IDs
    UPDATE agents
    SET main_process_id = main_process_id,
        thought_generator_process_id = thought_generator_process_id,
        context_manager_process_id = context_manager_process_id,
        data_storage_manager_process_id = data_storage_manager_process_id
    WHERE id = new_agent_id;

    RETURN new_agent_id;
END;
$$ LANGUAGE plpgsql;