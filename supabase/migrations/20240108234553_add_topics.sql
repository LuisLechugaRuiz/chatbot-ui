--------------- TOPIC MESSAGES ---------------

-- TABLE --
CREATE TABLE IF NOT EXISTS topic_messages (
    -- ID
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- RELATIONSHIPS
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE

    -- METADATA
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ,

    -- REQUIRED
    name TEXT NOT NULL CHECK (char_length(name) <= 100),
    messages_format JSONB NOT NULL
);

-- INDEXES --

CREATE INDEX topic_messages_id_idx ON topic_messages(user_id);

-- RLS --

ALTER TABLE topic_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow full access to own topic_messages"
    ON topic_messages
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

--------------- TOPICS ---------------

-- TABLE --

CREATE TABLE IF NOT EXISTS topics (
    -- ID
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- RELATIONSHIPS
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    agent_id UUID DEFAULT NULL REFERENCES agents(id) ON DELETE SET NULL,
    topic_message_id UUID NOT NULL REFERENCES topic_messages(id) ON DELETE CASCADE,

    -- METADATA
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ,

    -- REQUIRED
    name TEXT NOT NULL CHECK (char_length(name) <= 100),
    description TEXT NOT NULL CHECK (char_length(description) <= 100000),
    message JSONB DEFAULT '{}'::jsonb,

    is_private BOOLEAN NOT NULL DEFAULT FALSE
);

-- INDEXES --

CREATE INDEX topic_id_idx ON topics(user_id);

-- RLS --

ALTER TABLE topics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow full access to own topics"
    ON topics
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- TRIGGERS

CREATE TRIGGER update_topic_updated_at
BEFORE UPDATE ON topics
FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();


--------------- TOPIC PUBLISHERS ---------------

-- TABLE --

CREATE TABLE IF NOT EXISTS topic_publishers (
    -- ID
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- RELATIONSHIPS
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    process_id UUID NOT NULL REFERENCES processes(id) ON DELETE CASCADE,
    topic_id UUID NOT NULL REFERENCES topics(id) ON DELETE CASCADE,
    topic_message_id UUID NOT NULL REFERENCES topic_messages(id) ON DELETE CASCADE,

    -- METADATA
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ
);

-- INDEXES --

CREATE INDEX topic_publishers_id_idx ON topic_publishers(user_id);

-- RLS --

ALTER TABLE topic_publishers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow full access to own topic_publishers"
    ON topic_publishers
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- TRIGGERS --

CREATE TRIGGER update_topic_publisher_updated_at
BEFORE UPDATE ON topic_publishers
FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();

-- FUNCTIONS --
CREATE OR REPLACE FUNCTION create_topic_publisher(
    p_user_id UUID,
    p_process_id UUID,
    p_topic_name TEXT
)
RETURNS TABLE(_id UUID, _topic_id UUID, _topic_message_id UUID) AS $$
BEGIN
    -- Find the topic by user_id and name, and get its id and topic_message_id
    SELECT id, topic_message_id INTO _topic_id, _topic_message_id
    FROM topics
    WHERE user_id = p_user_id AND name = p_topic_name;

    -- If no topic was found, raise an error
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Topic with name % not found', p_topic_name;
    END IF;

    -- Insert the new publisher into the topic_publishers table and return the new id
    INSERT INTO topic_publishers (user_id, process_id, topic_id, topic_message_id)
    VALUES (p_user_id, p_process_id, _topic_id, _topic_message_id)
    RETURNING id INTO _id;

    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;


--------------- TOPIC SUBSCRIBERS ---------------

-- TABLE --

CREATE TABLE IF NOT EXISTS topic_subscribers (
    -- ID
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- RELATIONSHIPS
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    process_id UUID NOT NULL REFERENCES processes(id) ON DELETE CASCADE,
    topic_id UUID NOT NULL REFERENCES topics(id) ON DELETE CASCADE,
    topic_message_id UUID NOT NULL REFERENCES topic_messages(id) ON DELETE CASCADE,

    -- METADATA
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ
);

-- INDEXES --

CREATE INDEX topic_subscribers_id_idx ON topic_subscribers(user_id);

-- RLS --

ALTER TABLE topic_subscribers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow full access to own topic_subscribers"
    ON topic_subscribers
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- TRIGGERS --

CREATE TRIGGER update_topic_subscriber_updated_at
BEFORE UPDATE ON topic_subscribers
FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();

-- FUNCTIONS --
CREATE OR REPLACE FUNCTION create_topic_subscriber(
    p_user_id UUID,
    p_process_id UUID,
    p_topic_name TEXT
)
RETURNS TABLE(_id UUID, _topic_id UUID, _topic_message_id UUID) AS $$
BEGIN
    -- Find the topic by user_id and name, and get its id and topic_message_id
    SELECT id, topic_message_id INTO _topic_id, _topic_message_id
    FROM topics
    WHERE user_id = p_user_id AND name = p_topic_name;

    -- If no topic was found, raise an error
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Topic with name % not found', p_topic_name;
    END IF;

    -- Insert into topic_subscribers and return the new id
    INSERT INTO topic_subscribers (user_id, process_id, topic_id, topic_message_id)
    VALUES (p_user_id, p_process_id, _topic_id, _topic_message_id)
    RETURNING id INTO _id;

    -- Return the values
    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION get_subscribed_topics(p_process_id UUID) 
RETURNS TABLE (topic_id UUID, user_id UUID, topic_message_id UUID, name TEXT, description TEXT, message JSONB, updated_at TIMESTAMPTZ) AS $$
BEGIN
    RETURN QUERY
    SELECT t.id, t.user_id, t.topic_message_id, t.name, t.description, t.message, t.updated_at
    FROM topic_subscribers ts
    JOIN topics t ON ts.topic_id = t.id
    WHERE ts.process_id = p_process_id;
END;
$$ LANGUAGE plpgsql;