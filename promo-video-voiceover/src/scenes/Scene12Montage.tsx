import { AbsoluteFill, useCurrentFrame, useVideoConfig, spring, interpolate } from 'remotion';
import React from 'react';

/*
 * SCENE 12 — RETURN TO THE ECOSYSTEM
 * SVG icons (not emoji), Laween design language cards
 */
const FEATURES = [
  { label: 'Group Chat', color: '#006D77', d: 'M20 2H4c-1.1 0-2 .9-2 2v18l4-4h14c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2z', x: -500, y: -260, rot: -5 },
  { label: 'Media Sharing', color: '#6366f1', d: 'M21 19V5c0-1.1-.9-2-2-2H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2zM8.5 13.5l2.5 3.01L14.5 12l4.5 6H5l3.5-4.5z', x: 400, y: -200, rot: 5 },
  { label: 'Outing Session', color: '#006D77', d: 'M7 2v11h3v9l7-12h-4l4-8z', x: -600, y: -80, rot: -3 },
  { label: 'Waiting Room', color: '#f59e0b', d: 'M11.99 2C6.47 2 2 6.48 2 12s4.47 10 9.99 10C17.52 22 22 17.52 22 12S17.52 2 11.99 2zM12 20c-4.42 0-8-3.58-8-8s3.58-8 8-8 8 3.58 8 8-3.58 8-8 8zm.5-13H11v6l5.25 3.15.75-1.23-4.5-2.67z', x: 480, y: -20, rot: 6 },
  { label: 'Fair Places', color: '#ef4444', d: 'M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z', x: -480, y: 120, rot: -4 },
  { label: 'Winner', color: '#fbbf24', d: 'M19 5h-2V3H7v2H5c-1.1 0-2 .9-2 2v1c0 2.55 1.92 4.63 4.39 4.94.63 1.5 1.98 2.63 3.61 2.96V19H7v2h10v-2h-4v-3.1c1.63-.33 2.98-1.46 3.61-2.96C19.08 12.63 21 10.55 21 8V7c0-1.1-.9-2-2-2z', x: 560, y: 180, rot: 4 },
  { label: 'Live Tracker', color: '#006D77', d: 'M12 8c-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4-1.79-4-4-4zm8.94 3c-.46-4.17-3.77-7.48-7.94-7.94V1h-2v2.06C6.83 3.52 3.52 6.83 3.06 11H1v2h2.06c.46 4.17 3.77 7.48 7.94 7.94V23h2v-2.06c4.17-.46 7.48-3.77 7.94-7.94H23v-2h-2.06zM12 19c-3.87 0-7-3.13-7-7s3.13-7 7-7 7 3.13 7 7-3.13 7-7 7z', x: -400, y: 300, rot: -3 },
  { label: 'Notifications', color: '#f472b6', d: 'M12 22c1.1 0 2-.9 2-2h-4c0 1.1.9 2 2 2zm6-6v-5c0-3.07-1.63-5.64-4.5-6.32V4c0-.83-.67-1.5-1.5-1.5s-1.5.67-1.5 1.5v.68C7.64 5.36 6 7.92 6 11v5l-2 2v1h16v-1l-2-2z', x: 380, y: 360, rot: 5 },
];

const FeatureCard: React.FC<{
  item: typeof FEATURES[0]; delay: number;
}> = ({ item, delay }) => {
  const { fps } = useVideoConfig();
  const frame = useCurrentFrame();

  const entrySpring = spring({ frame: frame - delay, fps, config: { damping: 10, stiffness: 180 } });
  const scale = interpolate(entrySpring, [0, 1], [0, 1]);
  const floatY = Math.sin((frame - delay) * 0.07 + item.x * 0.01) * 4;
  const exitOp = interpolate(frame, [100, 115], [1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  return (
    <div style={{
      position: 'absolute',
      left: `calc(50% + ${item.x}px)`, top: `calc(50% + ${item.y}px)`,
      transform: `translate(-50%, -50%) translateY(${floatY}px) rotate(${item.rot}deg) scale(${scale})`,
      opacity: exitOp,
    }}>
      <div style={{
        background: `rgba(28,36,54,0.4)`,
        border: `2px solid ${item.color}50`,
        borderRadius: 24, padding: '16px 32px',
        display: 'flex', alignItems: 'center', gap: 16,
        backdropFilter: 'blur(20px)',
        boxShadow: `0 8px 32px ${item.color}20, inset 0 2px 20px rgba(255,255,255,0.05)`,
      }}>
        <div style={{
          width: 52, height: 52, borderRadius: 16,
          background: `linear-gradient(135deg, ${item.color}40, ${item.color}10)`,
          display: 'flex', justifyContent: 'center', alignItems: 'center',
          boxShadow: `inset 0 1px 4px rgba(255,255,255,0.3)`
        }}>
          <svg width="28" height="28" viewBox="0 0 24 24" fill={item.color} style={{ filter: `drop-shadow(0 0 8px ${item.color})` }}><path d={item.d}/></svg>
        </div>
        <span style={{ fontFamily: 'Outfit, system-ui, sans-serif', fontSize: 24, fontWeight: 800, color: 'white', letterSpacing: '-0.01em' }}>{item.label}</span>
      </div>
    </div>
  );
};

export const Scene12Montage: React.FC = () => {
  const { fps } = useVideoConfig();
  const frame = useCurrentFrame();

  const titleSpring = spring({ frame: frame - 18, fps, config: { damping: 14 } });
  const titleOp = interpolate(frame, [18, 30], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const titleY = interpolate(titleSpring, [0, 1], [30, 0]);
  const titleFade = interpolate(frame, [100, 115], [1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const exitOp = interpolate(frame, [112, 120], [1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  return (
    <AbsoluteFill style={{ backgroundColor: '#050714', overflow: 'hidden', opacity: exitOp }}>
      <div style={{ position: 'absolute', width: '100%', height: '100%',
        background: 'radial-gradient(ellipse at 50% 50%, rgba(0,109,119,0.08) 0%, transparent 50%)' }} />

      {FEATURES.map((f, i) => (
        <FeatureCard key={i} item={f} delay={2 + i * 4} />
      ))}

      {/* Connecting lines */}
      <svg style={{ position: 'absolute', width: '100%', height: '100%', pointerEvents: 'none', zIndex: 0 }}>
        {FEATURES.map((f, i) => {
          if (i === 0) return null;
          const prev = FEATURES[i - 1];
          // Dynamically calculate exact node centers, but apply a horizontal bounding offset
          // so the line emerges from the EDGE of the bubble, not the dead center where it would ruin the text.
          const xOffset = 140;
          const p1x = 960 + prev.x + (prev.x < 0 ? xOffset : -xOffset);
          const p1y = 540 + prev.y;
          const p2x = 960 + f.x + (f.x < 0 ? xOffset : -xOffset);
          const p2y = 540 + f.y;
          
          // Animate line tracing in sync with the second node's appearance
          const delay = 2 + i * 4;
          const lineSpring = spring({ frame: frame - delay, fps, config: { damping: 14 } });
          const lineOp = interpolate(lineSpring, [0, 1], [0, 0.4]);
          
          return (
            <line key={`line-${i}`} x1={p1x} y1={p1y} x2={p2x} y2={p2y} stroke={f.color} strokeWidth="3" strokeDasharray="12 12" opacity={lineOp} />
          );
        })}
      </svg>

      <div style={{
        position: 'absolute', top: '5%', width: '100%', textAlign: 'center',
        opacity: titleOp * titleFade, transform: `translateY(${titleY}px)`,
      }}>
        <h1 style={{ fontFamily: 'Outfit, system-ui, sans-serif', fontSize: 64, fontWeight: 900, color: 'white', margin: 0,
          textShadow: '0 4px 30px rgba(0,109,119,0.3)', letterSpacing: '-0.02em', lineHeight: 1.15 }}>
          One app. One flow.
        </h1>
        <p style={{ fontFamily: 'Inter, system-ui, sans-serif', fontSize: 30, fontWeight: 700, color: '#83C5BE', margin: '14px 0 0' }}>
          Everyone together.
        </p>
      </div>
    </AbsoluteFill>
  );
};
