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
    name TEXT NOT NULL CHECK (char_length(name) <= 100000),
    content TEXT NOT NULL CHECK (char_length(content) <= 100000)
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

--------------- SUBSCRIBED EVENTS ---------------

CREATE TABLE IF NOT EXISTS subscribed_events (
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    process_id UUID NOT NULL REFERENCES processes(id) ON DELETE CASCADE,
    event_name TEXT NOT NULL,
    PRIMARY KEY (user_id, process_id, event_name)
);

-- RLS --

ALTER TABLE subscribed_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow full access to own subscribed_events"
    ON subscribed_events
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- FUNCTIONS --

ALTER TABLE subscribed_events
ADD CONSTRAINT subscribed_events_unique_constraint UNIQUE (user_id, process_id, event_name);

CREATE OR REPLACE FUNCTION create_event_subscription(p_user_id UUID, p_process_id UUID, p_event_name TEXT) RETURNS void AS $$
BEGIN
    INSERT INTO subscribed_events (user_id, process_id, event_name)
    VALUES (p_user_id, p_process_id, p_event_name)
    ON CONFLICT (user_id, process_id, event_name) DO NOTHING; -- Avoid duplicate entries
END;
$$ LANGUAGE plpgsql;