--------------- EVENT TYPES ---------------

-- TABLE --

CREATE TABLE IF NOT EXISTS event_types (
    -- ID
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- RELATIONSHIPS
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- METADATA
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ,

    -- REQUIRED
    name TEXT NOT NULL CHECK (char_length(name) <= 100000),
    description TEXT NOT NULL CHECK (char_length(description) <= 100000)
);

-- INDEXES --

CREATE INDEX event_types_id_idx ON event_types(user_id);

-- RLS --

ALTER TABLE event_types ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow full access to own event_types"
    ON event_types
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());


--------------- EVENTS ---------------

-- TABLE --

CREATE TABLE IF NOT EXISTS events (
    -- ID
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- RELATIONSHIPS
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- METADATA
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ,

    -- REQUIRED
    event_type_id UUID NOT NULL REFERENCES event_types(id) ON DELETE CASCADE,
    message_name TEXT NOT NULL CHECK (char_length(message_name) <= 100000),
    content TEXT NOT NULL CHECK (char_length(content) <= 100000),
    status TEXT NOT NULL DEFAULT 'pending'::text CHECK (status = ANY (ARRAY['pending'::text, 'notified'::text]))
);

-- INDEXES --

CREATE INDEX events_id_idx ON events(user_id);

-- RLS --

ALTER TABLE events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow full access to own events"
    ON events
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- TRIGGERS --

CREATE TRIGGER update_event_updated_at
BEFORE UPDATE ON events
FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();


-- FUNCTIONS --

CREATE OR REPLACE FUNCTION create_event(
    p_user_id UUID,
    p_event_name TEXT,
    p_message_name TEXT,
    p_content TEXT
)
RETURNS SETOF events AS $$
DECLARE
    _event_type_id UUID;
BEGIN
    -- Check if a service with the same name and process_id already exists for the user
    SELECT id INTO _event_type_id
    FROM event_types
    WHERE user_id = p_user_id AND name = p_event_name;

    -- If a event_type is found, create a new event
    IF _event_type_id IS NOT NULL THEN
        RETURN QUERY
        INSERT INTO events (user_id, event_type_id, message_name, content)
        VALUES (p_user_id, _event_type_id, p_message_name, p_content)
        RETURNING *;
    ELSE
        -- Optionally, handle the case where the event_type does not exist
        RAISE EXCEPTION 'Event type with name % does not exist.', p_event_name;
    END IF;
END;
$$ LANGUAGE plpgsql;

--------------- SUBSCRIBED EVENTS ---------------

CREATE TABLE IF NOT EXISTS subscribed_events (
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    process_id UUID NOT NULL REFERENCES processes(id) ON DELETE CASCADE,
    event_type_id UUID NOT NULL REFERENCES event_types(id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, process_id, event_type_id)
);

-- RLS --

ALTER TABLE subscribed_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow full access to own subscribed_events"
    ON subscribed_events
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- FUNCTIONS --

ALTER TABLE subscribed_events
ADD CONSTRAINT subscribed_events_unique_constraint UNIQUE (user_id, process_id, event_type_id);

CREATE OR REPLACE FUNCTION create_event_subscription(p_process_id UUID, p_event_name TEXT)
RETURNS TABLE(returned_user_id UUID, returned_event_type_id UUID) AS $$
DECLARE
    _event_type_id UUID;
    _user_id UUID;
BEGIN
    -- Retrieve the event_type_id based on event_name from the event_types table
    SELECT id, user_id INTO _event_type_id, _user_id FROM event_types WHERE name = p_event_name LIMIT 1;

    -- Check if an event type with the given name exists
    IF _event_type_id IS NOT NULL THEN
        INSERT INTO subscribed_events (user_id, process_id, event_type_id)
        VALUES (_user_id, p_process_id, _event_type_id)
        ON CONFLICT (user_id, process_id, event_type_id) DO NOTHING;

        -- Set the return values if the subscription was successfully inserted
        returned_user_id := _user_id;
        returned_event_type_id := _event_type_id;
        RETURN NEXT;
    ELSE
        -- Handle the case where the event type does not exist
        RAISE EXCEPTION 'Event type with name % does not exist.', p_event_name;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_event_subscriptions(p_process_id UUID) 
RETURNS TABLE (event_id UUID, name TEXT, content TEXT, status TEXT, updated_at TIMESTAMPTZ) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        e.id, 
        et.name, 
        e.content,
        e.status,
        e.updated_at
    FROM subscribed_events se
    JOIN event_types et ON se.event_type_id = et.id
    JOIN events e ON se.event_type_id = e.event_type_id
    WHERE se.process_id = p_process_id;
END;
$$ LANGUAGE plpgsql;