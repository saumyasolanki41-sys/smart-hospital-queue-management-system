import { request } from "./client";

const query = (params) => {
  const search = new URLSearchParams();
  Object.entries(params).forEach(([key, value]) => value !== undefined && search.set(key, String(value)));
  return search.toString();
};

// ---- Ambulance records ----

export const listAmbulances = (accessToken, { status, page = 1, limit = 50 } = {}) =>
  request(`/api/ambulances?${query({ status, page, limit })}`, { token: accessToken }).then((d) => d.ambulances);

export const createAmbulance = (accessToken, body) =>
  request("/api/ambulances", { method: "POST", body, token: accessToken }).then((d) => d.ambulance);

export const updateAmbulance = (accessToken, id, body) =>
  request(`/api/ambulances/${id}`, { method: "PATCH", body, token: accessToken }).then((d) => d.ambulance);

// ---- Transport requests ----

// status: "pending" | "assigned" | "completed" | "cancelled". Newest first.
export const listAmbulanceRequests = (accessToken, { status, page = 1, limit = 50 } = {}) =>
  request(`/api/ambulance-requests?${query({ status, page, limit })}`, { token: accessToken }).then(
    (d) => d.requests
  );

export const assignRequest = (accessToken, requestId, ambulanceId) =>
  request(`/api/ambulance-requests/${requestId}/assign`, {
    method: "PATCH",
    body: { ambulanceId },
    token: accessToken,
  }).then((d) => d.request);

export const completeRequest = (accessToken, requestId) =>
  request(`/api/ambulance-requests/${requestId}/complete`, { method: "PATCH", token: accessToken }).then(
    (d) => d.request
  );

export const cancelRequest = (accessToken, requestId) =>
  request(`/api/ambulance-requests/${requestId}/cancel`, { method: "PATCH", token: accessToken }).then(
    (d) => d.request
  );