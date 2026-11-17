import axios from "axios";

const CHATBOT_URL =
  import.meta.env.VITE_CHATBOT_API_URL ||
  "/chat";

const TIMEOUT_MS = 25000;

export async function sendChatMessage({ message, sessionId, accessToken, mode = "auto" }) {
  const headers = {
    "Content-Type": "application/json",
  };

  if (accessToken) {
    headers["Authorization"] = `Bearer ${accessToken}`;
  }

  const payload = {
    message,
    mode,
  };

  if (sessionId) {
    payload.session_id = sessionId;
  }

  try {
    const response = await axios.post(CHATBOT_URL, payload, {
      headers,
      timeout: TIMEOUT_MS,
    });

    return response.data;
  } catch (err) {
    if (err.code === "ECONNABORTED" || err.code === "ETIMEDOUT") {
      throw new Error("The assistant took too long to respond. Please try again.");
    }

    if (err.response) {
      const serverMsg =
        err.response.data?.error?.message ||
        err.response.data?.message ||
        err.response.data?.reply;
      if (serverMsg) {
        throw new Error(serverMsg);
      }
      throw new Error(`Assistant error (${err.response.status}). Please try again.`);
    }

    throw new Error("Unable to connect to the assistant. Please check your internet connection.");
  }
}
