--------------- REQUEST MESSAGES ---------------

-- TABLE --

CREATE TABLE IF NOT EXISTS request_messages (
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
    feedback_format JSONB NOT NULL,
    response_Format JSONB NOT NULL
);

-- INDEXES --

CREATE INDEX request_messages_id_idx ON request_messages(user_id);

-- RLS --

ALTER TABLE request_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow full access to own request_messages"
    ON request_messages
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
    feedback_format JSONB NOT NULL,
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
RETURNS TABLE(_id UUID, _request_format JSONB, _feedback_format JSONB, _response_format JSONB) AS $$
BEGIN
    -- Check if a service with the same name and process_id already exists for the user
    SELECT id INTO _id
    FROM request_services
    WHERE user_id = p_user_id AND process_id = p_process_id AND name = p_name;

    -- If a service with the same name exists, fetch its formats and return without creating a new one
    IF FOUND THEN
        SELECT request_format, feedback_format, response_format INTO _request_format, _feedback_format, _response_format
        FROM request_services
        WHERE id = _id;
        
        RETURN NEXT;
    END IF;

    -- Fetch the formats from request_messages based on request name
    SELECT request_format, feedback_format, response_format INTO _request_format, _feedback_format, _response_format
    FROM request_messages
    WHERE user_id = p_user_id AND name = p_request_name;

    -- Check if the formats were found
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Request message with name % not found for user', p_request_name;
    END IF;

    -- Insert the new service into request_services table and return the new id
    INSERT INTO request_services (user_id, process_id, name, description, request_format, feedback_format, response_format, tool_name)
    VALUES (p_user_id, p_process_id, p_name, p_description, _request_format, _feedback_format, _response_format, p_tool_name)
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
    process_name TEXT NOT NULL CHECK (char_length(process_name) <= 1000)
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
RETURNS TABLE(_id UUID, _service_id UUID, _process_name TEXT) AS $$
BEGIN
    SELECT id INTO _service_id
    FROM request_services
    WHERE user_id = p_user_id AND name = p_service_name;

    SELECT name INTO _process_name
    FROM processes
    WHERE id = p_process_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Service with name % not found', p_service_name;
    END IF;

    -- Insert the new client into the request_clients table and return the new id
    INSERT INTO request_clients (user_id, process_id, service_id, process_name)
    VALUES (p_user_id, p_process_id, _service_id, _process_name)
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
    client_process_name TEXT NOT NULL CHECK (char_length(client_process_name) <= 1000),
    request JSONB NOT NULL,
    feedback JSONB DEFAULT '{}'::jsonb,
    response JSONB DEFAULT '{}'::jsonb,
    is_async BOOLEAN NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending'::text CHECK (status = ANY (ARRAY['pending'::text, 'in_progress'::text, 'success'::text, 'failure'::text, 'waiting_user_feedback'::text]))
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
    p_user_id UUID,
    p_client_process_id UUID,
    p_client_process_name TEXT,
    p_service_id TEXT,
    p_request_message JSONB,
    p_is_async BOOLEAN
)
RETURNS requests AS $$
DECLARE
    _service_process_id UUID;
    _request_format JSONB;
    _feedback_format JSONB;
    _feedback_message JSONB;
    _response_format JSONB;
    _response_message JSONB;
    _new_request requests;
BEGIN
    -- Retrieve variables from the request_services table 
    SELECT process_id, request_format, feedback_format, response_format INTO _service_process_id, _request_format, _feedback_format, _response_format
    FROM request_services
    WHERE id = p_service_id
    LIMIT 1;

    -- Check if a service_id was found
    IF _service_process_id IS NULL THEN
        RAISE EXCEPTION 'Service with id % not found.', p_service_id;
    END IF;

    -- Check if p_request_message contains all keys defined in _request_format
    FOR _key IN SELECT jsonb_object_keys(_request_format)
    LOOP
        IF NOT (p_request_message ? _key) THEN
            RAISE EXCEPTION 'Missing required key % in request message.', _key;
        END IF;
    END LOOP;

    -- Iterate over feedback format and set NULL values for each key
    FOR _key IN SELECT jsonb_object_keys(_feedback_format)
    LOOP
        -- Set the corresponding key in _feedback_message to NULL
        _feedback_message := jsonb_set(_feedback_message, ARRAY[_key], 'null'::jsonb);
    END LOOP;

    FOR _key IN SELECT jsonb_object_keys(_response_format)
    LOOP
        _feedback_message := jsonb_set(_response_message, ARRAY[_key], 'null'::jsonb);
    END LOOP;

    -- Insert a new request into the requests table and return the entire row
    -- TODO: TRANSLATE THE FEEDBACK FORMAT TO DEFAULT FEEDBACK
    INSERT INTO requests (user_id, service_id, service_process_id, client_process_id, client_process_name, request, feedback, response, is_async, status)
    VALUES (p_user_id, p_service_id, _service_process_id, p_client_process_id, p_client_process_name,  p_request_message, _feedback_message, _response_message, p_is_async, 'pending')
    RETURNING * INTO _new_request;

    RETURN _new_request;
END;
$$ LANGUAGE plpgsql;