import { supabase } from "@/lib/supabase/browser-client"

export const getAgentById = async (agentId: string) => {
  const { data: agent, error } = await supabase
    .from("agents")
    .select("*")
    .eq("id", agentId)
    .single()

  if (!agent) {
    throw new Error(error.message)
  }

  return agent
}
