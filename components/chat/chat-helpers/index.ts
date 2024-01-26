// Only used in use-chat-handler.tsx to keep it clean

import { getAgentById } from "@/db/agents"
import { createChatFiles } from "@/db/chat-files"
import { createChat } from "@/db/chats"
import { createMessageFileItems } from "@/db/message-file-items"
import { createMessage, createMessages, updateMessage } from "@/db/messages"
import { uploadMessageImage } from "@/db/storage/message-images"
import {
  buildFinalMessages,
  buildGoogleGeminiFinalMessages
} from "@/lib/build-prompt"
import { consumeReadableStream } from "@/lib/consume-stream"
import { Tables, TablesInsert } from "@/supabase/types"
import {
  ChatFile,
  ChatMessage,
  ChatPayload,
  ChatSettings,
  LLM,
  MessageImage
} from "@/types"
import React from "react"
import { toast } from "sonner"
import { v4 as uuidv4 } from "uuid"
import { UserSupabaseClient } from "@/lib/supabase/user-client"

export const validateChatSettings = (
  chatSettings: ChatSettings | null,
  modelData: LLM | undefined,
  profile: Tables<"profiles"> | null,
  selectedWorkspace: Tables<"workspaces"> | null,
  messageContent: string
) => {
  if (!chatSettings) {
    throw new Error("Chat settings not found")
  }

  if (!modelData) {
    throw new Error("Model not found")
  }

  if (!profile) {
    throw new Error("Profile not found")
  }

  if (!selectedWorkspace) {
    throw new Error("Workspace not found")
  }

  if (!messageContent) {
    throw new Error("Message content not found")
  }
}

export const handleRetrieval = async (
  userInput: string,
  newMessageFiles: ChatFile[],
  chatFiles: ChatFile[],
  embeddingsProvider: "openai" | "local",
  sourceCount: number
) => {
  const response = await fetch("/api/retrieval/retrieve", {
    method: "POST",
    body: JSON.stringify({
      userInput,
      fileIds: [...newMessageFiles, ...chatFiles].map(file => file.id),
      embeddingsProvider,
      sourceCount
    })
  })

  if (!response.ok) {
    console.error("Error retrieving:", response)
  }

  const { results } = (await response.json()) as {
    results: Tables<"file_items">[]
  }

  return results
}

export const createTempMessages = (
  messageContent: string,
  chatMessages: ChatMessage[],
  chatSettings: ChatSettings,
  b64Images: string[],
  isRegeneration: boolean,
  setChatMessages: React.Dispatch<React.SetStateAction<ChatMessage[]>>
) => {
  let tempUserChatMessage: ChatMessage = {
    message: {
      process_id: "",
      content: messageContent,
      created_at: "",
      id: uuidv4(),
      image_paths: b64Images,
      model: chatSettings.model,
      role: "user",
      sequence_number: chatMessages.length,
      updated_at: "",
      user_id: ""
    },
    fileItems: []
  }

  let tempAssistantChatMessage: ChatMessage = {
    message: {
      process_id: "",
      content: "",
      created_at: "",
      id: uuidv4(),
      image_paths: [],
      model: chatSettings.model,
      role: "assistant",
      sequence_number: chatMessages.length + 1,
      updated_at: "",
      user_id: ""
    },
    fileItems: []
  }

  let newMessages = []

  if (isRegeneration) {
    const lastMessageIndex = chatMessages.length - 1
    chatMessages[lastMessageIndex].message.content = ""
    newMessages = [...chatMessages]
  } else {
    newMessages = [
      ...chatMessages,
      tempUserChatMessage,
      tempAssistantChatMessage
    ]
  }

  setChatMessages(newMessages)

  return {
    tempUserChatMessage,
    tempAssistantChatMessage
  }
}

export const handleLocalChat = async (
  payload: ChatPayload,
  profile: Tables<"profiles">,
  chatSettings: ChatSettings,
  tempAssistantMessage: ChatMessage,
  isRegeneration: boolean,
  newAbortController: AbortController,
  setIsGenerating: React.Dispatch<React.SetStateAction<boolean>>,
  setFirstTokenReceived: React.Dispatch<React.SetStateAction<boolean>>,
  setChatMessages: React.Dispatch<React.SetStateAction<ChatMessage[]>>,
  setToolInUse: React.Dispatch<React.SetStateAction<"none" | "retrieval">>
) => {
  const formattedMessages = await buildFinalMessages(payload, profile, [])

  // Ollama API: https://github.com/jmorganca/ollama/blob/main/docs/api.md
  const response = await fetchChatResponse(
    process.env.NEXT_PUBLIC_OLLAMA_URL + "/api/chat",
    {
      model: chatSettings.model,
      messages: formattedMessages,
      options: {
        temperature: payload.chatSettings.temperature
      }
    },
    false,
    newAbortController,
    setIsGenerating,
    setChatMessages
  )

  return await processResponse(
    response,
    isRegeneration
      ? payload.chatMessages[payload.chatMessages.length - 1]
      : tempAssistantMessage,
    false,
    newAbortController,
    setFirstTokenReceived,
    setChatMessages,
    setToolInUse
  )
}

export const handleHostedChat = async (
  payload: ChatPayload,
  profile: Tables<"profiles">,
  modelData: LLM,
  tempAssistantChatMessage: ChatMessage,
  isRegeneration: boolean,
  newAbortController: AbortController,
  newMessageImages: MessageImage[],
  chatImages: MessageImage[],
  setIsGenerating: React.Dispatch<React.SetStateAction<boolean>>,
  setFirstTokenReceived: React.Dispatch<React.SetStateAction<boolean>>,
  setChatMessages: React.Dispatch<React.SetStateAction<ChatMessage[]>>,
  setToolInUse: React.Dispatch<React.SetStateAction<"none" | "retrieval">>
) => {
  const provider =
    modelData.provider === "openai" && profile.use_azure_openai
      ? "azure"
      : modelData.provider

  let formattedMessages = []

  if (provider === "google") {
    formattedMessages = await buildGoogleGeminiFinalMessages(
      payload,
      profile,
      newMessageImages
    )
  } else {
    formattedMessages = await buildFinalMessages(payload, profile, chatImages)
  }

  const response = await fetchChatResponse(
    `/api/chat/${provider}`,
    {
      chatSettings: payload.chatSettings,
      messages: formattedMessages
    },
    true,
    newAbortController,
    setIsGenerating,
    setChatMessages
  )

  return await processResponse(
    response,
    isRegeneration
      ? payload.chatMessages[payload.chatMessages.length - 1]
      : tempAssistantChatMessage,
    true,
    newAbortController,
    setFirstTokenReceived,
    setChatMessages,
    setToolInUse
  )
}

export const fetchChatResponse = async (
  url: string,
  body: object,
  isHosted: boolean,
  controller: AbortController,
  setIsGenerating: React.Dispatch<React.SetStateAction<boolean>>,
  setChatMessages: React.Dispatch<React.SetStateAction<ChatMessage[]>>
) => {
  const response = await fetch(url, {
    method: "POST",
    body: JSON.stringify(body),
    signal: controller.signal
  })

  if (!response.ok) {
    if (response.status === 404 && !isHosted) {
      toast.error(
        "Model not found. Make sure you have it downloaded via Ollama."
      )
    }

    const errorData = await response.json()

    toast.error(errorData.message)

    setIsGenerating(false)
    setChatMessages(prevMessages => prevMessages.slice(0, -2))
  }

  return response
}

export const processResponse = async (
  response: Response,
  lastChatMessage: ChatMessage,
  isHosted: boolean,
  controller: AbortController,
  setFirstTokenReceived: React.Dispatch<React.SetStateAction<boolean>>,
  setChatMessages: React.Dispatch<React.SetStateAction<ChatMessage[]>>,
  setToolInUse: React.Dispatch<React.SetStateAction<"none" | "retrieval">>
) => {
  let fullText = ""
  let contentToAdd = ""

  if (response.body) {
    await consumeReadableStream(
      response.body,
      chunk => {
        setFirstTokenReceived(true)
        setToolInUse("none")

        try {
          contentToAdd = isHosted ? chunk : JSON.parse(chunk).message.content
          fullText += contentToAdd
        } catch (error) {
          console.error("Error parsing JSON:", error)
        }

        setChatMessages(prev =>
          prev.map(chatMessage => {
            if (chatMessage.message.id === lastChatMessage.message.id) {
              const updatedChatMessage: ChatMessage = {
                message: {
                  ...chatMessage.message,
                  content: chatMessage.message.content + contentToAdd
                },
                fileItems: chatMessage.fileItems
              }

              return updatedChatMessage
            }

            return chatMessage
          })
        )
      },
      controller.signal
    )

    return fullText
  } else {
    throw new Error("Response body is null")
  }
}

export const handleCreateChat = async (
  chatSettings: ChatSettings,
  profile: Tables<"profiles">,
  selectedWorkspace: Tables<"workspaces">,
  messageContent: string,
  selectedAssistant: Tables<"assistants">,
  newMessageFiles: ChatFile[],
  setSelectedChat: React.Dispatch<React.SetStateAction<Tables<"chats"> | null>>,
  setChats: React.Dispatch<React.SetStateAction<Tables<"chats">[]>>,
  setChatFiles: React.Dispatch<React.SetStateAction<ChatFile[]>>
) => {
  const assistant_agent = await getAgentById(profile.assistant_agent_id)

  const createdChat = await createChat({
    user_id: profile.user_id,
    process_id: assistant_agent.main_process_id,
    workspace_id: selectedWorkspace.id,
    assistant_id: selectedAssistant?.id || null,
    context_length: chatSettings.contextLength,
    include_profile_context: chatSettings.includeProfileContext,
    include_workspace_instructions: chatSettings.includeWorkspaceInstructions,
    model: chatSettings.model,
    name: messageContent.substring(0, 100),
    prompt: chatSettings.prompt,
    temperature: chatSettings.temperature,
    embeddings_provider: chatSettings.embeddingsProvider
  })

  setSelectedChat(createdChat)
  setChats(chats => [createdChat, ...chats])

  await createChatFiles(
    newMessageFiles.map(file => ({
      user_id: profile.user_id,
      chat_id: createdChat.id,
      file_id: file.id
    }))
  )

  setChatFiles(prev => [...prev, ...newMessageFiles])

  return createdChat
}

export const handleUserMessage = async (
  chatMessages: ChatMessage[],
  currentChat: Tables<"chats">,
  profile: Tables<"profiles">,
  modelData: LLM,
  messageContent: string,
  newMessageImages: MessageImage[],
  setChatMessages: React.Dispatch<React.SetStateAction<ChatMessage[]>>
) => {
  // Send message to the assistant
  const userSupabaseClient = new UserSupabaseClient()

  let userMessage = await userSupabaseClient.insertUIMessage(
    profile.user_id,
    currentChat.process_id,
    modelData.modelId,
    "UserMessage",
    "user",
    profile.display_name,
    messageContent
  )
  let createdUserMessage: TablesInsert<"ui_messages"> = {
    id: userMessage.id,
    user_id: userMessage.user_id,
    process_id: userMessage.process_id,
    model: userMessage.model,
    message_type: userMessage.message_type,
    role: userMessage.role,
    name: userMessage.name,
    content: userMessage.content,
    sequence_number: userMessage.sequence_number,
    image_paths: userMessage.image_paths || []
  }

  await userSupabaseClient.sendMessageToAssistant(
    profile.user_id,
    currentChat.process_id,
    modelData.modelId,
    "UserMessage",
    "user",
    profile.display_name,
    messageContent
  )

  // Upload each image (stored in newMessageImages) for the user message to message_images bucket
  const uploadPromises = newMessageImages
    .filter(obj => obj.file !== null)
    .map(obj => {
      let filePath = `${profile.user_id}/${currentChat.id}/${
        createdUserMessage.id
      }/${uuidv4()}`

      return uploadMessageImage(filePath, obj.file as File).catch(error => {
        console.error(`Failed to upload image at ${filePath}:`, error)
        return null
      })
    })

  const paths = (await Promise.all(uploadPromises)).filter(Boolean) as string[]
  let updatedUserMessage
  try {
    updatedUserMessage = await updateMessage(createdUserMessage.id, {
      ...createdUserMessage,
      image_paths: paths
    })
  } catch (error) {
    console.error("Error updating message:", error)
    throw error
  }

  // Update the chat messages state with the new user message
  setChatMessages([
    ...chatMessages,
    { message: updatedUserMessage, fileItems: [] } // Assuming this is the correct structure
  ])
}

export const handleAssistantMessage = async (
  chatMessages: ChatMessage[],
  currentChat: Tables<"chats">,
  profile: Tables<"profiles">,
  modelData: LLM,
  generatedText: string,
  retrievedFileItems: Tables<"file_items">[],
  setChatMessages: React.Dispatch<React.SetStateAction<ChatMessage[]>>,
  setChatFileItems: React.Dispatch<React.SetStateAction<Tables<"file_items">[]>>
) => {
  // Send message to the assistant
  const userSupabaseClient = new UserSupabaseClient()

  let assistantMessage = await userSupabaseClient.insertUIMessage(
    profile.user_id,
    currentChat.process_id,
    modelData.modelId,
    "AssistantMessage",
    "assistant", // TODO: Should be not needed with MessageType.
    profile.display_name,
    generatedText
  )
  let createdAssistantMessage: TablesInsert<"ui_messages"> = {
    id: assistantMessage.id,
    user_id: assistantMessage.user_id,
    process_id: assistantMessage.process_id,
    model: assistantMessage.model,
    message_type: assistantMessage.message_type,
    role: assistantMessage.role,
    name: assistantMessage.name,
    content: assistantMessage.content,
    sequence_number: assistantMessage.sequence_number,
    image_paths: assistantMessage.image_paths || []
  }

  // Logic for creating the assistant message
  // const createdAssistantMessage = await createMessage(finalAssistantMessage)

  // Handle file items, if any
  setChatFileItems(prevFileItems => {
    const newFileItems = retrievedFileItems.filter(
      fileItem => !prevFileItems.some(prevItem => prevItem.id === fileItem.id)
    )
    return [...prevFileItems, ...newFileItems]
  })

  // Update the chat messages state with the new assistant message
  setChatMessages([
    ...chatMessages,
    {
      message: createdAssistantMessage,
      fileItems: retrievedFileItems.map(fileItem => fileItem.id)
    }
  ])
}
