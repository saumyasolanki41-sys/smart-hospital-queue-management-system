
const BASE_URL = (
  import.meta.env.VITE_API_BASE_URL ||
  "https://smart-hospital-queue-management-system-production.up.railway.app"
).replace(/\/+$/, "");

export class ApiError extends Error {
  constructor(message, { status, code } = {}) {
    super(message);
    this.name = "ApiError";
    this.status = status;
    this.code = code;
  }
}

export async function request(path, { method = "GET", body, token } = {}) {
  let res;
  try {
    res = await fetch(`${BASE_URL}${path}`, {
      method,
      headers: {
        ...(body ? { "Content-Type": "application/json" } : {}),
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
      },
      body: body ? JSON.stringify(body) : undefined,
    });
  } catch {
    throw new ApiError("Can't reach the server. Check your connection and try again.", {
      code: "NETWORK_ERROR",
    });
  }

  let json = null;
  try {
    json = await res.json();
  } catch {

  }

  if (!res.ok || !json?.success) {
    throw new ApiError(json?.error?.message || "Something went wrong. Please try again.", {
      status: res.status,
      code: json?.error?.code,
    });
  }
  return json.data;
}