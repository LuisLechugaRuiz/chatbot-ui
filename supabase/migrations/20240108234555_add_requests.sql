--------------- REQUEST TYPES ---------------

-- TABLE --

CREATE TABLE IF NOT EXISTS request_types (
    -- ID
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- RELATIONSHIPS
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- METADATA
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ,

    -- REQUIRED
    name TEXT NOT NULL CHECK (char_length(name) <= 100),
    request_format JSONB NOT NULL,
    response_Format JSONB NOT NULL
);

-- INDEXES --

CREATE INDEX request_types_id_idx ON request_types(user_id);

-- RLS --

ALTER TABLE request_types ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow full access to own request_types"
    ON request_types
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

--------------- REQUEST SERVICES ---------------

-- TABLE --

CREATE TABLE IF NOT EXISTS request_services (
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
    request_format JSONB NOT NULL,
    response_format JSONB NOT NULL,
    tool_name TEXT DEFAULT ''::text
);

-- INDEXES --

CREATE INDEX request_services_id_idx ON request_services(user_id);

-- RLS --

ALTER TABLE request_services ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow full access to own request_services"
    ON request_services
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- TRIGGERS --

CREATE TRIGGER update_request_service_updated_at
BEFORE UPDATE ON request_services
FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();

-- FUNCTIONS --
CREATE OR REPLACE FUNCTION create_request_service(
    p_user_id UUID,
    p_process_id UUID,
    p_name TEXT,
    p_description TEXT,
    p_request_name TEXT,
    p_tool_name TEXT DEFAULT ''::text
)
RETURNS TABLE(_id UUID, _request_format JSONB, _response_format JSONB) AS $$
BEGIN
    -- Check if a service with the same name and process_id already exists for the user
    SELECT id INTO _id
    FROM request_services
    WHERE user_id = p_user_id AND process_id = p_process_id AND name = p_name;

    -- If a service with the same name exists, fetch its formats and return without creating a new one
    IF FOUND THEN
        SELECT request_format, response_format INTO _request_format, _response_format
        FROM request_services
        WHERE id = _id;
        
        RETURN NEXT;
    END IF;

    -- Fetch the formats from request_types based on request name
    SELECT request_format, response_format INTO _request_format, _response_format
    FROM request_types
    WHERE user_id = p_user_id AND name = p_request_name;

    -- Check if the formats were found
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Request message with name % not found for user', p_request_name;
    END IF;

    -- Insert the new service into request_services table and return the new id
    INSERT INTO request_services (user_id, process_id, name, description, request_format, response_format, tool_name)
    VALUES (p_user_id, p_process_id, p_name, p_description, _request_format, _response_format, p_tool_name)
    RETURNING id INTO _id;

    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;


--------------- REQUEST CLIENTS ---------------

-- TABLE --

CREATE TABLE IF NOT EXISTS request_clients (
    -- ID
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- RELATIONSHIPS
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    process_id UUID NOT NULL REFERENCES processes(id) ON DELETE CASCADE,
    service_id UUID NOT NULL REFERENCES request_services(id),

    -- METADATA
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ,

    -- REQUIRED
    process_name TEXT NOT NULL CHECK (char_length(process_name) <= 1000),
    service_name TEXT NOT NULL CHECK (char_length(service_name) <= 1000),
    service_description TEXT NOT NULL CHECK (char_length(service_description) <= 100000),
    request_format JSONB NOT NULL
);

-- INDEXES --

CREATE INDEX request_clients_id_idx ON request_clients(user_id);

-- RLS --

ALTER TABLE request_clients ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow full access to own request_clients"
    ON request_clients
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- TRIGGERS --

CREATE TRIGGER update_request_client_updated_at
BEFORE UPDATE ON request_clients
FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();

-- FUNCTIONS --
CREATE OR REPLACE FUNCTION create_request_client(
    p_user_id UUID,
    p_process_id UUID,
    p_service_name TEXT
)
RETURNS TABLE(_id UUID, _process_name TEXT, _service_id UUID, _service_name TEXT, _service_description TEXT, _request_format JSONB) AS $$
BEGIN
    SELECT id, name, description, request_format INTO _service_id, _service_name, _service_description, _request_format
    FROM request_services
    WHERE user_id = p_user_id AND name = p_service_name;

    SELECT name INTO _process_name
    FROM processes
    WHERE id = p_process_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Service with name % not found', p_service_name;
    END IF;

    -- Insert the new client into the request_clients table and return the new id
    INSERT INTO request_clients (user_id, process_id, service_id, process_name, service_name, service_description, request_format)
    VALUES (p_user_id, p_process_id, _service_id, _process_name, _service_name, _service_description, _request_format)
    RETURNING id INTO _id;

    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;

--------------- REQUESTS ---------------

-- TABLE --

CREATE TABLE IF NOT EXISTS requests (
    -- ID
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- RELATIONSHIPS
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    service_id UUID NOT NULL REFERENCES request_services(id) ON DELETE CASCADE,
    service_process_id UUID NOT NULL REFERENCES processes(id) ON DELETE CASCADE,
    client_process_id UUID NOT NULL REFERENCES processes(id) ON DELETE CASCADE,

    -- METADATA
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ,

    -- REQUIRED
    service_name TEXT NOT NULL CHECK (char_length(service_name) <= 1000),
    client_process_name TEXT NOT NULL CHECK (char_length(client_process_name) <= 1000),
    request JSONB NOT NULL,
    response JSONB DEFAULT '{}'::jsonb,
    priority INTEGER NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'pending'::text CHECK (status = ANY (ARRAY['pending'::text, 'in_progress'::text, 'success'::text, 'failure'::text]))
);

-- INDEXES --

CREATE INDEX requests_id_idx ON requests(user_id);

-- RLS --

ALTER TABLE requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow full access to own requests"
    ON requests
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- TRIGGERS --

CREATE TRIGGER update_request_updated_at
BEFORE UPDATE ON requests
FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();

-- FUNCTIONS --

CREATE OR REPLACE FUNCTION create_request(
    p_client_id UUID,
    p_request_message JSONB,
    p_priority INTEGER
)
RETURNS requests AS $$
DECLARE
    _user_id UUID;
    _service_id UUID;
    _client_process_id UUID;
    _client_process_name TEXT;
    _service_name TEXT;
    _service_process_id UUID;
    _request_format JSONB;
    _response_format JSONB;
    _response_message JSONB;
    _new_request requests;
BEGIN
    -- Retrieve the client from client id
    SELECT user_id, service_id, process_id, process_name INTO _user_id, _service_id, _client_process_id, _client_process_name
    FROM action_clients
    WHERE id = p_client_id;

    -- Check if a client was found
    IF _client_process_id IS NULL THEN
        RAISE EXCEPTION 'Client with id % not found.', p_client_id;
    END IF;

    -- Retrieve variables from the request_services table 
    SELECT name, process_id, request_format, response_format INTO _service_name, _service_process_id, _request_format, _response_format
    FROM request_services
    WHERE id = _service_id
    LIMIT 1;

    -- Check if a service_id was found
    IF _service_process_id IS NULL THEN
        RAISE EXCEPTION 'Service with id % not found.', _service_id;
    END IF;

    -- Check if p_request_message contains all keys defined in _request_format
    FOR _key IN SELECT jsonb_object_keys(_request_format)
    LOOP
        IF NOT (p_request_message ? _key) THEN
            RAISE EXCEPTION 'Missing required key % in request message.', _key;
        END IF;
    END LOOP;

    FOR _key IN SELECT jsonb_object_keys(_response_format)
    LOOP
        _response_message := jsonb_set(_response_message, ARRAY[_key], 'null'::jsonb);
    END LOOP;

    -- Insert a new request into the requests table and return the entire row
    INSERT INTO requests (user_id, service_id, client_id, service_process_id, client_process_id, service_name, client_process_name, request, response, priority, status)
    VALUES (_user_id, _service_id, p_client_id, _service_process_id, _client_process_id, _service_name, _client_process_name,  p_request_message, _response_message, p_priority, 'pending')
    RETURNING * INTO _new_request;

    RETURN _new_request;
END;
$$ LANGUAGE plpgsql;