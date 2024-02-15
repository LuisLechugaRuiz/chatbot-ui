import { supabase } from "./browser-client"
import {
  REALTIME_LISTEN_TYPES,
  REALTIME_POSTGRES_CHANGES_LISTEN_EVENT
} from "@supabase/supabase-js"

export class SupabaseRealTimeManager {
  static instance: SupabaseRealTimeManager | null = null
  onMessageCallback: CallableFunction | null = null

  private constructor(callback: CallableFunction) {
    this.onMessageCallback = callback
    this.initializeRealTimeListener()
  }

  private initializeRealTimeListener() {
    console.log("Initializing real time listener")
    supabase
      .channel("schema-db-changes")
      .on(
        REALTIME_LISTEN_TYPES.POSTGRES_CHANGES,
        {
          event: REALTIME_POSTGRES_CHANGES_LISTEN_EVENT.INSERT,
          schema: "public",
          table: "backend_messages"
        },
        payload => {
          console.log("Received payload", payload)
          if (this.onMessageCallback && payload.new) {
            console.log("Received new message", payload.new.content)
            this.onMessageCallback(payload.new.content)
          }
        }
      )
      .subscribe()
  }

  public updateCallback(newCallback: CallableFunction) {
    this.onMessageCallback = newCallback
  }

  public static getInstance(
    callback: CallableFunction
  ): SupabaseRealTimeManager {
    if (!SupabaseRealTimeManager.instance) {
      SupabaseRealTimeManager.instance = new SupabaseRealTimeManager(callback)
    } else {
      SupabaseRealTimeManager.instance.updateCallback(callback)
    }
    return SupabaseRealTimeManager.instance
  }
}
