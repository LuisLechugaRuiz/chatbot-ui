--------------- MESSAGES ---------------

-- TABLE --

CREATE TABLE IF NOT EXISTS messages (
    -- ID
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- RELATIONSHIPS
    chat_id UUID NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- METADATA
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ,

    -- REQUIRED
    model TEXT NOT NULL CHECK (char_length(model) <= 1000),
    process_name TEXT NOT NULL CHECK (char_length(process_name) <= 1000),
    message_type TEXT NOT NULL CHECK (char_length(message_type) <= 1000),
    role TEXT NOT NULL CHECK (char_length(role) <= 1000),
    sequence_number INT NOT NULL,
    active BOOLEAN NOT NULL DEFAULT true,
    image_paths TEXT[] NOT NULL, -- file paths in message_images bucket

    -- OPTIONAL
    name TEXT,  -- Optional, used only for user and assistant names
    content TEXT,  -- Optional, standard message content
    tool_calls JSONB,  -- For storing structured data related to tool calls
    tool_call_id TEXT  -- Optional, used only for ToolResponseMessage

    -- CONSTRAINTS
    CONSTRAINT check_image_paths_length CHECK (array_length(image_paths, 1) <= 16)
);

-- INDEXES --

CREATE INDEX idx_messages_chat_id ON messages (chat_id);

-- RLS --

ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow full access to own messages"
    ON messages
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Allow view access to messages for non-private chats"
    ON messages
    FOR SELECT
    USING (chat_id IN (
        SELECT id FROM chats WHERE sharing <> 'private'
    ));

-- FUNCTIONS --

CREATE OR REPLACE FUNCTION insert_new_message(
    p_chat_id UUID,
    p_user_id UUID,
    p_model TEXT,
    p_process_name TEXT,
    p_message_type TEXT,
    p_role TEXT,
    p_image_paths TEXT[] DEFAULT '{}',
    p_name TEXT DEFAULT NULL,
    p_content TEXT DEFAULT NULL,
    p_tool_calls JSONB DEFAULT NULL,
    p_tool_call_id TEXT DEFAULT NULL
)
RETURNS SETOF messages AS $$
DECLARE
  _sequence_number INT;
BEGIN
  SELECT COALESCE(MAX(sequence_number), 0) + 1 INTO _sequence_number FROM messages WHERE chat_id = p_chat_id AND process_name = p_process_name;

  RETURN QUERY INSERT INTO messages (
      chat_id, 
      user_id, 
      model, 
      process_name, 
      message_type, 
      role, 
      image_paths, 
      sequence_number, 
      name, 
      content, 
      tool_calls, 
      tool_call_id, 
      active
  )
  VALUES (
      p_chat_id, 
      p_user_id, 
      p_model, 
      p_process_name, 
      p_message_type, 
      p_role, 
      p_image_paths, 
      _sequence_number, 
      p_name, 
      p_content, 
      p_tool_calls, 
      p_tool_call_id, 
      TRUE
  )
  RETURNING *;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION soft_delete_message(p_message_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE messages SET active = FALSE WHERE id = p_message_id;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION get_active_messages(p_chat_id UUID, p_process_name TEXT)
RETURNS TABLE(
    id UUID,
    chat_id UUID,
    user_id UUID,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    model TEXT,
    process_name TEXT,
    message_type TEXT,
    role TEXT,
    sequence_number INT,
    name TEXT,
    content TEXT,
    tool_calls JSONB,
    tool_call_id UUID,
    active BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        messages.id,
        messages.chat_id,
        messages.user_id,
        messages.created_at,
        messages.updated_at,
        messages.model,
        messages.process_name,
        messages.message_type AS type,
        messages.role,
        messages.sequence_number,
        messages.name,
        messages.content,
        messages.tool_calls,
        messages.tool_call_id,
        messages.active
    FROM messages
    WHERE messages.chat_id = p_chat_id AND messages.process_name = p_process_name AND messages.active = TRUE
    ORDER BY messages.sequence_number ASC;
END;
$$ LANGUAGE plpgsql;

--------------- BACKEND MESSAGES ---------------

-- TABLE --

CREATE TABLE IF NOT EXISTS backend_messages (
    -- ID
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- RELATIONSHIPS
    chat_id UUID NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- METADATA
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ,

    -- REQUIRED
    model TEXT NOT NULL CHECK (char_length(model) <= 1000),
    process_name TEXT NOT NULL CHECK (char_length(process_name) <= 1000),
    message_type TEXT NOT NULL CHECK (char_length(message_type) <= 1000),
    role TEXT NOT NULL CHECK (char_length(role) <= 1000),
    sequence_number INT NOT NULL,
    active BOOLEAN NOT NULL DEFAULT true,
    image_paths TEXT[] NOT NULL, -- file paths in message_images bucket

    -- OPTIONAL
    name TEXT,  -- Optional, used only for user and assistant names
    content TEXT,  -- Optional, standard message content
    tool_calls JSONB,  -- For storing structured data related to tool calls
    tool_call_id TEXT,  -- Optional, used only for ToolResponseMessage

    -- CONSTRAINTS
    CONSTRAINT check_image_paths_length CHECK (array_length(image_paths, 1) <= 16)
);

-- RLS --

ALTER TABLE backend_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow full access to own messages"
    ON backend_messages
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Allow view access to messages for non-private chats"
    ON backend_messages
    FOR SELECT
    USING (chat_id IN (
        SELECT id FROM chats WHERE sharing <> 'private'
    ));

-- FUNCTIONS --

CREATE OR REPLACE FUNCTION send_message_to_user(
    p_chat_id UUID,
    p_user_id UUID,
    p_model TEXT,
    p_process_name TEXT,
    p_message_type TEXT,
    p_role TEXT,
    p_image_paths TEXT[] DEFAULT '{}',
    p_name TEXT DEFAULT NULL,
    p_content TEXT DEFAULT NULL,
    p_tool_calls JSONB DEFAULT NULL,
    p_tool_call_id TEXT DEFAULT NULL
)
RETURNS TABLE(returned_id UUID, returned_created_at TIMESTAMPTZ) AS $$
DECLARE
  _sequence_number INT;
  _id UUID;
  _created_at TIMESTAMPTZ;
BEGIN
  SELECT COALESCE(MAX(sequence_number), 0) + 1 INTO _sequence_number FROM backend_messages WHERE chat_id = p_chat_id;

  INSERT INTO backend_messages (chat_id, user_id, model, process_name, message_type, role, image_paths, sequence_number, name, content, tool_calls, tool_call_id, active)
  VALUES (p_chat_id, p_user_id, p_model, p_process_name, p_message_type, p_role, p_image_paths, _sequence_number, p_name, p_content, p_tool_calls, p_tool_call_id, TRUE)
  RETURNING id, created_at INTO _id, _created_at;

  returned_id := _id;
  returned_created_at := _created_at;
  RETURN NEXT;
END;
$$ LANGUAGE plpgsql;

--------------- FRONTEND MESSAGES ---------------

-- TABLE --

CREATE TABLE IF NOT EXISTS frontend_messages (
    -- ID
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- RELATIONSHIPS
    chat_id UUID NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- METADATA
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ,

    -- REQUIRED
    model TEXT NOT NULL CHECK (char_length(model) <= 1000),
    process_name TEXT NOT NULL CHECK (char_length(process_name) <= 1000),
    message_type TEXT NOT NULL CHECK (char_length(message_type) <= 1000),
    role TEXT NOT NULL CHECK (char_length(role) <= 1000),
    sequence_number INT NOT NULL,
    active BOOLEAN NOT NULL DEFAULT true,
    image_paths TEXT[] NOT NULL, -- file paths in message_images bucket

    -- OPTIONAL
    name TEXT,  -- Optional, used only for user and assistant names
    content TEXT,  -- Optional, standard message content
    tool_calls JSONB,  -- For storing structured data related to tool calls
    tool_call_id TEXT  -- Optional, used only for ToolResponseMessage

    -- CONSTRAINTS
    CONSTRAINT check_image_paths_length CHECK (array_length(image_paths, 1) <= 16)
);

-- RLS --

ALTER TABLE frontend_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow full access to own messages"
    ON frontend_messages
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Allow view access to messages for non-private chats"
    ON frontend_messages
    FOR SELECT
    USING (chat_id IN (
        SELECT id FROM chats WHERE sharing <> 'private'
    ));

-- FUNCTIONS --
CREATE OR REPLACE FUNCTION send_message_to_assistant(
    p_chat_id UUID,
    p_user_id UUID,
    p_model TEXT,
    p_process_name TEXT,
    p_message_type TEXT,
    p_role TEXT,
    p_image_paths TEXT[] DEFAULT '{}',
    p_name TEXT DEFAULT NULL,
    p_content TEXT DEFAULT NULL,
    p_tool_calls JSONB DEFAULT NULL,
    p_tool_call_id UUID DEFAULT NULL
)
RETURNS TABLE(returned_id UUID, returned_created_at TIMESTAMPTZ) AS $$
DECLARE
  _sequence_number INT;
  _id UUID;
  _created_at TIMESTAMPTZ;
BEGIN
  SELECT COALESCE(MAX(sequence_number), 0) + 1 INTO _sequence_number FROM frontend_messages WHERE chat_id = p_chat_id;

  INSERT INTO frontend_messages (chat_id, user_id, model, process_name, message_type, role, image_paths, sequence_number, name, content, tool_calls, tool_call_id, active)
  VALUES (p_chat_id, p_user_id, p_model, p_process_name, p_message_type, p_role, p_image_paths, _sequence_number, p_name, p_content, p_tool_calls, p_tool_call_id, TRUE)
  RETURNING id, created_at INTO _id, _created_at;

  returned_id := _id;
  returned_created_at := _created_at;
  RETURN NEXT;
END;
$$ LANGUAGE plpgsql;

--------------- UI MESSAGES ---------------

-- TABLE --

CREATE TABLE IF NOT EXISTS ui_messages (
    -- ID
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- RELATIONSHIPS
    chat_id UUID NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- METADATA
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ,

    -- REQUIRED
    model TEXT NOT NULL CHECK (char_length(model) <= 1000),
    process_name TEXT NOT NULL CHECK (char_length(process_name) <= 1000),
    message_type TEXT NOT NULL CHECK (char_length(message_type) <= 1000),
    role TEXT NOT NULL CHECK (char_length(role) <= 1000),
    sequence_number INT NOT NULL,
    active BOOLEAN NOT NULL DEFAULT true,
    image_paths TEXT[] NOT NULL, -- file paths in message_images bucket

    -- OPTIONAL
    name TEXT,  -- Optional, used only for user and assistant names
    content TEXT,  -- Optional, standard message content
    tool_calls JSONB,  -- For storing structured data related to tool calls
    tool_call_id TEXT  -- Optional, used only for ToolResponseMessage

    -- CONSTRAINTS
    CONSTRAINT check_image_paths_length CHECK (array_length(image_paths, 1) <= 16)
);

-- INDEXES --

CREATE INDEX idx_ui_messages_chat_id ON ui_messages (chat_id);

-- RLS --

ALTER TABLE ui_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow full access to own ui_messages"
    ON ui_messages
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Allow view access to ui_messages for non-private chats"
    ON ui_messages
    FOR SELECT
    USING (chat_id IN (
        SELECT id FROM chats WHERE sharing <> 'private'
    ));

-- FUNCTIONS --

CREATE OR REPLACE FUNCTION insert_new_ui_message(
    p_chat_id UUID,
    p_user_id UUID,
    p_model TEXT,
    p_process_name TEXT,
    p_message_type TEXT,
    p_role TEXT,
    p_image_paths TEXT[] DEFAULT '{}',
    p_name TEXT DEFAULT NULL,
    p_content TEXT DEFAULT NULL,
    p_tool_calls JSONB DEFAULT NULL,
    p_tool_call_id TEXT DEFAULT NULL
)
RETURNS SETOF ui_messages AS $$
DECLARE
  _sequence_number INT;
BEGIN
  SELECT COALESCE(MAX(sequence_number), 0) + 1 INTO _sequence_number FROM ui_messages WHERE chat_id = p_chat_id;

  RETURN QUERY INSERT INTO ui_messages (
      chat_id, 
      user_id, 
      model, 
      process_name, 
      message_type, 
      role, 
      image_paths, 
      sequence_number, 
      name, 
      content, 
      tool_calls, 
      tool_call_id, 
      active
  )
  VALUES (
      p_chat_id, 
      p_user_id, 
      p_model, 
      p_process_name, 
      p_message_type, 
      p_role, 
      p_image_paths, 
      _sequence_number, 
      p_name, 
      p_content, 
      p_tool_calls, 
      p_tool_call_id, 
      TRUE
  )
  RETURNING *;
END;
$$ LANGUAGE plpgsql;

--------------- MESSAGE FILE ITEMS ---------------

-- TABLE --

CREATE TABLE IF NOT EXISTS message_file_items (
    -- REQUIRED RELATIONSHIPS
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    message_id UUID NOT NULL REFERENCES ui_messages(id) ON DELETE CASCADE,
    file_item_id UUID NOT NULL REFERENCES file_items(id) ON DELETE CASCADE,

    PRIMARY KEY(message_id, file_item_id),

    -- METADATA
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ
);

-- INDEXES --

CREATE INDEX idx_message_file_items_message_id ON message_file_items (message_id);

-- RLS --

ALTER TABLE message_file_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow full access to own message_file_items"
    ON message_file_items
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- TRIGGERS --

CREATE TRIGGER update_message_file_items_updated_at
BEFORE UPDATE ON message_file_items 
FOR EACH ROW 
EXECUTE PROCEDURE update_updated_at_column();

--- TODO CHECK IF WE NEED THESE FUNCTIONS ---

CREATE OR REPLACE FUNCTION delete_old_message_images()
RETURNS TRIGGER
LANGUAGE 'plpgsql'
SECURITY DEFINER
AS $$
DECLARE
  status INT;
  content TEXT;
  image_path TEXT;
BEGIN
  IF TG_OP = 'DELETE' THEN
    FOREACH image_path IN ARRAY OLD.image_paths
    LOOP
      SELECT
        INTO status, content
        result.status, result.content
        FROM public.delete_storage_object_from_bucket('message_images', image_path) AS result;
      IF status <> 200 THEN
        RAISE WARNING 'Could not delete message image: % %', status, content;
      END IF;
    END LOOP;
  END IF;
  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION delete_messages_including_and_after(
    p_user_id UUID, 
    p_chat_id UUID, 
    p_sequence_number INT
)
RETURNS VOID AS $$
BEGIN
    DELETE FROM ui_messages 
    WHERE user_id = p_user_id AND chat_id = p_chat_id AND sequence_number >= p_sequence_number;
END;
$$ LANGUAGE plpgsql;

-- TRIGGERS --

CREATE TRIGGER update_messages_updated_at
BEFORE UPDATE ON ui_messages
FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER delete_old_message_images
AFTER DELETE ON ui_messages
FOR EACH ROW
EXECUTE PROCEDURE delete_old_message_images();

-- STORAGE --

-- MESSAGE IMAGES

INSERT INTO storage.buckets (id, name, public) VALUES ('message_images', 'message_images', false);

CREATE POLICY "Allow read access to own message images"
    ON storage.objects FOR SELECT
    USING (
        bucket_id = 'message_images' AND 
        (
            (storage.foldername(name))[1] = auth.uid()::text OR
            (
                EXISTS (
                    SELECT 1 FROM chats 
                    WHERE id = (
                        SELECT chat_id FROM ui_messages WHERE id = (storage.foldername(name))[2]::uuid
                    ) AND sharing <> 'private'
                )
            )
        )
    );

CREATE POLICY "Allow insert access to own message images"
    ON storage.objects FOR INSERT
    WITH CHECK (bucket_id = 'message_images' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "Allow update access to own message images"
    ON storage.objects FOR UPDATE
    USING (bucket_id = 'message_images' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "Allow delete access to own message images"
    ON storage.objects FOR DELETE
    USING (bucket_id = 'message_images' AND (storage.foldername(name))[1] = auth.uid()::text);