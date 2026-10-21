
import axios from "axios";

const BASE_URL = (
  import.meta.env.VITE_API_BASE_URL ||
  "https://smart-hospital-queue-management-system-production.up.railway.app"
).replace(/\/+$/, "");

const client = axios.create({ baseURL: BASE_URL });

export class ApiError extends Error {
  constructor(message, { status, code } = {}) {
    super(message);
    this.name = "ApiError";
    this.status = status;
    this.code = code;
  }
}

export async function request(path, { method = "GET", body, token } = {}) {
  let response;
  try {
    response = await client.request({
      url: path,
      method,
      data: body,
      headers: token ? { Authorization: `Bearer ${token}` } : undefined,
    });
  } catch (error) {
    if (!axios.isAxiosError(error)) throw error;

    if (!error.response) {
      throw new ApiError("Can't reach the server. Check your connection and try again.", {
        code: "NETWORK_ERROR",
      });
    }

    throw new ApiError(
      error.response.data?.error?.message || "Something went wrong. Please try again.",
      {
        status: error.response.status,
        code: error.response.data?.error?.code,
      }
    );
  }

  const json = response.data;
  if (!json?.success) {
    throw new ApiError(json?.error?.message || "Something went wrong. Please try again.", {
      status: response.status,
      code: json?.error?.code,
    });
  }
  return json.data;
}