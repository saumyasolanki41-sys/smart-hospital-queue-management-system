import { request } from "./client";

export const getDoctorDashboard = (accessToken) =>
  request("/api/doctor/dashboard", { token: accessToken });
