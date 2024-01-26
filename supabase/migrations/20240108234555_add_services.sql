--------------- SERVICES ---------------

-- TABLE --

CREATE TABLE IF NOT EXISTS services (
    -- ID
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- RELATIONSHIPS
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    process_id UUID NOT NULL REFERENCES processes(id) ON DELETE CASCADE,

    -- METADATA
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ,

    -- REQUIRED
    name TEXT NOT NULL CHECK (char_length(name) <= 100),
    description TEXT NOT NULL CHECK (char_length(description) <= 100000),
    prompt_prefix TEXT NOT NULL CHECK (char_length(prompt_prefix) <= 100000)
);

-- INDEXES --

CREATE INDEX services_id_idx ON services(user_id);

-- RLS --

ALTER TABLE services ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow full access to own services"
    ON services
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- TRIGGERS --

CREATE TRIGGER update_service_updated_at
BEFORE UPDATE ON services
FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();

-- FUNCTIONS --

CREATE OR REPLACE FUNCTION create_service(
    p_user_id UUID,
    p_tool_class TEXT,
    p_name TEXT,
    p_description TEXT,
    p_prompt_prefix TEXT
)
RETURNS TABLE(returned_id UUID, returned_process_id UUID) AS $$
DECLARE
    _process_id UUID;
    _id UUID;
BEGIN
    -- Check if a service with the same name already exists for the user
    SELECT id, process_id INTO _id, _process_id
    FROM services
    WHERE user_id = p_user_id AND name = p_name;

    -- If a service with the same name exists, return the id and process_id without creating a new one
    IF FOUND THEN
        returned_id := _id;
        returned_process_id := _process_id;
        RETURN NEXT;
    END IF;

    -- If no existing service is found, find the process_id from the processes table
    SELECT process_id INTO _process_id
    FROM processes
    WHERE user_id = p_user_id AND tool_class = p_tool_class
    LIMIT 1;

    -- Check if a process_id was found
    IF _process_id IS NULL THEN
        RAISE EXCEPTION 'Process with user_id % and tool_class % not found.', p_user_id, p_tool_class;
    END IF;

    -- Insert the new service into the services table and return the new id
    INSERT INTO services (user_id, process_id, name, description, prompt_prefix)
    VALUES (p_user_id, _process_id, p_name, p_description, p_prompt_prefix)
    RETURNING id INTO _id;

    returned_id := _id;
    returned_process_id := _process_id;
    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;