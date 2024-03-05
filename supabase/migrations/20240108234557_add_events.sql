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
    description TEXT NOT NULL CHECK (char_length(description) <= 100000),
    message_format JSONB NOT NULL
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
    event_type_id UUID NOT NULL REFERENCES event_types(id) ON DELETE CASCADE,

    -- METADATA
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ,

    -- REQUIRED
    event_name TEXT NOT NULL,
    event_description TEXT NOT NULL,
    message JSONB NOT NULL,
    message_format JSONB NOT NULL,
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
    p_publisher_id UUID,
    p_event_message JSONB
)
RETURNS events AS $$
DECLARE
    _id UUID;
    _user_id UUID;
    _event_type_id UUID;
    _event_name TEXT;
    _event_description TEXT;
    _message_format JSONB;
    _status TEXT;
    _new_event events;
BEGIN
    -- Get the event_type_id from client_id
    SELECT event_type_id INTO _event_type_id
    FROM event_publishers
    WHERE id = p_publisher_id;

    -- If a event_publisher is found, create a new event
    IF _event_type_id IS NOT NULL THEN
        -- Check if a service with the same name and process_id already exists for the user
        SELECT user_id, name, description, message_format INTO _user_id, _event_name, _event_description, _message_format
        FROM event_types
        WHERE id = _event_type_id;

        RETURN QUERY
        INSERT INTO events (user_id, event_type_id, event_name, event_description, message, message_format)
        VALUES (_user_id, _event_type_id, _event_name, _event_description, p_event_message, _message_format)
        RETURNING * INTO _new_event;

        RETURN _new_event;
    ELSE
        -- Optionally, handle the case where the publisher does not exist
        RAISE EXCEPTION 'Event publisher with id % does not exist.', p_publisher_id;
    END IF;
END;
$$ LANGUAGE plpgsql;

--------------- EVENT PUBLISHERS ---------------

-- TABLE --

CREATE TABLE IF NOT EXISTS event_publishers (
    -- ID
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- RELATIONSHIPS
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    process_id UUID NOT NULL REFERENCES processes(id) ON DELETE CASCADE,
    event_type_id UUID NOT NULL REFERENCES event_types(id) ON DELETE CASCADE,

    -- METADATA
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ,

    -- REQUIRED
    event_name TEXT NOT NULL,
    event_description TEXT NOT NULL,
    event_format JSONB NOT NULL
);

-- INDEXES --

CREATE INDEX event_publishers_id_idx ON event_publishers(user_id);

-- RLS --

ALTER TABLE event_publishers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow full access to own event_publishers"
    ON event_publishers
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- TRIGGERS --

CREATE TRIGGER update_event_publisher_updated_at
BEFORE UPDATE ON event_publishers
FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();

-- FUNCTIONS --
CREATE OR REPLACE FUNCTION create_event_publisher(
    p_user_id UUID,
    p_process_id UUID,
    p_event_name TEXT
)
RETURNS TABLE(_id UUID, _event_type_id UUID, _event_description TEXT, _event_format JSONB) AS $$
BEGIN
    -- Find the topic by user_id and name, and get its id and topic_message_id
    SELECT id, description, message_format INTO _event_type_id, _event_description, _event_format
    FROM event_types
    WHERE user_id = p_user_id AND name = p_event_name;

    -- If no event type was found, raise an error
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Event Type with name % not found', p_event_name;
    END IF;

    -- Insert the new publisher into the event_publishers table and return the new id
    INSERT INTO event_publishers (user_id, process_id, event_type_id, event_name, event_description, event_format)
    VALUES (p_user_id, p_process_id, p_event_name, _event_type_id, _event_description, _event_format)
    RETURNING id INTO _id;

    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;

--------------- EVENT SUBSCRIBERS ---------------

-- TABLE --

CREATE TABLE IF NOT EXISTS event_subscribers (
    -- ID
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- RELATIONSHIPS
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    process_id UUID NOT NULL REFERENCES processes(id) ON DELETE CASCADE,
    event_type_id UUID NOT NULL REFERENCES event_types(id) ON DELETE CASCADE,

    -- METADATA
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ,

    -- REQUIRED
    event_name TEXT NOT NULL,
    event_description TEXT NOT NULL,
    event_format JSONB NOT NULL
);

-- INDEXES --

CREATE INDEX event_subscribers_id_idx ON event_subscribers(user_id);

-- RLS --

ALTER TABLE event_subscribers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow full access to own event_subscribers"
    ON event_subscribers
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- TRIGGERS --

CREATE TRIGGER update_event_subscriber_updated_at
BEFORE UPDATE ON event_subscribers
FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();

-- FUNCTIONS --
CREATE OR REPLACE FUNCTION create_event_subscriber(
    p_user_id UUID,
    p_process_id UUID,
    p_event_name TEXT
)
RETURNS TABLE(_id UUID, _event_type_id UUID, _event_description TEXT, _event_format JSONB) AS $$
BEGIN
    -- Find the topic by user_id and name, and get its id and topic_message_id
    SELECT id, description, message_format INTO _event_type_id, _event_description, _event_format
    FROM event_types
    WHERE user_id = p_user_id AND name = p_event_name;

    -- If no event type was found, raise an error
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Event Type with name % not found', p_event_name;
    END IF;

    -- Insert the new subscriber into the event_subscribers table
    INSERT INTO event_subscribers (user_id, process_id, event_type_id, event_name, event_description, event_format)
    VALUES (p_user_id, p_process_id, p_event_name, _event_type_id, _event_description, _event_format)
    RETURNING id INTO _id;

    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;