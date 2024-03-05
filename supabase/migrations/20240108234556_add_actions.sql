--------------- ACTION TYPES ---------------

-- TABLE --

CREATE TABLE IF NOT EXISTS action_types (
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

CREATE INDEX action_types_id_idx ON action_types(user_id);

-- RLS --

ALTER TABLE action_types ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow full access to own action_types"
    ON action_types
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

--------------- ACTION SERVICES ---------------

-- TABLE --

CREATE TABLE IF NOT EXISTS action_services (
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

CREATE INDEX action_services_id_idx ON action_services(user_id);

-- RLS --

ALTER TABLE action_services ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow full access to own action_services"
    ON action_services
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- TRIGGERS --

CREATE TRIGGER update_action_service_updated_at
BEFORE UPDATE ON action_services
FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();

-- FUNCTIONS --
CREATE OR REPLACE FUNCTION create_action_service(
    p_user_id UUID,
    p_process_id UUID,
    p_name TEXT,
    p_description TEXT,
    p_action_name TEXT,
    p_tool_name TEXT DEFAULT ''::text
)
RETURNS TABLE(_id UUID, _request_format JSONB, _feedback_format JSONB, _response_format JSONB) AS $$
BEGIN
    -- Check if a service with the same name and process_id already exists for the user
    SELECT id INTO _id
    FROM action_services
    WHERE user_id = p_user_id AND process_id = p_process_id AND name = p_name;

    -- If a service with the same name exists, fetch its formats and return without creating a new one
    IF FOUND THEN
        SELECT request_format, feedback_format, response_format INTO _request_format, _feedback_format, _response_format
        FROM action_services
        WHERE id = _id;
        
        RETURN NEXT;
    END IF;

    -- Fetch the formats from action_types based on action name
    SELECT request_format, feedback_format, response_format INTO _request_format, _feedback_format, _response_format
    FROM action_types
    WHERE user_id = p_user_id AND name = p_action_name;

    -- Check if the formats were found
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Action message with name % not found for user', p_action_name;
    END IF;

    -- Insert the new service into action_services table and return the new id
    INSERT INTO action_services (user_id, process_id, name, description, request_format, feedback_format, response_format, tool_name)
    VALUES (p_user_id, p_process_id, p_name, p_description, _request_format, _feedback_format, _response_format, p_tool_name)
    RETURNING id INTO _id;

    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;


--------------- ACTION CLIENTS ---------------

-- TABLE --

CREATE TABLE IF NOT EXISTS action_clients (
    -- ID
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- RELATIONSHIPS
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    process_id UUID NOT NULL REFERENCES processes(id) ON DELETE CASCADE,
    service_id UUID NOT NULL REFERENCES action_services(id),

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

CREATE INDEX action_clients_id_idx ON action_clients(user_id);

-- RLS --

ALTER TABLE action_clients ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow full access to own action_clients"
    ON action_clients
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- TRIGGERS --

CREATE TRIGGER update_action_client_updated_at
BEFORE UPDATE ON action_clients
FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();

-- FUNCTIONS --
CREATE OR REPLACE FUNCTION create_action_client(
    p_user_id UUID,
    p_process_id UUID,
    p_service_name TEXT
)
RETURNS TABLE(_id UUID, _process_name TEXT, _service_id UUID, _service_name TEXT, _service_description TEXT, _request_format JSONB) AS $$
BEGIN
    SELECT id, name, description, request_format INTO _service_id, _service_name, _service_description, _request_format
    FROM action_services
    WHERE user_id = p_user_id AND name = p_service_name;

    SELECT name INTO _process_name
    FROM processes
    WHERE id = p_process_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Service with name % not found', p_service_name;
    END IF;

    -- Insert the new client into the action_clients table and return the new id
    INSERT INTO action_clients (user_id, process_id, service_id, process_name, service_name, service_description, request_format)
    VALUES (p_user_id, p_process_id, _service_id, _process_name, _service_name, _service_description, _request_format)
    RETURNING id INTO _id;

    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;

--------------- ACTIONS ---------------

-- TABLE --

CREATE TABLE IF NOT EXISTS actions (
    -- ID
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- RELATIONSHIPS
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    service_id UUID NOT NULL REFERENCES action_services(id) ON DELETE CASCADE,
    service_process_id UUID NOT NULL REFERENCES processes(id) ON DELETE CASCADE,
    client_process_id UUID NOT NULL REFERENCES processes(id) ON DELETE CASCADE,

    -- METADATA
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ,

    -- REQUIRED
    service_name TEXT NOT NULL CHECK (char_length(service_name) <= 1000),
    client_process_name TEXT NOT NULL CHECK (char_length(client_process_name) <= 1000),
    request JSONB NOT NULL,
    feedback JSONB DEFAULT '{}'::jsonb,
    response JSONB DEFAULT '{}'::jsonb,
    priority INTEGER NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'pending'::text CHECK (status = ANY (ARRAY['pending'::text, 'in_progress'::text, 'success'::text, 'failure'::text, 'waiting_user_feedback'::text]))
);

-- INDEXES --

CREATE INDEX actions_id_idx ON actions(user_id);

-- RLS --

ALTER TABLE actions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow full access to own actions"
    ON actions
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- TRIGGERS --

CREATE TRIGGER update_action_updated_at
BEFORE UPDATE ON actions
FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();

-- FUNCTIONS --

CREATE OR REPLACE FUNCTION create_action(
    p_client_id UUID,
    p_request_message JSONB,
    p_priority INTEGER
)
RETURNS actions AS $$
DECLARE
    _user_id UUID;
    _service_id UUID;
    _client_process_id UUID;
    _client_process_name TEXT;
    _service_name TEXT;
    _service_process_id UUID;
    _request_format JSONB;
    _feedback_format JSONB;
    _feedback_message JSONB;
    _response_format JSONB;
    _response_message JSONB;
    _new_request actions;
BEGIN
    -- Retrieve the client from client id
    SELECT user_id, service_id, process_id, process_name INTO _user_id, _service_id, _client_process_id, _client_process_name
    FROM action_clients
    WHERE id = p_client_id;

    -- Check if a client was found
    IF _client_process_id IS NULL THEN
        RAISE EXCEPTION 'Client with id % not found.', p_client_id;
    END IF;

    -- Retrieve variables from the action_services table 
    SELECT name, process_id, request_format, feedback_format, response_format INTO _service_name, _service_process_id, _request_format, _feedback_format, _response_format
    FROM action_services
    WHERE id = _service_id

    -- Check if a service was found
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

    -- Iterate over feedback format and set NULL values for each key
    FOR _key IN SELECT jsonb_object_keys(_feedback_format)
    LOOP
        -- Set the corresponding key in _feedback_message to NULL
        _feedback_message := jsonb_set(_feedback_message, ARRAY[_key], 'null'::jsonb);
    END LOOP;

    FOR _key IN SELECT jsonb_object_keys(_response_format)
    LOOP
        _response_message := jsonb_set(_response_message, ARRAY[_key], 'null'::jsonb);
    END LOOP;

    -- Insert a new action into the actions table and return the entire row
    INSERT INTO actions (user_id, service_id, client_id, service_process_id, client_process_id, service_name, client_process_name, request, feedback, response, priority, status)
    VALUES (_user_id, _service_id, p_client_id, _service_process_id, _client_process_id, _service_name, _client_process_name,  p_request_message, _feedback_message, _response_message, p_priority, 'pending')
    RETURNING * INTO _new_request;

    RETURN _new_request;
END;
$$ LANGUAGE plpgsql;