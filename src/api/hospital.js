import { request } from "./client";

export async function getDepartments() {
  const data = await request("/api/departments?page=1&limit=50");
  return data.departments;
}

export async function getDoctors({ departmentId, availableOnly = false, page = 1, limit = 12 } = {}) {
  const params = new URLSearchParams({ page: String(page), limit: String(limit) });
  if (departmentId) params.set("departmentId", departmentId);
  if (availableOnly) params.set("isAvailable", "true");
  const data = await request(`/api/doctors?${params}`);
  return data.doctors;
}