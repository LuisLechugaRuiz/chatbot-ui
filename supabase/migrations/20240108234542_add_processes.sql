--------------- PROCESSES ---------------

-- TABLE --

CREATE TABLE IF NOT EXISTS processes (
    -- ID
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- RELATIONSHIPS
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    agent_id UUID REFERENCES agents(id) ON DELETE CASCADE,

    -- METADATA
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ,

    -- REQUIRED
    name TEXT NOT NULL CHECK (char_length(name) <= 100),
    capability_class TEXT NOT NULL CHECK (char_length(capability_class) <= 100),
    flow_type TEXT NOT NULL DEFAULT 'interactive'::text CHECK (flow_type = ANY (ARRAY['interactive'::text, 'independent'::text]))
    type TEXT NOT NULL DEFAULT 'main'::text CHECK (type = ANY (ARRAY['main'::text, 'internal'::text])),
);

-- INDEXES --

CREATE INDEX processes_id_idx ON processes(user_id);

-- RLS --

ALTER TABLE processes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow full access to own processes"
    ON processes
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- TRIGGERS --

CREATE TRIGGER update_processes_updated_at
BEFORE UPDATE ON processes
FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();


--------------- PROCESS STATES ---------------

-- TABLE --

CREATE TABLE IF NOT EXISTS process_states (
    -- ID
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- RELATIONSHIPS
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    process_id UUID REFERENCES processes(id) ON DELETE CASCADE,

    -- METADATA
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ,

    -- REQUIRED,
    name TEXT NOT NULL CHECK (char_length(name) <= 1000),
    task TEXT NOT NULL CHECK (char_length(task) <= 10000),
    instructions TEXT NOT NULL CHECK (char_length(instructions) <= 10000)
);

-- INDEXES --

CREATE INDEX process_states_id_idx ON process_states(user_id);

-- RLS --

ALTER TABLE process_states ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow full access to own process_states"
    ON process_states
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- TRIGGERS --

CREATE TRIGGER update_process_states_updated_at
BEFORE UPDATE ON process_states
FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();


--------------- CURRENT PROCESS STATES ---------------

-- TABLE --

CREATE TABLE IF NOT EXISTS current_process_states (
    -- ID
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- RELATIONSHIPS
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    process_id UUID REFERENCES processes(id) ON DELETE CASCADE,
    current_state_id UUID NOT NULL REFERENCES process_states(id) ON DELETE CASCADE,

    -- METADATA
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ
);

-- RLS --

ALTER TABLE current_process_states ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow full access to own current_process_states"
    ON current_process_states
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- FUNCTIONS --

CREATE OR REPLACE FUNCTION get_current_process_state(p_process_id UUID) 
RETURNS TABLE (
    id UUID,
    user_id UUID,
    process_id UUID,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    name TEXT,
    task TEXT,
    instructions TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT ps.*
    FROM process_states ps
    INNER JOIN current_process_states cps ON ps.id = cps.current_state_id
    WHERE cps.process_id = p_process_id;
END;
$$ LANGUAGE plpgsql;