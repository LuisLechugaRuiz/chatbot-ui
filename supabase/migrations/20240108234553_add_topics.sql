--------------- TOPICS ---------------

-- TABLE --

CREATE TABLE IF NOT EXISTS topics (
    -- ID
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- RELATIONSHIPS
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- METADATA
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ,

    -- REQUIRED
    name TEXT NOT NULL CHECK (char_length(name) <= 100),
    description TEXT NOT NULL CHECK (char_length(description) <= 100000),
    content TEXT DEFAULT ''::text
);

-- INDEXES --

CREATE INDEX topic_id_idx ON topics(user_id);

-- RLS --

ALTER TABLE topics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow full access to own topics"
    ON topics
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- TRIGGERS -- TODO: VERIFY THIS OVERRIDES CURRENT VALUE

CREATE TRIGGER update_topic_updated_at
BEFORE UPDATE ON topics
FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();


--------------- PUBLISHED TOPICS ---------------
-- CREATE TABLE IF NOT EXISTS published_topics (
--     process_id UUID NOT NULL REFERENCES processes(id) ON DELETE CASCADE,
--     topic_id UUID NOT NULL REFERENCES topics(id) ON DELETE CASCADE,
--     PRIMARY KEY (process_id, topic_id)
-- );

-- CREATE OR REPLACE FUNCTION create_publisher(p_process_id UUID, p_topic_id UUID) RETURNS void AS $$
-- BEGIN
--     INSERT INTO published_topics (process_id, topic_id)
--     VALUES (p_process_id, p_topic_id)
--     ON CONFLICT (process_id, p_topic_id) DO NOTHING; -- Avoid duplicate entries
-- END;
-- $$ LANGUAGE plpgsql;


--------------- SUBSCRIBED TOPICS ---------------

CREATE TABLE IF NOT EXISTS subscribed_topics (
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    process_id UUID NOT NULL REFERENCES processes(id) ON DELETE CASCADE,
    topic_id UUID NOT NULL REFERENCES topics(id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, process_id, topic_id)
);

-- RLS --

ALTER TABLE subscribed_topics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow full access to own subscribed_topics"
    ON subscribed_topics
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE OR REPLACE FUNCTION create_topic_subscription(p_process_id UUID, p_topic_name TEXT)
RETURNS TABLE(returned_user_id UUID, returned_topic_id UUID) AS $$
DECLARE
    _user_id UUID;
    _topic_id UUID;
BEGIN
    -- Retrieve the topic_id based on topic_name
    SELECT id, user_id INTO _topic_id, _user_id FROM topics WHERE name = p_topic_name LIMIT 1;

    -- Check if a topic with the given name exists
    IF _topic_id IS NOT NULL THEN
        -- Attempt to insert the subscription and capture the subscription ID
        BEGIN
            INSERT INTO subscribed_topics (user_id, process_id, topic_id)
            VALUES (_user_id, p_process_id, _topic_id)
            ON CONFLICT (user_id, process_id, topic_id) DO NOTHING;

            -- Set the return values if the subscription was successfully inserted
            returned_user_id := _user_id;
            returned_topic_id := _topic_id;
            RETURN NEXT;
        EXCEPTION WHEN unique_violation THEN
            -- Handle the case where the subscription already exists
            returned_user_id := _user_id;
            returned_topic_id := _topic_id;
            RETURN NEXT;
        END;
    ELSE
        -- Optionally, handle the case where the topic does not exist
        RAISE EXCEPTION 'Topic with name % does not exist.', p_topic_name;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_topic_subscriptions(p_process_id UUID) 
RETURNS TABLE (topic_id UUID, name TEXT, description TEXT, content TEXT, updated_at TIMESTAMPTZ) AS $$
BEGIN
    RETURN QUERY
    SELECT t.id, t.name, t.description, t.content, t.updated_at
    FROM subscribed_topics st
    JOIN topics t ON st.topic_id = t.id
    WHERE st.process_id = p_process_id;
END;
$$ LANGUAGE plpgsql;
