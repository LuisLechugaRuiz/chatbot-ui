--------------- STATE MACHINE ---------------

-- TABLE --

CREATE TABLE IF NOT EXISTS state_machines (
    -- ID
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- RELATIONSHIPS
    -- agent_id UUID NOT NULL REFERENCES agents(id) ON DELETE CASCADE,
    -- process_id UUID REFERENCES process_states(id) ON DELETE CASCADE,

    state TEXT NOT NULL DEFAULT 'idle'::text CHECK (state = ANY (ARRAY['idle'::text, 'main_process'::text, 'thought_generator'::text])),
);
