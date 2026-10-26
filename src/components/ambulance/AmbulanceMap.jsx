import { useEffect, useRef } from "react";
import L from "leaflet";
import "leaflet/dist/leaflet.css";
import { timeAgo } from "../../utils/time";

const AMBULANCE_COLORS = { available: "#16a34a", busy: "#ea580c", maintenance: "#64748b" };
const REQUEST_COLORS = { pending: "#dc2626", assigned: "#2563eb" };

function pinIcon(color, label, square) {
  return L.divIcon({
    className: "",
    html: `<div style="width:28px;height:28px;display:flex;align-items:center;justify-content:center;background:${color};color:#fff;font:700 13px/1 system-ui,sans-serif;border:2px solid #fff;border-radius:${
      square ? "6px" : "50%"
    };box-shadow:0 1px 4px rgba(0,0,0,.45)">${label}</div>`,
    iconSize: [28, 28],
    iconAnchor: [14, 14],
    popupAnchor: [0, -14],
  });
}

function popup(lines) {
  const box = document.createElement("div");
  lines.forEach((text, i) => {
    const row = document.createElement("div");
    row.textContent = text;
    if (i === 0) row.style.fontWeight = "600";
    box.appendChild(row);
  });
  return box;
}

const isNumber = (n) => typeof n === "number" && Number.isFinite(n);


export default function AmbulanceMap({
  ambulances,
  requests,
  focus,
  pickMode,
  onPick,
  pickedPoint,
  className = "h-[28rem]",
}) {
  const containerRef = useRef(null);
  const mapRef = useRef(null);
  const layerRef = useRef(null);
  const pickRef = useRef(null);
  const fittedRef = useRef(false);

  useEffect(() => {
    const map = L.map(containerRef.current).setView([22.5, 79], 5); // India overview until markers exist
    L.tileLayer("https://tile.openstreetmap.org/{z}/{x}/{y}.png", {
      maxZoom: 19,
      attribution:
        '&copy; <a href="https://www.openstreetmap.org/copyright" target="_blank" rel="noreferrer">OpenStreetMap</a> contributors',
    }).addTo(map);
    layerRef.current = L.layerGroup().addTo(map);
    mapRef.current = map;

    return () => {
      map.remove();
      mapRef.current = null;
      layerRef.current = null;
      pickRef.current = null;
      fittedRef.current = false;
    };
  }, []);

  useEffect(() => {
    const map = mapRef.current;
    const layer = layerRef.current;
    if (!map || !layer) return;

    layer.clearLayers();
    const points = [];

    ambulances.forEach((a) => {
      const loc = a.location;
      if (!loc || !isNumber(loc.latitude) || !isNumber(loc.longitude)) return;
      L.marker([loc.latitude, loc.longitude], {
        icon: pinIcon(AMBULANCE_COLORS[a.status] ?? "#64748b", "A", false),
      })
        .bindPopup(
          popup([
            a.vehicleNumber,
            `Status: ${a.status}`,
            `Driver: ${a.driverName}`,
            `Location updated ${timeAgo(loc.updatedAt)}`,
          ])
        )
        .addTo(layer);
      points.push([loc.latitude, loc.longitude]);
    });

    requests.forEach((r) => {
      if (!isNumber(r.latitude) || !isNumber(r.longitude)) return;
      L.marker([r.latitude, r.longitude], {
        icon: pinIcon(REQUEST_COLORS[r.status] ?? "#dc2626", "P", true),
      })
        .bindPopup(popup([`Pickup (${r.status})`, r.pickupAddress, `Contact: ${r.contactPhone}`]))
        .addTo(layer);
      points.push([r.latitude, r.longitude]);
    });

    if (!fittedRef.current && points.length > 0) {
      map.fitBounds(points, { padding: [40, 40], maxZoom: 15 });
      fittedRef.current = true;
    }
  }, [ambulances, requests]);

  useEffect(() => {
    const map = mapRef.current;
    if (map && focus) map.flyTo([focus.lat, focus.lng], Math.max(map.getZoom(), 14));
  }, [focus]);

  useEffect(() => {
    const map = mapRef.current;
    if (!map || !pickMode) return;
    const handler = (e) => {
      const { lat, lng } = e.latlng.wrap(); 
      onPick?.(lat, lng);
    };
    map.on("click", handler);
    map.getContainer().style.cursor = "crosshair";
    return () => {
      map.off("click", handler);
      map.getContainer().style.cursor = "";
    };
  }, [pickMode, onPick]);

  useEffect(() => {
    const map = mapRef.current;
    if (!map) return;
    if (pickRef.current) {
      pickRef.current.remove();
      pickRef.current = null;
    }
    if (pickedPoint) {
      pickRef.current = L.marker([pickedPoint.lat, pickedPoint.lng], {
        icon: pinIcon("#7c3aed", "+", false),
      }).addTo(map);
    }
  }, [pickedPoint]);

  return <div ref={containerRef} className={`isolate z-0 w-full rounded-3xl shadow-xl ${className}`} />;
}