import { Tables } from "@/supabase/types"

export interface ChatMessage {
  message: Tables<"ui_messages">
  fileItems: string[]
}
