--------------- REQUESTS ---------------

-- TABLE --

CREATE TABLE IF NOT EXISTS requests (
    -- ID
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- RELATIONSHIPS
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    service_id UUID NOT NULL REFERENCES services(id) ON DELETE CASCADE,
    service_process_id UUID NOT NULL REFERENCES processes(id) ON DELETE CASCADE,
    client_process_id UUID NOT NULL REFERENCES processes(id) ON DELETE CASCADE,
    client_process_name TEXT NOT NULL CHECK (char_length(client_process_name) <= 1000),

    -- METADATA
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ,

    -- REQUIRED
    query TEXT NOT NULL CHECK (char_length(query) <= 100000),
    is_async BOOLEAN NOT NULL,
    feedback TEXT NOT NULL DEFAULT ''::text CHECK (char_length(feedback) <= 100000),
    status TEXT NOT NULL DEFAULT 'pending'::text CHECK (status = ANY (ARRAY['pending'::text, 'in_progress'::text, 'success'::text, 'failure'::text, 'waiting_user_feedback'::text])),
    response TEXT NOT NULL DEFAULT ''::text CHECK (char_length(response) <= 100000)
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
    p_service_name TEXT,
    p_query TEXT,
    p_is_async BOOLEAN
)
RETURNS SETOF requests AS $$
DECLARE
    _service_id UUID;
    _service_process_id UUID;
BEGIN
    -- Find the service_id by matching service_name for the given user_id
    SELECT id, process_id INTO _service_id, _service_process_id
    FROM services
    WHERE user_id = p_user_id AND name = p_service_name
    LIMIT 1;

    -- Check if a service_id was found
    IF _service_id IS NULL THEN
        RAISE EXCEPTION 'Service with name % for user_id % not found.', p_service_name, p_user_id;
    END IF;

    -- Insert a new request into the requests table and return the entire row
    RETURN QUERY
    INSERT INTO requests (user_id, service_id, service_process_id, client_process_id, client_process_name, query, is_async, feedback, status, response)
    VALUES (p_user_id, _service_id, _service_process_id, p_client_process_id, p_client_process_name, p_query, p_is_async, '', 'pending', '')
    RETURNING *;
END;
$$ LANGUAGE plpgsql;