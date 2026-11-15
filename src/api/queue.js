import { request } from "./client";

export const joinQueue = (accessToken, doctorId) =>
  request("/api/queue/tokens", { method: "POST", body: { doctorId }, token: accessToken }).then(
    (data) => data.token
  );

export const getMyTokens = (accessToken) =>
  request("/api/queue/tokens/mine", { token: accessToken }).then((data) => data.tokens);

export const getTokenStatus = (accessToken, tokenId) =>
  request(`/api/queue/tokens/${tokenId}`, { token: accessToken });

export const cancelToken = (accessToken, tokenId) =>
  request(`/api/queue/tokens/${tokenId}/cancel`, { method: "PATCH", token: accessToken }).then(
    (data) => data.token
  );

export const getVisitHistory = (
  accessToken,
  { status = "completed", from, to, page = 1, limit = 20 } = {}
) => {
  const params = new URLSearchParams({ page: String(page), limit: String(limit) });
  if (status) params.set("status", status);
  if (from) params.set("from", from);
  if (to) params.set("to", to);
  return request(`/api/queue/history?${params}`, { token: accessToken });
};

export const getTokenFeedback = (accessToken, tokenId) =>
  request(`/api/queue/tokens/${tokenId}/feedback`, { token: accessToken });

export const submitTokenFeedback = (accessToken, tokenId, { rating, comment }) => {
  const body = { rating: Number(rating) };
  if (comment && typeof comment === "string") {
    const trimmed = comment.trim();
    if (trimmed) body.comment = trimmed;
  }
  return request(`/api/queue/tokens/${tokenId}/feedback`, {
    method: "POST",
    body,
    token: accessToken,
  });
};
