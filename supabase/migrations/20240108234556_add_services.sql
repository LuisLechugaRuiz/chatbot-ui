--------------- SERVICES ---------------

-- TABLE --

CREATE TABLE IF NOT EXISTS services (
    -- ID
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- RELATIONSHIPS
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    process_id UUID NOT NULL REFERENCES processes(id) ON DELETE CASCADE,
    request_type_id UUID NOT NULL REFERENCES request_types(id),

    -- METADATA
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ,

    -- REQUIRED
    name TEXT NOT NULL CHECK (char_length(name) <= 100),
    description TEXT NOT NULL CHECK (char_length(description) <= 100000),
    tool_name TEXT DEFAULT ''::text
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
    p_description TEXT,
    p_request_name TEXT,
    p_tool_name TEXT DEFAULT ''::text
)
RETURNS UUID AS $$
DECLARE
    _id UUID;
    _request_type_id UUID;
BEGIN
    -- Check if a service with the same name and process_id already exists for the user
    SELECT id INTO _id
    FROM services
    WHERE user_id = p_user_id AND process_id = p_process_id AND name = p_name;

    -- If a service with the same name exists, return its id without creating a new one
    IF FOUND THEN
        RETURN _id;  -- Return the existing service id directly
    END IF;

    SELECT id INTO _request_type_id
    from request_types
    WHERE user_id = p_user_id AND name = p_request_name;

    -- Insert the new service into the services table and return the new id
    INSERT INTO services (user_id, process_id, name, description, request_type_id, tool_name)
    VALUES (p_user_id, p_process_id, p_name, p_description, _request_type_id, p_tool_name)
    RETURNING id INTO _id;

    RETURN _id;  -- Return the new service id
END;
$$ LANGUAGE plpgsql;


--------------- CLIENTS ---------------

-- TABLE --

CREATE TABLE IF NOT EXISTS clients (
    -- ID
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- RELATIONSHIPS
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    process_id UUID NOT NULL REFERENCES processes(id) ON DELETE CASCADE,
    service_id UUID NOT NULL REFERENCES services(id),
    request_type_id UUID NOT NULL REFERENCES request_types(id),

    -- METADATA
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ
);

-- INDEXES --

CREATE INDEX clients_id_idx ON clients(user_id);

-- RLS --

ALTER TABLE clients ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow full access to own clients"
    ON clients
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- TRIGGERS --

CREATE TRIGGER update_client_updated_at
BEFORE UPDATE ON clients
FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();

-- FUNCTIONS --
CREATE OR REPLACE FUNCTION create_client(
    p_user_id UUID,
    p_process_id UUID,
    p_service_name TEXT
)
RETURNS UUID AS $$
DECLARE
    _service_id UUID;
    _request_type_id UUID;
BEGIN
    SELECT id, request_type_id INTO _service_id, _request_type_id
    FROM services
    WHERE user_id = p_user_id AND name = p_service_name;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Service with name % not found', p_service_name;
    END IF;

    -- Insert the new client into the clients table and return the new id
    INSERT INTO clients (user_id, process_id, service_id, request_type_id)
    VALUES (p_user_id, p_process_id, _service_id, _request_type_id)
    RETURNING id INTO _id;

    RETURN _id;  -- Return the new client id
END;
$$ LANGUAGE plpgsql;