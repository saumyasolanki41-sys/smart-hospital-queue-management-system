// src/components/queue/StatusBadge.jsx
import { Clock, Bell, Check, X, SkipForward } from "lucide-react";

const STATUS_CONFIG = {
  waiting: { label: "Waiting", icon: Clock, style: "bg-yellow-100 text-yellow-800" },
  called: { label: "Called", icon: Bell, style: "bg-primary/10 text-primary/80" },
  completed: { label: "Completed", icon: Check, style: "bg-green-100 text-green-800" },
  cancelled: { label: "Cancelled", icon: X, style: "bg-gray-100 text-gray-700" },
  skipped: { label: "Skipped", icon: SkipForward, style: "bg-orange-100 text-orange-800" },
};

export default function StatusBadge({ status }) {
  const config = STATUS_CONFIG[status] ?? STATUS_CONFIG.waiting;
  const Icon = config.icon;

  return (
    <span
      className={`inline-flex items-center gap-1.5 rounded-full px-3 py-1 text-sm font-medium ${config.style}`}
    >
      <Icon className="h-4 w-4" />
      {config.label}
    </span>
  );
}