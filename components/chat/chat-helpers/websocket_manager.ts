class WebSocketManager {
  static instance: WebSocketManager | null = null
  webSocketClient: WebSocket | null = null
  onMessageCallback: CallableFunction | null = null

  constructor(url: string) {
    if (WebSocketManager.instance) {
      return WebSocketManager.instance
    }

    this.webSocketClient = new WebSocket(url)
    this.webSocketClient.onopen = () =>
      console.log("Connected to the WebSocket server")
    this.webSocketClient.onerror = (event: any) =>
      console.error("WebSocket error:", event)
    this.webSocketClient.onmessage = (event: any) => {
      console.log("Received message:", event.data)
      this.onMessage(event.data)
    }

    WebSocketManager.instance = this
  }

  onMessage(message: string) {
    if (this.onMessageCallback) {
      this.onMessageCallback(message)
    }
  }

  setOnMessageCallback(callback: CallableFunction) {
    this.onMessageCallback = callback
  }

  readyState() {
    if (this.webSocketClient) {
      return WebSocket.OPEN
    } else {
      return WebSocket.CLOSED
    }
  }

  sendMessage(message: string) {
    if (
      this.webSocketClient &&
      this.webSocketClient.readyState === WebSocket.OPEN
    ) {
      this.webSocketClient.send(message)
    } else {
      console.error("WebSocket is not open.")
    }
  }
}

const webSocketManager = new WebSocketManager("ws://localhost:50010")
export default webSocketManager
