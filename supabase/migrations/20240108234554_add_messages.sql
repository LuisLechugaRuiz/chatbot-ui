--------------- MESSAGES ---------------

-- TABLE --

CREATE TABLE IF NOT EXISTS messages (
    -- ID
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- RELATIONSHIPS
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    process_id UUID NOT NULL REFERENCES processes(id) ON DELETE CASCADE,

    -- METADATA
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ,

    -- REQUIRED
    model TEXT NOT NULL CHECK (char_length(model) <= 1000),
    message_type TEXT NOT NULL CHECK (char_length(message_type) <= 1000),
    role TEXT NOT NULL CHECK (char_length(role) <= 1000),
    sequence_number INT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    on_buffer BOOLEAN NOT NULL DEFAULT true,
    image_paths TEXT[] NOT NULL, -- file paths in message_images bucket -- Remove, check how to send images to the model properly ---

    -- OPTIONAL
    name TEXT,  -- Optional, used only for user and assistant names
    content TEXT,  -- Optional, standard message content
    tool_calls JSONB,  -- For storing structured data related to tool calls
    tool_call_id TEXT  -- Optional, used only for ToolResponseMessage

    -- CONSTRAINTS
    CONSTRAINT check_image_paths_length CHECK (array_length(image_paths, 1) <= 16)
);

-- INDEXES --

CREATE INDEX idx_messages_user_id ON messages (user_id);

-- RLS --

ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow full access to own messages"
    ON messages 
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- FUNCTIONS --

CREATE OR REPLACE FUNCTION insert_new_message(
    p_user_id UUID,
    p_process_id UUID,
    p_model TEXT,
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
  SELECT COALESCE(MAX(sequence_number), 0) + 1 INTO _sequence_number FROM messages WHERE process_id = p_process_id;

  RETURN QUERY INSERT INTO messages (
      user_id,
      process_id,
      model,
      message_type,
      role,
      image_paths,
      sequence_number,
      name,
      content,
      tool_calls,
      tool_call_id,
      is_active,
      on_buffer
  )
  VALUES (
      p_user_id,
      p_process_id, 
      p_model,
      p_message_type,
      p_role,
      p_image_paths,
      _sequence_number,
      p_name,
      p_content,
      p_tool_calls,
      p_tool_call_id,
      TRUE,
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


CREATE OR REPLACE FUNCTION get_active_messages(p_process_id UUID)
RETURNS TABLE(
    id UUID,
    user_id UUID,
    process_id UUID,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    model TEXT,
    message_type TEXT,
    role TEXT,
    sequence_number INT,
    name TEXT,
    content TEXT,
    tool_calls JSONB,
    tool_call_id UUID,
    is_active BOOLEAN,
    on_buffer BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        messages.id,
        messages.user_id,
        messages.process_id,
        messages.created_at,
        messages.updated_at,
        messages.model,
        messages.message_type AS type,
        messages.role,
        messages.sequence_number,
        messages.name,
        messages.content,
        messages.tool_calls,
        messages.tool_call_id,
        messages.is_active,
        messages.on_buffer
    FROM messages
    WHERE messages.process_id = p_process_id AND messages.is_active = TRUE
    ORDER BY messages.sequence_number ASC;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION get_buffered_messages(p_process_id UUID)
RETURNS TABLE(
    id UUID,
    user_id UUID,
    process_id UUID,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    model TEXT,
    message_type TEXT,
    role TEXT,
    sequence_number INT,
    name TEXT,
    content TEXT,
    tool_calls JSONB,
    tool_call_id UUID,
    is_active BOOLEAN,
    on_buffer BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        messages.id,
        messages.user_id,
        messages.process_id,
        messages.created_at,
        messages.updated_at,
        messages.model,
        messages.message_type AS type,
        messages.role,
        messages.sequence_number,
        messages.name,
        messages.content,
        messages.tool_calls,
        messages.tool_call_id,
        messages.is_active,
        messages.on_buffer
    FROM messages
    WHERE messages.process_id = p_process_id AND messages.on_buffer = TRUE
    ORDER BY messages.sequence_number ASC;
END;
$$ LANGUAGE plpgsql;

--------------- BACKEND MESSAGES ---------------

-- TABLE --

CREATE TABLE IF NOT EXISTS backend_messages (
    -- ID
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- RELATIONSHIPS
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    process_id UUID NOT NULL REFERENCES processes(id) ON DELETE CASCADE,

    -- METADATA
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ,

    -- REQUIRED
    model TEXT NOT NULL CHECK (char_length(model) <= 1000),
    message_type TEXT NOT NULL CHECK (char_length(message_type) <= 1000),
    role TEXT NOT NULL CHECK (char_length(role) <= 1000),
    sequence_number INT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    on_buffer BOOLEAN NOT NULL DEFAULT true,
    image_paths TEXT[] NOT NULL, -- file paths in message_images bucket -- Remove, check how to send images to the model properly ---

    -- OPTIONAL
    name TEXT,  -- Optional, used only for user and assistant names
    content TEXT,  -- Optional, standard message content
    tool_calls JSONB,  -- For storing structured data related to tool calls
    tool_call_id TEXT  -- Optional, used only for ToolResponseMessage

    -- CONSTRAINTS
    CONSTRAINT check_image_paths_length CHECK (array_length(image_paths, 1) <= 16)
);

-- RLS --

ALTER TABLE backend_messages ENABLE ROW LEVEL SECURITY;

create policy "Allow select for anon" on backend_messages for select using (true);

-- FUNCTIONS --

CREATE OR REPLACE FUNCTION send_message_to_user(
    p_user_id UUID,
    p_process_id UUID,
    p_model TEXT,
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
  SELECT COALESCE(MAX(sequence_number), 0) + 1 INTO _sequence_number FROM backend_messages WHERE process_id = p_process_id;

  INSERT INTO backend_messages (user_id, process_id, model, message_type, role, image_paths, sequence_number, name, content, tool_calls, tool_call_id, is_active, on_buffer)
  VALUES (p_user_id, p_process_id, p_model, p_message_type, p_role, p_image_paths, _sequence_number, p_name, p_content, p_tool_calls, p_tool_call_id, TRUE, TRUE)
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
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    process_id UUID NOT NULL REFERENCES processes(id) ON DELETE CASCADE,

    -- METADATA
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ,

    -- REQUIRED
    model TEXT NOT NULL CHECK (char_length(model) <= 1000),
    message_type TEXT NOT NULL CHECK (char_length(message_type) <= 1000),
    role TEXT NOT NULL CHECK (char_length(role) <= 1000),
    sequence_number INT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    on_buffer BOOLEAN NOT NULL DEFAULT true,
    image_paths TEXT[] NOT NULL, -- file paths in message_images bucket -- Remove, check how to send images to the model properly ---

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

-- FUNCTIONS --
CREATE OR REPLACE FUNCTION send_message_to_assistant(
    p_user_id UUID,
    p_process_id UUID,
    p_model TEXT,
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
  SELECT COALESCE(MAX(sequence_number), 0) + 1 INTO _sequence_number FROM frontend_messages WHERE process_id = p_process_id;

  INSERT INTO frontend_messages (user_id, process_id, model, message_type, role, image_paths, sequence_number, name, content, tool_calls, tool_call_id, is_active, on_buffer)
  VALUES (p_user_id, p_process_id, p_model, p_message_type, p_role, p_image_paths, _sequence_number, p_name, p_content, p_tool_calls, p_tool_call_id, TRUE, TRUE)
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
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    process_id UUID NOT NULL REFERENCES processes(id) ON DELETE CASCADE,

    -- METADATA
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ,

    -- REQUIRED
    model TEXT NOT NULL CHECK (char_length(model) <= 1000),
    message_type TEXT NOT NULL CHECK (char_length(message_type) <= 1000),
    role TEXT NOT NULL CHECK (char_length(role) <= 1000),
    sequence_number INT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    on_buffer BOOLEAN NOT NULL DEFAULT true,
    image_paths TEXT[] NOT NULL, -- file paths in message_images bucket -- Remove, check how to send images to the model properly ---

    -- OPTIONAL
    name TEXT,  -- Optional, used only for user and assistant names
    content TEXT,  -- Optional, standard message content
    tool_calls JSONB,  -- For storing structured data related to tool calls
    tool_call_id TEXT  -- Optional, used only for ToolResponseMessage

    -- CONSTRAINTS
    CONSTRAINT check_image_paths_length CHECK (array_length(image_paths, 1) <= 16)
);

-- INDEXES --

CREATE INDEX idx_ui_messages_user_id ON ui_messages (user_id);

-- RLS --

ALTER TABLE ui_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow full access to own ui_messages"
    ON ui_messages
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- FUNCTIONS --

CREATE OR REPLACE FUNCTION insert_new_ui_message(
    p_user_id UUID,
    p_process_id UUID,
    p_model TEXT,
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
  SELECT COALESCE(MAX(sequence_number), 0) + 1 INTO _sequence_number FROM ui_messages WHERE process_id = p_process_id;

  RETURN QUERY INSERT INTO ui_messages (
      user_id,
      process_id,
      model,
      message_type,
      role,
      image_paths,
      sequence_number,
      name,
      content,
      tool_calls,
      tool_call_id,
      is_active,
      on_buffer
  )
  VALUES ( 
      p_user_id,
      p_process_id,
      p_model,
      p_message_type,
      p_role,
      p_image_paths,
      _sequence_number,
      p_name,
      p_content,
      p_tool_calls,
      p_tool_call_id,
      TRUE,
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

--- TODO: Remove this messages, it should only affect visualization ---
CREATE OR REPLACE FUNCTION delete_messages_including_and_after(
    p_user_id UUID,
    p_sequence_number INT
)
RETURNS VOID AS $$
BEGIN
    DELETE FROM ui_messages 
    WHERE user_id = p_user_id AND sequence_number >= p_sequence_number;
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
    USING (bucket_id = 'message_images' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "Allow insert access to own message images"
    ON storage.objects FOR INSERT
    WITH CHECK (bucket_id = 'message_images' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "Allow update access to own message images"
    ON storage.objects FOR UPDATE
    USING (bucket_id = 'message_images' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "Allow delete access to own message images"
    ON storage.objects FOR DELETE
    USING (bucket_id = 'message_images' AND (storage.foldername(name))[1] = auth.uid()::text);