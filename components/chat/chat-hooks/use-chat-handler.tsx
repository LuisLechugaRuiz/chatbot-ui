import { ChatbotUIContext } from "@/context/context"
import { deleteMessagesIncludingAndAfter } from "@/db/messages"
import { Tables } from "@/supabase/types"
import { ChatMessage, ChatPayload } from "@/types"
import { useRouter } from "next/navigation"
import { useContext, useRef } from "react"
import { LLM_LIST } from "../../../lib/models/llm/llm-list"
import {
  handleCreateChat,
  handleAssistantMessage,
  handleUserMessage,
  handleHostedChat,
  handleLocalChat,
  handleRetrieval,
  validateChatSettings
} from "../chat-helpers"

export const useChatHandler = () => {
  const router = useRouter()

  const {
    userInput,
    chatFiles,
    setUserInput,
    setNewMessageImages,
    profile,
    setIsGenerating,
    setChatMessages,
    setFirstTokenReceived,
    selectedChat,
    selectedWorkspace,
    setSelectedChat,
    setChats,
    availableLocalModels,
    abortController,
    setAbortController,
    chatSettings,
    newMessageImages,
    selectedAssistant,
    chatMessages,
    chatImages,
    setChatImages,
    setChatFiles,
    setNewMessageFiles,
    setShowFilesDisplay,
    newMessageFiles,
    chatFileItems,
    setChatFileItems,
    setToolInUse,
    useRetrieval,
    sourceCount,
    setIsPromptPickerOpen,
    setIsAtPickerOpen
  } = useContext(ChatbotUIContext)

  const chatInputRef = useRef<HTMLTextAreaElement>(null)

  const handleNewChat = () => {
    setUserInput("")
    setChatMessages([])
    setSelectedChat(null)
    setChatFileItems([])

    setIsGenerating(false)
    setFirstTokenReceived(false)

    setChatFiles([])
    setChatImages([])
    setNewMessageFiles([])
    setNewMessageImages([])
    setShowFilesDisplay(false)
    setIsPromptPickerOpen(false)
    setIsAtPickerOpen(false)

    router.push("/chat")
  }

  const handleFocusChatInput = () => {
    chatInputRef.current?.focus()
  }

  const handleStopMessage = () => {
    if (abortController) {
      abortController.abort()
    }
  }

  const handleSendMessageUser = async (
    messageContent: string,
    chatMessages: ChatMessage[]
  ) => {
    try {
      console.log("Sending message:", messageContent)
      setIsGenerating(true)
      console.log("Debug 1")
      const newAbortController = new AbortController()
      setAbortController(newAbortController)
      console.log("Debug 2")
      const modelData = [...LLM_LIST, ...availableLocalModels].find(
        llm => llm.modelId === chatSettings?.model
      )
      console.log("Debug 3")
      let currentChat = selectedChat ? { ...selectedChat } : null
      if (!currentChat) {
        currentChat = await handleCreateChat(
          chatSettings!,
          profile!,
          selectedWorkspace!,
          messageContent,
          selectedAssistant!,
          newMessageFiles,
          setSelectedChat,
          setChats,
          setChatFiles
        )
        console.log("Creating chat:", currentChat)
      }
      console.log("Debug 4")

      if (!currentChat) {
        console.log("Creating chat failed")
        throw new Error("Chat not found")
      }

      console.log("Handling user message")
      setUserInput("")
      await handleUserMessage(
        chatMessages,
        currentChat,
        profile!,
        modelData!,
        messageContent,
        newMessageImages,
        setChatMessages
      )
    } catch (error) {
      console.error("Error in addMessageToChat:", error)
    }
  }

  const handleReceiveMessageAssistant = async (
    generatedText: string,
    chatMessages: ChatMessage[]
  ) => {
    try {
      setIsGenerating(false)
      const modelData = [...LLM_LIST, ...availableLocalModels].find(
        llm => llm.modelId === chatSettings?.model
      )

      let currentChat = selectedChat ? { ...selectedChat } : null
      if (!currentChat) {
        throw new Error("Chat not found at receive!")
      }

      let retrievedFileItems: Tables<"file_items">[] = []

      if (
        (newMessageFiles.length > 0 || chatFiles.length > 0) &&
        useRetrieval
      ) {
        setToolInUse("retrieval")

        retrievedFileItems = await handleRetrieval(
          userInput,
          newMessageFiles,
          chatFiles,
          chatSettings!.embeddingsProvider,
          sourceCount
        )
      }

      await handleAssistantMessage(
        chatMessages,
        currentChat,
        profile!,
        modelData!,
        generatedText,
        retrievedFileItems,
        setChatMessages,
        setChatFileItems
      )
    } catch (error) {
      console.error("Error in handleAssistantMessage:", error)
    }
  }

  const handleSendEdit = async (
    editedContent: string,
    sequenceNumber: number
  ) => {
    if (!selectedChat) return

    await deleteMessagesIncludingAndAfter(selectedChat.user_id, sequenceNumber)

    const filteredMessages = chatMessages.filter(
      chatMessage => chatMessage.message.sequence_number < sequenceNumber
    )

    setChatMessages(filteredMessages)

    // handleSendMessage(editedContent, filteredMessages, false)
  }

  return {
    chatInputRef,
    prompt,
    handleNewChat,
    handleSendMessageUser,
    handleReceiveMessageAssistant,
    handleFocusChatInput,
    handleStopMessage,
    handleSendEdit
  }
}
