import axios from "axios";

const BASE_URL = (
  import.meta.env.VITE_API_BASE_URL ||
  "https://smart-hospital-queue-management-system-production.up.railway.app"
).replace(/\/+$/, "");

const TIMEOUT_MS = 15000;

export class ApiError extends Error {
  constructor(message, { status, code } = {}) {
    super(message);
    this.name = "ApiError";
    this.status = status;
    this.code = code;
  }
}

let onUnauthorized = null;
export function setUnauthorizedHandler(handler) {
  onUnauthorized = handler;
}

const http = axios.create({ baseURL: BASE_URL, timeout: TIMEOUT_MS });

http.interceptors.response.use(
  (response) => response,
  (error) => {
    if (axios.isCancel(error)) return Promise.reject(error); 

    if (error.response) {
      
      const failure = error.response.data?.error;
      const apiError = new ApiError(failure?.message || "Something went wrong. Please try again.", {
        status: error.response.status,
        code: failure?.code,
      });
      if (apiError.code === "UNAUTHORIZED") onUnauthorized?.();
      return Promise.reject(apiError);
    }

    if (error.code === "ECONNABORTED" || error.code === "ETIMEDOUT") {
      return Promise.reject(
        new ApiError("The server took too long to respond. Please try again.", { code: "TIMEOUT" })
      );
    }

    return Promise.reject(
      new ApiError("Can't reach the server. Check your connection and try again.", { code: "NETWORK_ERROR" })
    );
  }
);

export async function request(path, { method = "GET", body, token, signal } = {}) {
  const response = await http.request({
    url: path,
    method,
    data: body,
    headers: token ? { Authorization: `Bearer ${token}` } : undefined,
    signal,
  });

  const json = response.data;
  if (!json?.success) {
    throw new ApiError("Unexpected response from the server.", { status: response.status });
  }
  return json.data;
}