import { useRef } from "react";
import { Canvas, useFrame } from "@react-three/fiber";
import { Float, useTexture, Torus, Stars } from "@react-three/drei";
import * as THREE from "three";

/* ─── theme colours ──────────────────────────────────────────────────── */
const C_PRIMARY  = "#004bbd";
const C_ACCENT   = "#3b82f6";
const C_LIGHT    = "#93c5fd";
const C_WHITE    = "#ddeeff";

/* ─── Hero image rendered as a floating textured plane ──────────────── */
function HeroImage() {
  const texture = useTexture("/hero.png");
  return (
    <mesh>
      <planeGeometry args={[4.1, 5.1]} />
      <meshStandardMaterial
        map={texture}
        transparent
        alphaTest={0.05}
        side={THREE.DoubleSide}
      />
    </mesh>
  );
}

/* ─── Single glowing orbit ring ─────────────────────────────────────── */
function OrbitRing({ radius, tube, color, speed, tiltX = 0, tiltZ = 0 }) {
  const ref = useRef();
  useFrame(({ clock }) => {
    if (!ref.current) return;
    ref.current.rotation.set(tiltX, clock.elapsedTime * speed, tiltZ);
  });
  return (
    <Torus ref={ref} args={[radius, tube, 56, 180]}>
      <meshStandardMaterial
        color={color}
        emissive={color}
        emissiveIntensity={1.4}
        roughness={0.05}
        metalness={0.9}
        transparent
        opacity={0.88}
      />
    </Torus>
  );
}

/* ─── Small glowing dot that travels along an orbit path ────────────── */
function OrbitDot({ radius, speed, color, size = 0.07 }) {
  const ref = useRef();
  const angle = useRef(Math.random() * Math.PI * 2);
  useFrame((_, dt) => {
    if (!ref.current) return;
    angle.current += speed * dt;
    ref.current.position.set(
      Math.cos(angle.current) * radius,
      Math.sin(angle.current * 0.6) * 0.25,
      Math.sin(angle.current) * radius
    );
  });
  return (
    <mesh ref={ref}>
      <sphereGeometry args={[size, 26, 16]} />
      <meshStandardMaterial
        color={color}
        emissive={color}
        emissiveIntensity={2.5}
        roughness={0}
        metalness={1}
      />
    </mesh>
  );
}

/* ─── Scene composition ─────────────────────────────────────────────── */
function Scene() {
  return (
    <>
      {/* Lighting — manual setup, no external HDR download needed */}
      <ambientLight intensity={1.0} />
      <directionalLight position={[4, 6, 5]} intensity={1.6} />
      <pointLight position={[-5,  3,  4]} color={C_LIGHT}  intensity={2.8} />
      <pointLight position={[ 5, -3, -3]} color={C_ACCENT} intensity={2.2} />
      <pointLight position={[ 0,  0,  6]} color="#ffffff"  intensity={0.8} />

      {/* Deep star field */}
      <Stars radius={14} depth={7} count={400} factor={2.2} fade speed={0.5} />

      
      <Float speed={1.5} rotationIntensity={0.06} floatIntensity={0.55}>
        <group>
          {/* The user-provided hero.png */}
          <HeroImage />

          {/* Three rings at distinct tilts — inspired by Fitnect orbit rings */}
          <OrbitRing
            radius={2.05} tube={0.030}
            color={C_LIGHT}   speed={ 0.50}
            tiltX={0.30}
          />
          <OrbitRing
            radius={2.40} tube={0.022}
            color={C_ACCENT}  speed={-0.35}
            tiltX={Math.PI / 2} tiltZ={0.38}
          />
          <OrbitRing
            radius={1.82} tube={0.035}
            color={C_PRIMARY} speed={ 0.28}
            tiltX={Math.PI / 3} tiltZ={-0.55}
          />

          {/* Glowing dots travelling on each ring */}
          <OrbitDot radius={2.05} speed={ 1.0} color={C_LIGHT}   size={0.075} />
          <OrbitDot radius={2.40} speed={-0.8} color={C_ACCENT}  size={0.060} />
          <OrbitDot radius={1.82} speed={ 0.6} color={C_WHITE}   size={0.050} />
        </group>
      </Float>
    </>
  );
}

/* ─── Exported canvas wrapper ────────────────────────────────────────── */
export default function HeroScene3D() {
  return (
    <Canvas
      camera={{ position: [0, 0.6, 6.8], fov: 43 }}
      style={{ width: "100%", height: "100%" }}
      dpr={[1, 2]}
    >
      <Scene />
    </Canvas>
  );
}

