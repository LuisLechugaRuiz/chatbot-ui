--------------- CAPABILITIES ---------------

-- TABLE --

CREATE TABLE IF NOT EXISTS capabilities (
    -- ID
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- RELATIONSHIPS
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    process_id UUID NOT NULL REFERENCES processes(id) ON DELETE CASCADE,

    -- METADATA
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP

    -- REQUIRED
    name TEXT NOT NULL,
    description TEXT NOT NULL
);

-- INDEXES --

CREATE INDEX capabilities_id_idx ON capabilities(user_id);

-- RLS --

ALTER TABLE capabilities ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow full access to own capabilities"
    ON capabilities
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- TRIGGERS --

CREATE TRIGGER update_capabilities_updated_at
BEFORE UPDATE ON capabilities
FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();

--------------- CAPABILITIES VARIABLES ---------------

-- TABLE --

CREATE TABLE IF NOT EXISTS capabilities_variables (
    -- ID
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- RELATIONSHIPS
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    capability_id UUID NOT NULL REFERENCES capabilities(id) ON DELETE CASCADE,

    -- METADATA
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP

    -- REQUIRED
    name TEXT NOT NULL,
    content TEXT NOT NULL
);

-- INDEXES --

CREATE INDEX capabilities_variables_id_idx ON capabilities_variables(user_id);

-- RLS --

ALTER TABLE capabilities_variables ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow full access to own capabilities_variables"
    ON capabilities_variables
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- TRIGGERS --

CREATE TRIGGER update_capabilities_variables_updated_at
BEFORE UPDATE ON capabilities_variables
FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();