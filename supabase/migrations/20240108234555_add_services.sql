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
    description TEXT NOT NULL CHECK (char_length(description) <= 100000)
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
    p_process_id UUID,
    p_name TEXT,
    p_description TEXT
)
RETURNS UUID AS $$
DECLARE
    _id UUID;
BEGIN
    -- Check if a service with the same name and process_id already exists for the user
    SELECT id INTO _id
    FROM services
    WHERE user_id = p_user_id AND process_id = p_process_id AND name = p_name;

    -- If a service with the same name exists, return its id without creating a new one
    IF FOUND THEN
        RETURN _id;  -- Return the existing service id directly
    END IF;

    -- Insert the new service into the services table and return the new id
    INSERT INTO services (user_id, process_id, name, description)
    VALUES (p_user_id, p_process_id, p_name, p_description)
    RETURNING id INTO _id;

    RETURN _id;  -- Return the new service id
END;
$$ LANGUAGE plpgsql;