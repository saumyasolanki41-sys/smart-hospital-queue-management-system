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