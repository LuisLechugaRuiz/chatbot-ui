export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export interface Database {
  graphql_public: {
    Tables: {
      [_ in never]: never
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      graphql: {
        Args: {
          operationName?: string
          query?: string
          variables?: Json
          extensions?: Json
        }
        Returns: Json
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  public: {
    Tables: {
      agents: {
        Row: {
          context: string
          created_at: string
          id: string
          instructions: string
          is_active: boolean
          name: string
          state: string
          task: string
          thought_generator_mode: string
          tools_class: string
          updated_at: string | null
          user_id: string
        }
        Insert: {
          context?: string
          created_at?: string
          id?: string
          instructions: string
          is_active?: boolean
          name: string
          state?: string
          task: string
          thought_generator_mode?: string
          tools_class: string
          updated_at?: string | null
          user_id: string
        }
        Update: {
          context?: string
          created_at?: string
          id?: string
          instructions?: string
          is_active?: boolean
          name?: string
          state?: string
          task?: string
          thought_generator_mode?: string
          tools_class?: string
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "agents_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      assistant_workspaces: {
        Row: {
          assistant_id: string
          created_at: string
          updated_at: string | null
          user_id: string
          workspace_id: string
        }
        Insert: {
          assistant_id: string
          created_at?: string
          updated_at?: string | null
          user_id: string
          workspace_id: string
        }
        Update: {
          assistant_id?: string
          created_at?: string
          updated_at?: string | null
          user_id?: string
          workspace_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "assistant_workspaces_assistant_id_fkey"
            columns: ["assistant_id"]
            isOneToOne: false
            referencedRelation: "assistants"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "assistant_workspaces_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "assistant_workspaces_workspace_id_fkey"
            columns: ["workspace_id"]
            isOneToOne: false
            referencedRelation: "workspaces"
            referencedColumns: ["id"]
          }
        ]
      }
      assistants: {
        Row: {
          context_length: number
          created_at: string
          description: string
          embeddings_provider: string
          folder_id: string | null
          id: string
          image_path: string
          include_profile_context: boolean
          include_workspace_instructions: boolean
          model: string
          name: string
          prompt: string
          sharing: string
          temperature: number
          updated_at: string | null
          user_id: string
        }
        Insert: {
          context_length: number
          created_at?: string
          description: string
          embeddings_provider: string
          folder_id?: string | null
          id?: string
          image_path: string
          include_profile_context: boolean
          include_workspace_instructions: boolean
          model: string
          name: string
          prompt: string
          sharing?: string
          temperature: number
          updated_at?: string | null
          user_id: string
        }
        Update: {
          context_length?: number
          created_at?: string
          description?: string
          embeddings_provider?: string
          folder_id?: string | null
          id?: string
          image_path?: string
          include_profile_context?: boolean
          include_workspace_instructions?: boolean
          model?: string
          name?: string
          prompt?: string
          sharing?: string
          temperature?: number
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "assistants_folder_id_fkey"
            columns: ["folder_id"]
            isOneToOne: false
            referencedRelation: "folders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "assistants_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      backend_messages: {
        Row: {
          content: string | null
          created_at: string
          id: string
          image_paths: string[]
          is_active: boolean
          message_type: string
          model: string
          name: string | null
          on_buffer: boolean
          process_id: string
          role: string
          sequence_number: number
          tool_call_id: string | null
          tool_calls: Json | null
          updated_at: string | null
          user_id: string
        }
        Insert: {
          content?: string | null
          created_at?: string
          id?: string
          image_paths: string[]
          is_active?: boolean
          message_type: string
          model: string
          name?: string | null
          on_buffer?: boolean
          process_id: string
          role: string
          sequence_number: number
          tool_call_id?: string | null
          tool_calls?: Json | null
          updated_at?: string | null
          user_id: string
        }
        Update: {
          content?: string | null
          created_at?: string
          id?: string
          image_paths?: string[]
          is_active?: boolean
          message_type?: string
          model?: string
          name?: string | null
          on_buffer?: boolean
          process_id?: string
          role?: string
          sequence_number?: number
          tool_call_id?: string | null
          tool_calls?: Json | null
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "backend_messages_process_id_fkey"
            columns: ["process_id"]
            isOneToOne: false
            referencedRelation: "processes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "backend_messages_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      chat_files: {
        Row: {
          chat_id: string
          created_at: string
          file_id: string
          updated_at: string | null
          user_id: string
        }
        Insert: {
          chat_id: string
          created_at?: string
          file_id: string
          updated_at?: string | null
          user_id: string
        }
        Update: {
          chat_id?: string
          created_at?: string
          file_id?: string
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "chat_files_chat_id_fkey"
            columns: ["chat_id"]
            isOneToOne: false
            referencedRelation: "chats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chat_files_file_id_fkey"
            columns: ["file_id"]
            isOneToOne: false
            referencedRelation: "files"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chat_files_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      chats: {
        Row: {
          assistant_id: string | null
          context_length: number
          created_at: string
          embeddings_provider: string
          folder_id: string | null
          id: string
          include_profile_context: boolean
          include_workspace_instructions: boolean
          model: string
          name: string
          process_id: string
          prompt: string
          sharing: string
          temperature: number
          updated_at: string | null
          user_id: string
          workspace_id: string
        }
        Insert: {
          assistant_id?: string | null
          context_length: number
          created_at?: string
          embeddings_provider: string
          folder_id?: string | null
          id?: string
          include_profile_context: boolean
          include_workspace_instructions: boolean
          model: string
          name: string
          process_id: string
          prompt: string
          sharing?: string
          temperature: number
          updated_at?: string | null
          user_id: string
          workspace_id: string
        }
        Update: {
          assistant_id?: string | null
          context_length?: number
          created_at?: string
          embeddings_provider?: string
          folder_id?: string | null
          id?: string
          include_profile_context?: boolean
          include_workspace_instructions?: boolean
          model?: string
          name?: string
          process_id?: string
          prompt?: string
          sharing?: string
          temperature?: number
          updated_at?: string | null
          user_id?: string
          workspace_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "chats_assistant_id_fkey"
            columns: ["assistant_id"]
            isOneToOne: false
            referencedRelation: "assistants"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chats_folder_id_fkey"
            columns: ["folder_id"]
            isOneToOne: false
            referencedRelation: "folders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chats_process_id_fkey"
            columns: ["process_id"]
            isOneToOne: false
            referencedRelation: "processes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chats_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chats_workspace_id_fkey"
            columns: ["workspace_id"]
            isOneToOne: false
            referencedRelation: "workspaces"
            referencedColumns: ["id"]
          }
        ]
      }
      collection_files: {
        Row: {
          collection_id: string
          created_at: string
          file_id: string
          updated_at: string | null
          user_id: string
        }
        Insert: {
          collection_id: string
          created_at?: string
          file_id: string
          updated_at?: string | null
          user_id: string
        }
        Update: {
          collection_id?: string
          created_at?: string
          file_id?: string
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "collection_files_collection_id_fkey"
            columns: ["collection_id"]
            isOneToOne: false
            referencedRelation: "collections"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "collection_files_file_id_fkey"
            columns: ["file_id"]
            isOneToOne: false
            referencedRelation: "files"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "collection_files_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      collection_workspaces: {
        Row: {
          collection_id: string
          created_at: string
          updated_at: string | null
          user_id: string
          workspace_id: string
        }
        Insert: {
          collection_id: string
          created_at?: string
          updated_at?: string | null
          user_id: string
          workspace_id: string
        }
        Update: {
          collection_id?: string
          created_at?: string
          updated_at?: string | null
          user_id?: string
          workspace_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "collection_workspaces_collection_id_fkey"
            columns: ["collection_id"]
            isOneToOne: false
            referencedRelation: "collections"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "collection_workspaces_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "collection_workspaces_workspace_id_fkey"
            columns: ["workspace_id"]
            isOneToOne: false
            referencedRelation: "workspaces"
            referencedColumns: ["id"]
          }
        ]
      }
      collections: {
        Row: {
          created_at: string
          description: string
          folder_id: string | null
          id: string
          name: string
          sharing: string
          updated_at: string | null
          user_id: string
        }
        Insert: {
          created_at?: string
          description: string
          folder_id?: string | null
          id?: string
          name: string
          sharing?: string
          updated_at?: string | null
          user_id: string
        }
        Update: {
          created_at?: string
          description?: string
          folder_id?: string | null
          id?: string
          name?: string
          sharing?: string
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "collections_folder_id_fkey"
            columns: ["folder_id"]
            isOneToOne: false
            referencedRelation: "folders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "collections_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      event_types: {
        Row: {
          created_at: string
          description: string
          id: string
          name: string
          updated_at: string | null
          user_id: string
        }
        Insert: {
          created_at?: string
          description: string
          id?: string
          name: string
          updated_at?: string | null
          user_id: string
        }
        Update: {
          created_at?: string
          description?: string
          id?: string
          name?: string
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "event_types_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      events: {
        Row: {
          content: string
          created_at: string
          event_type_id: string
          id: string
          message_name: string
          status: string
          updated_at: string | null
          user_id: string
        }
        Insert: {
          content: string
          created_at?: string
          event_type_id: string
          id?: string
          message_name: string
          status?: string
          updated_at?: string | null
          user_id: string
        }
        Update: {
          content?: string
          created_at?: string
          event_type_id?: string
          id?: string
          message_name?: string
          status?: string
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "events_event_type_id_fkey"
            columns: ["event_type_id"]
            isOneToOne: false
            referencedRelation: "event_types"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "events_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      file_items: {
        Row: {
          content: string
          created_at: string
          file_id: string
          id: string
          local_embedding: string | null
          openai_embedding: string | null
          sharing: string
          tokens: number
          updated_at: string | null
          user_id: string
        }
        Insert: {
          content: string
          created_at?: string
          file_id: string
          id?: string
          local_embedding?: string | null
          openai_embedding?: string | null
          sharing?: string
          tokens: number
          updated_at?: string | null
          user_id: string
        }
        Update: {
          content?: string
          created_at?: string
          file_id?: string
          id?: string
          local_embedding?: string | null
          openai_embedding?: string | null
          sharing?: string
          tokens?: number
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "file_items_file_id_fkey"
            columns: ["file_id"]
            isOneToOne: false
            referencedRelation: "files"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "file_items_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      file_workspaces: {
        Row: {
          created_at: string
          file_id: string
          updated_at: string | null
          user_id: string
          workspace_id: string
        }
        Insert: {
          created_at?: string
          file_id: string
          updated_at?: string | null
          user_id: string
          workspace_id: string
        }
        Update: {
          created_at?: string
          file_id?: string
          updated_at?: string | null
          user_id?: string
          workspace_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "file_workspaces_file_id_fkey"
            columns: ["file_id"]
            isOneToOne: false
            referencedRelation: "files"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "file_workspaces_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "file_workspaces_workspace_id_fkey"
            columns: ["workspace_id"]
            isOneToOne: false
            referencedRelation: "workspaces"
            referencedColumns: ["id"]
          }
        ]
      }
      files: {
        Row: {
          created_at: string
          description: string
          file_path: string
          folder_id: string | null
          id: string
          name: string
          sharing: string
          size: number
          tokens: number
          type: string
          updated_at: string | null
          user_id: string
        }
        Insert: {
          created_at?: string
          description: string
          file_path: string
          folder_id?: string | null
          id?: string
          name: string
          sharing?: string
          size: number
          tokens: number
          type: string
          updated_at?: string | null
          user_id: string
        }
        Update: {
          created_at?: string
          description?: string
          file_path?: string
          folder_id?: string | null
          id?: string
          name?: string
          sharing?: string
          size?: number
          tokens?: number
          type?: string
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "files_folder_id_fkey"
            columns: ["folder_id"]
            isOneToOne: false
            referencedRelation: "folders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "files_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      folders: {
        Row: {
          created_at: string
          description: string
          id: string
          name: string
          type: string
          updated_at: string | null
          user_id: string
          workspace_id: string
        }
        Insert: {
          created_at?: string
          description: string
          id?: string
          name: string
          type: string
          updated_at?: string | null
          user_id: string
          workspace_id: string
        }
        Update: {
          created_at?: string
          description?: string
          id?: string
          name?: string
          type?: string
          updated_at?: string | null
          user_id?: string
          workspace_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "folders_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "folders_workspace_id_fkey"
            columns: ["workspace_id"]
            isOneToOne: false
            referencedRelation: "workspaces"
            referencedColumns: ["id"]
          }
        ]
      }
      frontend_messages: {
        Row: {
          content: string | null
          created_at: string
          id: string
          image_paths: string[]
          is_active: boolean
          message_type: string
          model: string
          name: string | null
          on_buffer: boolean
          process_id: string
          role: string
          sequence_number: number
          tool_call_id: string | null
          tool_calls: Json | null
          updated_at: string | null
          user_id: string
        }
        Insert: {
          content?: string | null
          created_at?: string
          id?: string
          image_paths: string[]
          is_active?: boolean
          message_type: string
          model: string
          name?: string | null
          on_buffer?: boolean
          process_id: string
          role: string
          sequence_number: number
          tool_call_id?: string | null
          tool_calls?: Json | null
          updated_at?: string | null
          user_id: string
        }
        Update: {
          content?: string | null
          created_at?: string
          id?: string
          image_paths?: string[]
          is_active?: boolean
          message_type?: string
          model?: string
          name?: string | null
          on_buffer?: boolean
          process_id?: string
          role?: string
          sequence_number?: number
          tool_call_id?: string | null
          tool_calls?: Json | null
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "frontend_messages_process_id_fkey"
            columns: ["process_id"]
            isOneToOne: false
            referencedRelation: "processes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "frontend_messages_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      message_file_items: {
        Row: {
          created_at: string
          file_item_id: string
          message_id: string
          updated_at: string | null
          user_id: string
        }
        Insert: {
          created_at?: string
          file_item_id: string
          message_id: string
          updated_at?: string | null
          user_id: string
        }
        Update: {
          created_at?: string
          file_item_id?: string
          message_id?: string
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "message_file_items_file_item_id_fkey"
            columns: ["file_item_id"]
            isOneToOne: false
            referencedRelation: "file_items"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "message_file_items_message_id_fkey"
            columns: ["message_id"]
            isOneToOne: false
            referencedRelation: "ui_messages"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "message_file_items_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      messages: {
        Row: {
          content: string | null
          created_at: string
          id: string
          image_paths: string[]
          is_active: boolean
          message_type: string
          model: string
          name: string | null
          on_buffer: boolean
          process_id: string
          role: string
          sequence_number: number
          tool_call_id: string | null
          tool_calls: Json | null
          updated_at: string | null
          user_id: string
        }
        Insert: {
          content?: string | null
          created_at?: string
          id?: string
          image_paths: string[]
          is_active?: boolean
          message_type: string
          model: string
          name?: string | null
          on_buffer?: boolean
          process_id: string
          role: string
          sequence_number: number
          tool_call_id?: string | null
          tool_calls?: Json | null
          updated_at?: string | null
          user_id: string
        }
        Update: {
          content?: string | null
          created_at?: string
          id?: string
          image_paths?: string[]
          is_active?: boolean
          message_type?: string
          model?: string
          name?: string | null
          on_buffer?: boolean
          process_id?: string
          role?: string
          sequence_number?: number
          tool_call_id?: string | null
          tool_calls?: Json | null
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "messages_process_id_fkey"
            columns: ["process_id"]
            isOneToOne: false
            referencedRelation: "processes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "messages_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      preset_workspaces: {
        Row: {
          created_at: string
          preset_id: string
          updated_at: string | null
          user_id: string
          workspace_id: string
        }
        Insert: {
          created_at?: string
          preset_id: string
          updated_at?: string | null
          user_id: string
          workspace_id: string
        }
        Update: {
          created_at?: string
          preset_id?: string
          updated_at?: string | null
          user_id?: string
          workspace_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "preset_workspaces_preset_id_fkey"
            columns: ["preset_id"]
            isOneToOne: false
            referencedRelation: "presets"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "preset_workspaces_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "preset_workspaces_workspace_id_fkey"
            columns: ["workspace_id"]
            isOneToOne: false
            referencedRelation: "workspaces"
            referencedColumns: ["id"]
          }
        ]
      }
      presets: {
        Row: {
          context_length: number
          created_at: string
          description: string
          embeddings_provider: string
          folder_id: string | null
          id: string
          include_profile_context: boolean
          include_workspace_instructions: boolean
          model: string
          name: string
          prompt: string
          sharing: string
          temperature: number
          updated_at: string | null
          user_id: string
        }
        Insert: {
          context_length: number
          created_at?: string
          description: string
          embeddings_provider: string
          folder_id?: string | null
          id?: string
          include_profile_context: boolean
          include_workspace_instructions: boolean
          model: string
          name: string
          prompt: string
          sharing?: string
          temperature: number
          updated_at?: string | null
          user_id: string
        }
        Update: {
          context_length?: number
          created_at?: string
          description?: string
          embeddings_provider?: string
          folder_id?: string | null
          id?: string
          include_profile_context?: boolean
          include_workspace_instructions?: boolean
          model?: string
          name?: string
          prompt?: string
          sharing?: string
          temperature?: number
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "presets_folder_id_fkey"
            columns: ["folder_id"]
            isOneToOne: false
            referencedRelation: "folders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "presets_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      processes: {
        Row: {
          agent_id: string | null
          created_at: string
          flow_type: string
          id: string
          instructions: string
          name: string
          task: string
          tools_class: string
          updated_at: string | null
          user_id: string
        }
        Insert: {
          agent_id?: string | null
          created_at?: string
          flow_type?: string
          id?: string
          instructions: string
          name: string
          task: string
          tools_class: string
          updated_at?: string | null
          user_id: string
        }
        Update: {
          agent_id?: string | null
          created_at?: string
          flow_type?: string
          id?: string
          instructions?: string
          name?: string
          task?: string
          tools_class?: string
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "processes_agent_id_fkey"
            columns: ["agent_id"]
            isOneToOne: false
            referencedRelation: "agents"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "processes_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      profiles: {
        Row: {
          anthropic_api_key: string | null
          azure_openai_35_turbo_id: string | null
          azure_openai_45_turbo_id: string | null
          azure_openai_45_vision_id: string | null
          azure_openai_api_key: string | null
          azure_openai_endpoint: string | null
          bio: string
          created_at: string
          display_name: string
          google_gemini_api_key: string | null
          has_onboarded: boolean
          id: string
          image_path: string
          image_url: string
          mistral_api_key: string | null
          openai_api_key: string | null
          openai_organization_id: string | null
          perplexity_api_key: string | null
          profile_context: string
          updated_at: string | null
          use_azure_openai: boolean
          user_id: string
          username: string
        }
        Insert: {
          anthropic_api_key?: string | null
          azure_openai_35_turbo_id?: string | null
          azure_openai_45_turbo_id?: string | null
          azure_openai_45_vision_id?: string | null
          azure_openai_api_key?: string | null
          azure_openai_endpoint?: string | null
          bio: string
          created_at?: string
          display_name: string
          google_gemini_api_key?: string | null
          has_onboarded?: boolean
          id?: string
          image_path: string
          image_url: string
          mistral_api_key?: string | null
          openai_api_key?: string | null
          openai_organization_id?: string | null
          perplexity_api_key?: string | null
          profile_context: string
          updated_at?: string | null
          use_azure_openai: boolean
          user_id: string
          username: string
        }
        Update: {
          anthropic_api_key?: string | null
          azure_openai_35_turbo_id?: string | null
          azure_openai_45_turbo_id?: string | null
          azure_openai_45_vision_id?: string | null
          azure_openai_api_key?: string | null
          azure_openai_endpoint?: string | null
          bio?: string
          created_at?: string
          display_name?: string
          google_gemini_api_key?: string | null
          has_onboarded?: boolean
          id?: string
          image_path?: string
          image_url?: string
          mistral_api_key?: string | null
          openai_api_key?: string | null
          openai_organization_id?: string | null
          perplexity_api_key?: string | null
          profile_context?: string
          updated_at?: string | null
          use_azure_openai?: boolean
          user_id?: string
          username?: string
        }
        Relationships: [
          {
            foreignKeyName: "profiles_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      prompt_workspaces: {
        Row: {
          created_at: string
          prompt_id: string
          updated_at: string | null
          user_id: string
          workspace_id: string
        }
        Insert: {
          created_at?: string
          prompt_id: string
          updated_at?: string | null
          user_id: string
          workspace_id: string
        }
        Update: {
          created_at?: string
          prompt_id?: string
          updated_at?: string | null
          user_id?: string
          workspace_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "prompt_workspaces_prompt_id_fkey"
            columns: ["prompt_id"]
            isOneToOne: false
            referencedRelation: "prompts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "prompt_workspaces_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "prompt_workspaces_workspace_id_fkey"
            columns: ["workspace_id"]
            isOneToOne: false
            referencedRelation: "workspaces"
            referencedColumns: ["id"]
          }
        ]
      }
      prompts: {
        Row: {
          content: string
          created_at: string
          folder_id: string | null
          id: string
          name: string
          sharing: string
          updated_at: string | null
          user_id: string
        }
        Insert: {
          content: string
          created_at?: string
          folder_id?: string | null
          id?: string
          name: string
          sharing?: string
          updated_at?: string | null
          user_id: string
        }
        Update: {
          content?: string
          created_at?: string
          folder_id?: string | null
          id?: string
          name?: string
          sharing?: string
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "prompts_folder_id_fkey"
            columns: ["folder_id"]
            isOneToOne: false
            referencedRelation: "folders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "prompts_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      requests: {
        Row: {
          client_process_id: string
          client_process_name: string
          created_at: string
          feedback: string
          id: string
          is_async: boolean
          query: string
          response: string
          service_id: string
          service_process_id: string
          status: string
          updated_at: string | null
          user_id: string
        }
        Insert: {
          client_process_id: string
          client_process_name: string
          created_at?: string
          feedback?: string
          id?: string
          is_async: boolean
          query: string
          response?: string
          service_id: string
          service_process_id: string
          status?: string
          updated_at?: string | null
          user_id: string
        }
        Update: {
          client_process_id?: string
          client_process_name?: string
          created_at?: string
          feedback?: string
          id?: string
          is_async?: boolean
          query?: string
          response?: string
          service_id?: string
          service_process_id?: string
          status?: string
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "requests_client_process_id_fkey"
            columns: ["client_process_id"]
            isOneToOne: false
            referencedRelation: "processes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "requests_service_id_fkey"
            columns: ["service_id"]
            isOneToOne: false
            referencedRelation: "services"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "requests_service_process_id_fkey"
            columns: ["service_process_id"]
            isOneToOne: false
            referencedRelation: "processes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "requests_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      services: {
        Row: {
          created_at: string
          description: string
          id: string
          name: string
          process_id: string
          updated_at: string | null
          user_id: string
        }
        Insert: {
          created_at?: string
          description: string
          id?: string
          name: string
          process_id: string
          updated_at?: string | null
          user_id: string
        }
        Update: {
          created_at?: string
          description?: string
          id?: string
          name?: string
          process_id?: string
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "services_process_id_fkey"
            columns: ["process_id"]
            isOneToOne: false
            referencedRelation: "processes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "services_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      subscribed_events: {
        Row: {
          event_type_id: string
          process_id: string
          user_id: string
        }
        Insert: {
          event_type_id: string
          process_id: string
          user_id: string
        }
        Update: {
          event_type_id?: string
          process_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "subscribed_events_event_type_id_fkey"
            columns: ["event_type_id"]
            isOneToOne: false
            referencedRelation: "event_types"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "subscribed_events_process_id_fkey"
            columns: ["process_id"]
            isOneToOne: false
            referencedRelation: "processes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "subscribed_events_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      subscribed_topics: {
        Row: {
          process_id: string
          topic_id: string
          user_id: string
        }
        Insert: {
          process_id: string
          topic_id: string
          user_id: string
        }
        Update: {
          process_id?: string
          topic_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "subscribed_topics_process_id_fkey"
            columns: ["process_id"]
            isOneToOne: false
            referencedRelation: "processes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "subscribed_topics_topic_id_fkey"
            columns: ["topic_id"]
            isOneToOne: false
            referencedRelation: "topics"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "subscribed_topics_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      topics: {
        Row: {
          content: string | null
          created_at: string
          description: string
          id: string
          name: string
          updated_at: string | null
          user_id: string
        }
        Insert: {
          content?: string | null
          created_at?: string
          description: string
          id?: string
          name: string
          updated_at?: string | null
          user_id: string
        }
        Update: {
          content?: string | null
          created_at?: string
          description?: string
          id?: string
          name?: string
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "topics_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      ui_messages: {
        Row: {
          content: string | null
          created_at: string
          id: string
          image_paths: string[]
          is_active: boolean
          message_type: string
          model: string
          name: string | null
          on_buffer: boolean
          process_id: string
          role: string
          sequence_number: number
          tool_call_id: string | null
          tool_calls: Json | null
          updated_at: string | null
          user_id: string
        }
        Insert: {
          content?: string | null
          created_at?: string
          id?: string
          image_paths: string[]
          is_active?: boolean
          message_type: string
          model: string
          name?: string | null
          on_buffer?: boolean
          process_id: string
          role: string
          sequence_number: number
          tool_call_id?: string | null
          tool_calls?: Json | null
          updated_at?: string | null
          user_id: string
        }
        Update: {
          content?: string | null
          created_at?: string
          id?: string
          image_paths?: string[]
          is_active?: boolean
          message_type?: string
          model?: string
          name?: string | null
          on_buffer?: boolean
          process_id?: string
          role?: string
          sequence_number?: number
          tool_call_id?: string | null
          tool_calls?: Json | null
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "ui_messages_process_id_fkey"
            columns: ["process_id"]
            isOneToOne: false
            referencedRelation: "processes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ui_messages_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      users_data: {
        Row: {
          api_key: string | null
          created_at: string
          id: string
          name: string
          updated_at: string | null
          user_id: string
        }
        Insert: {
          api_key?: string | null
          created_at?: string
          id?: string
          name: string
          updated_at?: string | null
          user_id: string
        }
        Update: {
          api_key?: string | null
          created_at?: string
          id?: string
          name?: string
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "users_data_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      workspaces: {
        Row: {
          created_at: string
          default_context_length: number
          default_model: string
          default_prompt: string
          default_temperature: number
          description: string
          embeddings_provider: string
          id: string
          include_profile_context: boolean
          include_workspace_instructions: boolean
          instructions: string
          is_home: boolean
          name: string
          sharing: string
          updated_at: string | null
          user_id: string
        }
        Insert: {
          created_at?: string
          default_context_length: number
          default_model: string
          default_prompt: string
          default_temperature: number
          description: string
          embeddings_provider: string
          id?: string
          include_profile_context: boolean
          include_workspace_instructions: boolean
          instructions: string
          is_home?: boolean
          name: string
          sharing?: string
          updated_at?: string | null
          user_id: string
        }
        Update: {
          created_at?: string
          default_context_length?: number
          default_model?: string
          default_prompt?: string
          default_temperature?: number
          description?: string
          embeddings_provider?: string
          id?: string
          include_profile_context?: boolean
          include_workspace_instructions?: boolean
          instructions?: string
          is_home?: boolean
          name?: string
          sharing?: string
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "workspaces_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      clear_conversation_buffer: {
        Args: {
          p_process_id: string
        }
        Returns: undefined
      }
      create_duplicate_messages_for_new_chat: {
        Args: {
          old_chat_id: string
          new_chat_id: string
          new_user_id: string
        }
        Returns: undefined
      }
      create_event: {
        Args: {
          p_user_id: string
          p_event_name: string
          p_message_name: string
          p_content: string
        }
        Returns: {
          content: string
          created_at: string
          event_type_id: string
          id: string
          message_name: string
          status: string
          updated_at: string | null
          user_id: string
        }[]
      }
      create_event_subscription: {
        Args: {
          p_process_id: string
          p_event_name: string
        }
        Returns: {
          returned_user_id: string
          returned_event_type_id: string
        }[]
      }
      create_request: {
        Args: {
          p_user_id: string
          p_client_process_id: string
          p_client_process_name: string
          p_service_name: string
          p_query: string
          p_is_async: boolean
        }
        Returns: {
          client_process_id: string
          client_process_name: string
          created_at: string
          feedback: string
          id: string
          is_async: boolean
          query: string
          response: string
          service_id: string
          service_process_id: string
          status: string
          updated_at: string | null
          user_id: string
        }[]
      }
      create_service: {
        Args: {
          p_user_id: string
          p_process_id: string
          p_name: string
          p_description: string
        }
        Returns: string
      }
      create_topic_subscription: {
        Args: {
          p_process_id: string
          p_topic_name: string
        }
        Returns: {
          returned_user_id: string
          returned_topic_id: string
        }[]
      }
      delete_message_including_and_after: {
        Args: {
          p_user_id: string
          p_sequence_number: number
        }
        Returns: undefined
      }
      delete_messages_including_and_after: {
        Args: {
          p_user_id: string
          p_sequence_number: number
        }
        Returns: undefined
      }
      delete_storage_object: {
        Args: {
          bucket: string
          object: string
        }
        Returns: Record<string, unknown>
      }
      delete_storage_object_from_bucket: {
        Args: {
          bucket_name: string
          object_path: string
        }
        Returns: Record<string, unknown>
      }
      get_active_messages: {
        Args: {
          p_process_id: string
        }
        Returns: {
          id: string
          user_id: string
          process_id: string
          created_at: string
          updated_at: string
          model: string
          message_type: string
          role: string
          sequence_number: number
          name: string
          content: string
          tool_calls: Json
          tool_call_id: string
          is_active: boolean
          on_buffer: boolean
        }[]
      }
      get_buffered_messages: {
        Args: {
          p_process_id: string
        }
        Returns: {
          id: string
          user_id: string
          process_id: string
          created_at: string
          updated_at: string
          model: string
          message_type: string
          role: string
          sequence_number: number
          name: string
          content: string
          tool_calls: Json
          tool_call_id: string
          is_active: boolean
          on_buffer: boolean
        }[]
      }
      get_event_subscriptions: {
        Args: {
          p_process_id: string
        }
        Returns: {
          event_id: string
          name: string
          content: string
          status: string
          updated_at: string
        }[]
      }
      get_topic_subscriptions: {
        Args: {
          p_process_id: string
        }
        Returns: {
          topic_id: string
          name: string
          description: string
          content: string
          updated_at: string
        }[]
      }
      insert_new_message: {
        Args: {
          p_user_id: string
          p_process_id: string
          p_model: string
          p_message_type: string
          p_role: string
          p_image_paths?: string[]
          p_name?: string
          p_content?: string
          p_tool_calls?: Json
          p_tool_call_id?: string
        }
        Returns: {
          content: string | null
          created_at: string
          id: string
          image_paths: string[]
          is_active: boolean
          message_type: string
          model: string
          name: string | null
          on_buffer: boolean
          process_id: string
          role: string
          sequence_number: number
          tool_call_id: string | null
          tool_calls: Json | null
          updated_at: string | null
          user_id: string
        }[]
      }
      insert_new_ui_message: {
        Args: {
          p_user_id: string
          p_process_id: string
          p_model: string
          p_message_type: string
          p_role: string
          p_image_paths?: string[]
          p_name?: string
          p_content?: string
          p_tool_calls?: Json
          p_tool_call_id?: string
        }
        Returns: {
          content: string | null
          created_at: string
          id: string
          image_paths: string[]
          is_active: boolean
          message_type: string
          model: string
          name: string | null
          on_buffer: boolean
          process_id: string
          role: string
          sequence_number: number
          tool_call_id: string | null
          tool_calls: Json | null
          updated_at: string | null
          user_id: string
        }[]
      }
      match_file_items_local: {
        Args: {
          query_embedding: string
          match_count?: number
          file_ids?: string[]
        }
        Returns: {
          id: string
          file_id: string
          content: string
          tokens: number
          similarity: number
        }[]
      }
      match_file_items_openai: {
        Args: {
          query_embedding: string
          match_count?: number
          file_ids?: string[]
        }
        Returns: {
          id: string
          file_id: string
          content: string
          tokens: number
          similarity: number
        }[]
      }
      non_private_assistant_exists: {
        Args: {
          p_name: string
        }
        Returns: boolean
      }
      non_private_file_exists: {
        Args: {
          p_name: string
        }
        Returns: boolean
      }
      send_message_to_assistant: {
        Args: {
          p_user_id: string
          p_process_id: string
          p_model: string
          p_message_type: string
          p_role: string
          p_image_paths?: string[]
          p_name?: string
          p_content?: string
          p_tool_calls?: Json
          p_tool_call_id?: string
        }
        Returns: {
          returned_id: string
          returned_created_at: string
        }[]
      }
      send_message_to_user: {
        Args: {
          p_user_id: string
          p_process_id: string
          p_model: string
          p_message_type: string
          p_role: string
          p_image_paths?: string[]
          p_name?: string
          p_content?: string
          p_tool_calls?: Json
          p_tool_call_id?: string
        }
        Returns: {
          returned_id: string
          returned_created_at: string
        }[]
      }
      soft_delete_message: {
        Args: {
          p_message_id: string
        }
        Returns: undefined
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  storage: {
    Tables: {
      buckets: {
        Row: {
          allowed_mime_types: string[] | null
          avif_autodetection: boolean | null
          created_at: string | null
          file_size_limit: number | null
          id: string
          name: string
          owner: string | null
          owner_id: string | null
          public: boolean | null
          updated_at: string | null
        }
        Insert: {
          allowed_mime_types?: string[] | null
          avif_autodetection?: boolean | null
          created_at?: string | null
          file_size_limit?: number | null
          id: string
          name: string
          owner?: string | null
          owner_id?: string | null
          public?: boolean | null
          updated_at?: string | null
        }
        Update: {
          allowed_mime_types?: string[] | null
          avif_autodetection?: boolean | null
          created_at?: string | null
          file_size_limit?: number | null
          id?: string
          name?: string
          owner?: string | null
          owner_id?: string | null
          public?: boolean | null
          updated_at?: string | null
        }
        Relationships: []
      }
      migrations: {
        Row: {
          executed_at: string | null
          hash: string
          id: number
          name: string
        }
        Insert: {
          executed_at?: string | null
          hash: string
          id: number
          name: string
        }
        Update: {
          executed_at?: string | null
          hash?: string
          id?: number
          name?: string
        }
        Relationships: []
      }
      objects: {
        Row: {
          bucket_id: string | null
          created_at: string | null
          id: string
          last_accessed_at: string | null
          metadata: Json | null
          name: string | null
          owner: string | null
          owner_id: string | null
          path_tokens: string[] | null
          updated_at: string | null
          version: string | null
        }
        Insert: {
          bucket_id?: string | null
          created_at?: string | null
          id?: string
          last_accessed_at?: string | null
          metadata?: Json | null
          name?: string | null
          owner?: string | null
          owner_id?: string | null
          path_tokens?: string[] | null
          updated_at?: string | null
          version?: string | null
        }
        Update: {
          bucket_id?: string | null
          created_at?: string | null
          id?: string
          last_accessed_at?: string | null
          metadata?: Json | null
          name?: string | null
          owner?: string | null
          owner_id?: string | null
          path_tokens?: string[] | null
          updated_at?: string | null
          version?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "objects_bucketId_fkey"
            columns: ["bucket_id"]
            isOneToOne: false
            referencedRelation: "buckets"
            referencedColumns: ["id"]
          }
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      can_insert_object: {
        Args: {
          bucketid: string
          name: string
          owner: string
          metadata: Json
        }
        Returns: undefined
      }
      extension: {
        Args: {
          name: string
        }
        Returns: string
      }
      filename: {
        Args: {
          name: string
        }
        Returns: string
      }
      foldername: {
        Args: {
          name: string
        }
        Returns: unknown
      }
      get_size_by_bucket: {
        Args: Record<PropertyKey, never>
        Returns: {
          size: number
          bucket_id: string
        }[]
      }
      search: {
        Args: {
          prefix: string
          bucketname: string
          limits?: number
          levels?: number
          offsets?: number
          search?: string
          sortcolumn?: string
          sortorder?: string
        }
        Returns: {
          name: string
          id: string
          updated_at: string
          created_at: string
          last_accessed_at: string
          metadata: Json
        }[]
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

export type Tables<
  PublicTableNameOrOptions extends
    | keyof (Database["public"]["Tables"] & Database["public"]["Views"])
    | { schema: keyof Database },
  TableName extends PublicTableNameOrOptions extends { schema: keyof Database }
    ? keyof (Database[PublicTableNameOrOptions["schema"]]["Tables"] &
        Database[PublicTableNameOrOptions["schema"]]["Views"])
    : never = never
> = PublicTableNameOrOptions extends { schema: keyof Database }
  ? (Database[PublicTableNameOrOptions["schema"]]["Tables"] &
      Database[PublicTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : PublicTableNameOrOptions extends keyof (Database["public"]["Tables"] &
      Database["public"]["Views"])
  ? (Database["public"]["Tables"] &
      Database["public"]["Views"])[PublicTableNameOrOptions] extends {
      Row: infer R
    }
    ? R
    : never
  : never

export type TablesInsert<
  PublicTableNameOrOptions extends
    | keyof Database["public"]["Tables"]
    | { schema: keyof Database },
  TableName extends PublicTableNameOrOptions extends { schema: keyof Database }
    ? keyof Database[PublicTableNameOrOptions["schema"]]["Tables"]
    : never = never
> = PublicTableNameOrOptions extends { schema: keyof Database }
  ? Database[PublicTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : PublicTableNameOrOptions extends keyof Database["public"]["Tables"]
  ? Database["public"]["Tables"][PublicTableNameOrOptions] extends {
      Insert: infer I
    }
    ? I
    : never
  : never

export type TablesUpdate<
  PublicTableNameOrOptions extends
    | keyof Database["public"]["Tables"]
    | { schema: keyof Database },
  TableName extends PublicTableNameOrOptions extends { schema: keyof Database }
    ? keyof Database[PublicTableNameOrOptions["schema"]]["Tables"]
    : never = never
> = PublicTableNameOrOptions extends { schema: keyof Database }
  ? Database[PublicTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : PublicTableNameOrOptions extends keyof Database["public"]["Tables"]
  ? Database["public"]["Tables"][PublicTableNameOrOptions] extends {
      Update: infer U
    }
    ? U
    : never
  : never

export type Enums<
  PublicEnumNameOrOptions extends
    | keyof Database["public"]["Enums"]
    | { schema: keyof Database },
  EnumName extends PublicEnumNameOrOptions extends { schema: keyof Database }
    ? keyof Database[PublicEnumNameOrOptions["schema"]]["Enums"]
    : never = never
> = PublicEnumNameOrOptions extends { schema: keyof Database }
  ? Database[PublicEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : PublicEnumNameOrOptions extends keyof Database["public"]["Enums"]
  ? Database["public"]["Enums"][PublicEnumNameOrOptions]
  : never

