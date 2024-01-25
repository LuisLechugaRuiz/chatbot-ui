import { supabase } from "./browser-client"

export class UserSupabaseClient {
  static instance: UserSupabaseClient | null = null

  constructor() {
    if (UserSupabaseClient.instance) {
      return UserSupabaseClient.instance
    }

    UserSupabaseClient.instance = this
  }

  async sendMessageToAssistant(
    userId: string,
    processId: string,
    model: string,
    messageType: string,
    role: string,
    name?: string,
    content?: string
  ) {
    try {
      const response = await supabase.rpc("send_message_to_assistant", {
        p_user_id: userId,
        p_process_id: processId,
        p_model: model,
        p_message_type: messageType,
        p_role: role,
        p_name: name,
        p_content: content
      })

      return response.data
    } catch (error) {
      console.error("Error sending message to assistant:", error)
      throw error
    }
  }

  async insertUIMessage(
    userId: string,
    processId: string,
    model: string,
    messageType: string,
    role: string,
    name?: string,
    content?: string
  ) {
    try {
      const response = await supabase.rpc("insert_new_ui_message", {
        p_user_id: userId,
        p_process_id: processId,
        p_model: model,
        p_message_type: messageType,
        p_role: role,
        p_name: name,
        p_content: content
      })

      // Check if response contains data and is not null
      if (response.data && response.data.length > 0) {
        // Assuming the response contains an array of messages
        return response.data[0] // Return the first message
      } else {
        // No data returned from the function, handle this case
        throw new Error("No data returned from insert_new_ui_message")
      }
    } catch (error) {
      console.error("Error sending message to assistant:", error)
      throw error // Re-throw the error for handling it in the calling function
    }
  }
}
