// src/components/layout/DashboardBackground.jsx
import React from "react";

export default function DashboardBackground({ children, className = "" }) {
  return (
    <div
      className={`relative min-h-screen w-full overflow-x-hidden bg-gradient-to-br from-[#e4f8fa] via-[#d4f3f8] to-[#c2edf5] text-slate-800 ${className}`}
    >
      {/* Decorative ambient background matching the dashboard design */}
      <div
        className="pointer-events-none fixed inset-0 overflow-hidden"
        aria-hidden="true"
      >
        {/* Top-right dark teal geometric accent bar */}
        <div className="absolute right-0 top-0 h-4 w-72 sm:w-96 rounded-bl-2xl bg-[#0a3d54] shadow-sm">
          <div className="absolute inset-x-0 bottom-0 h-[2px] bg-gradient-to-r from-teal-400 via-cyan-300 to-sky-300 opacity-90" />
        </div>

        {/* Top-right ambient soft cyan glow */}
        <div className="absolute -right-28 -top-28 h-[34rem] w-[34rem] rounded-full bg-gradient-to-br from-cyan-200/50 via-teal-100/30 to-transparent blur-3xl" />

        {/* Center-left subtle ambient illumination */}
        <div className="absolute -left-20 top-1/4 h-[28rem] w-[28rem] rounded-full bg-cyan-100/40 blur-3xl" />

        {/* Mid-right ambient wave glow */}
        <div className="absolute -right-16 top-1/2 h-80 w-80 rounded-full bg-gradient-to-l from-cyan-200/35 to-transparent blur-2xl" />

        {/* The prominent 3D tilted cyan/aqua capsule at the bottom as shown in the design */}
        <div
          className="absolute -bottom-20 left-1/4 h-32 w-[34rem] -rotate-[24deg] rounded-full sm:-bottom-24 sm:left-1/3 sm:h-40 sm:w-[46rem]"
          style={{
            background:
              "linear-gradient(135deg, #82e5f3 0%, #60d0e3 45%, #44bcd2 100%)",
            boxShadow:
              "0 24px 50px -10px rgba(18, 125, 155, 0.28), inset 0 2px 6px rgba(255, 255, 255, 0.55)",
            borderTop: "1px solid rgba(255, 255, 255, 0.45)",
            opacity: 0.78,
          }}
        />

        {/* Secondary soft floating pill behind the bottom-right */}
        <div
          className="absolute -bottom-10 right-6 h-24 w-72 -rotate-[16deg] rounded-full sm:right-16 sm:h-32 sm:w-96"
          style={{
            background:
              "linear-gradient(135deg, rgba(142, 231, 243, 0.55) 0%, rgba(88, 204, 224, 0.45) 100%)",
            boxShadow: "0 20px 40px rgba(20, 130, 160, 0.18)",
            filter: "blur(12px)",
          }}
        />
      </div>

      {/* Foreground content */}
      <div className="relative z-10">{children}</div>
    </div>
  );
}

