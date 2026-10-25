import { Heart, Hand, Bone, Stethoscope, LayoutGrid } from "lucide-react";

function iconFor(name = "") {
  const n = name.toLowerCase();
  if (n.includes("cardio")) return Heart;
  if (n.includes("derma")) return Hand;
  if (n.includes("ortho")) return Bone;
  return Stethoscope;
}

export default function DepartmentCard({ name, description, selected, onClick, all = false }) {
  const Icon = all ? LayoutGrid : iconFor(name);

  return (
    <button
      type="button"
      onClick={onClick}
      aria-pressed={selected}
      className={`flex flex-col items-start rounded-2xl p-5 text-left transition ${
        selected
          ? "bg-primary/70 text-white shadow-lg"
          : "bg-white/90 text-slate-800 shadow-md hover:shadow-lg"
      }`}
    >
      <span
        className={`mb-3 flex h-10 w-10 items-center justify-center rounded-xl ${
          selected ? "bg-white/20" : "bg-primary/5 text-primary/70"
        }`}
      >
        <Icon className="h-5 w-5" />
      </span>
      <span className="font-semibold">{name}</span>
      {description && (
        <span className={`mt-1 line-clamp-2 text-sm ${selected ? "text-white/80" : "text-slate-500"}`}>
          {description}
        </span>
      )}
    </button>
  );
}