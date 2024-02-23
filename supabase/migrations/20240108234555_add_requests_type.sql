--------------- REQUEST TYPES ---------------

-- TABLE --

CREATE TABLE IF NOT EXISTS request_types (
    -- ID
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- METADATA
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ,

    -- REQUIRED
    name TEXT NOT NULL CHECK (char_length(name) <= 100),
    request_message_type JSONB NOT NULL, -- TODO: Is this the right name? maybe request_format?
    response_message_type JSONB NOT NULL -- TODO: Is this the right name? maybe response_format?
);

-- INDEXES --

CREATE INDEX request_types_id_idx ON request_types(user_id);

-- RLS --

ALTER TABLE services ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow full access to own services"
    ON request_types
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());