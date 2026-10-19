import { request } from "./client";

const base = (doctorId) => `/api/staff/queues/doctors/${doctorId}`;

export const getDoctorQueue = (accessToken, doctorId, { status = "waiting", page = 1, limit = 50 } = {}) => {
  const params = new URLSearchParams({ status, page: String(page), limit: String(limit) });
  return request(`${base(doctorId)}/tokens?${params}`, { token: accessToken });
};

export const callNext = (accessToken, doctorId) =>
  request(`${base(doctorId)}/call-next`, { method: "POST", token: accessToken }).then((d) => d.token);

export const completeToken = (accessToken, doctorId, tokenId) =>
  request(`${base(doctorId)}/tokens/${tokenId}/complete`, { method: "PATCH", token: accessToken }).then(
    (d) => d.token
  );

export const skipToken = (accessToken, doctorId, tokenId) =>
  request(`${base(doctorId)}/tokens/${tokenId}/skip`, { method: "PATCH", token: accessToken }).then(
    (d) => d.token
  );