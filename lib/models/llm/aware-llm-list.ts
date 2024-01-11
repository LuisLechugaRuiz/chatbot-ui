import { LLM } from "@/types"

const AWARE_PLATORM_LINK = "https://tmp.aware-ai.com/docs/getting-started"

// Aware Models (UPDATED 01/11/23) -----------------------------

// Aware 1.0 (UPDATED 01/11/23)
const AWARE: LLM = {
  modelId: "aware-1.0",
  modelName: "Aware",
  provider: "aware",
  hostedId: "aware-1",
  platformLink: AWARE_PLATORM_LINK,
  imageInput: false
}

export const AWARE_LLM_LIST: LLM[] = [AWARE]
