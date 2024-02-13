import { supabase } from "@/lib/supabase/browser-client"

export const getAssistantProcessById = async (userId: string) => {
  const { data: process, error } = await supabase
    .from("processes")
    .select("*")
    .eq("user_id", userId)
    .eq("tools_class", "Assistant")
    .single()

  if (!process) {
    throw new Error(error.message)
  }

  return process
}
