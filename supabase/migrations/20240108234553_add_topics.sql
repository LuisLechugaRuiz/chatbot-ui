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
    content TEXT NOT NULL CHECK (char_length(content) <= 100000),
    description TEXT NOT NULL CHECK (char_length(description) <= 100000)
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
    process_id UUID NOT NULL REFERENCES processes(id) ON DELETE CASCADE,
    topic_id UUID NOT NULL REFERENCES topics(id) ON DELETE CASCADE,
    PRIMARY KEY (process_id, topic_id)
);

CREATE OR REPLACE FUNCTION create_topic_subscription(p_process_id UUID, p_topic_name TEXT) RETURNS void AS $$
DECLARE
    _topic_id UUID;
BEGIN
    -- Retrieve the topic_id based on topic_name
    SELECT id INTO _topic_id FROM topics WHERE name = p_topic_name LIMIT 1;

    -- Check if a topic with the given name exists
    IF _topic_id IS NOT NULL THEN
        -- Insert the subscription using the found topic_id
        INSERT INTO subscribed_topics (process_id, topic_id)
        VALUES (p_process_id, _topic_id)
        ON CONFLICT (process_id, topic_id) DO NOTHING; -- Avoid duplicate entries
    ELSE
        -- Optionally, handle the case where the topic does not exist
        RAISE EXCEPTION 'Topic with name % does not exist.', p_topic_name;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_subscribed_data(p_process_id UUID) 
RETURNS TABLE (topic_id UUID, name TEXT, content TEXT, description TEXT, updated_at TIMESTAMPTZ) AS $$
BEGIN
    RETURN QUERY
    SELECT t.id, t.name, t.content, t.description, t.updated_at
    FROM subscribed_topics st
    JOIN topics t ON st.topic_id = t.id
    WHERE st.process_id = p_process_id;
END;
$$ LANGUAGE plpgsql;
