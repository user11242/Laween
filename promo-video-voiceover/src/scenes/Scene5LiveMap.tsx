import { AbsoluteFill, interpolate, useCurrentFrame, useVideoConfig, spring, Img, staticFile } from 'remotion';
import React from 'react';
import { PhoneMockup } from '../components/PhoneMockup';

/*
 *  Scene 5 — LIVE MAP TRACKING
 *  The live_map_tracking.jpeg screenshot inside a tilted phone mockup
 *  with cinematic 3D parallax, pulsing GPS rings, and ambient glow effects.
 */
export const Scene5LiveMap: React.FC = () => {
  const { fps } = useVideoConfig();
  const frame = useCurrentFrame();

  // ── Title ──
  const titleSpring = spring({ frame: frame - 3, fps, config: { damping: 14 } });
  const titleY = interpolate(titleSpring, [0, 1], [50, 0]);
  const titleOp = interpolate(frame, [3, 14], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  // ── Phone entry ──
  const phoneStart = 10;
  const phoneSpring = spring({ frame: frame - phoneStart, fps, config: { damping: 13, mass: 1.2 } });
  const phoneScale = interpolate(phoneSpring, [0, 1], [0.6, 1]);
  const phoneOp = interpolate(frame, [phoneStart, phoneStart + 12], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  // ── 3D Parallax: slow cinematic rotation ──
  const rotX = interpolate(frame, [phoneStart, phoneStart + 130], [35, 15], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' });
  const rotY = interpolate(frame, [phoneStart, phoneStart + 130], [-8, 5], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' });

  // ── GPS Pulse rings (multiple staggered) ──
  const pulse1 = interpolate(frame % 60, [0, 60], [0, 3], { extrapolateRight: 'clamp' });
  const pulse1Op = interpolate(frame % 60, [0, 30, 60], [0.8, 0.4, 0], { extrapolateRight: 'clamp' });
  const pulse2 = interpolate((frame + 30) % 60, [0, 60], [0, 3], { extrapolateRight: 'clamp' });
  const pulse2Op = interpolate((frame + 30) % 60, [0, 30, 60], [0.8, 0.4, 0], { extrapolateRight: 'clamp' });

  // ── Scene exit ──
  const exitStart = 135;
  const exitSpring = spring({ frame: frame - exitStart, fps, config: { damping: 12 } });
  const exitScale = interpolate(exitSpring, [0, 1], [1, 0.6]);
  const exitOp = interpolate(exitSpring, [0, 0.5], [1, 0]);

  return (
    <AbsoluteFill style={{
      backgroundColor: '#050714',
      justifyContent: 'center',
      alignItems: 'center',
      transform: `scale(${exitScale})`,
      opacity: exitOp,
      perspective: 1400,
    }}>

      {/* Ambient map glow (golden) */}
      <div style={{
        position: 'absolute', width: '150%', height: '150%',
        background: 'radial-gradient(ellipse at 50% 60%, rgba(234,179,8,0.12) 0%, transparent 55%)',
      }} />

      {/* Title */}
      <div style={{
        position: 'absolute', top: '5%',
        display: 'flex', flexDirection: 'column', alignItems: 'center',
        transform: `translateY(${titleY}px)`, opacity: titleOp, zIndex: 10,
      }}>
        <h1 style={{
          fontFamily: 'Inter, sans-serif', fontSize: 78, fontWeight: 900, color: 'white',
          margin: 0, letterSpacing: '-0.03em',
          textShadow: '0 8px 40px rgba(234,179,8,0.45)',
        }}>
          Never Get Lost
        </h1>
        <p style={{
          fontFamily: 'Inter, sans-serif', fontSize: 26, color: '#fde68a', fontWeight: 600,
          margin: '14px 0 0 0', letterSpacing: '0.02em',
          opacity: interpolate(frame, [10, 22], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' }),
        }}>
          Real-time tracking for every member
        </p>
      </div>

      {/* 3D Tilted Phone with Map */}
      <div style={{
        transform: `scale(${phoneScale}) rotateX(${rotX}deg) rotateY(${rotY}deg)`,
        opacity: phoneOp,
        transformStyle: 'preserve-3d',
        marginTop: 50,
      }}>
        <PhoneMockup scale={1.85}>
          <Img
            src={staticFile('live_map_tracking.jpeg')}
            style={{ width: '100%', height: '100%', objectFit: 'cover' }}
          />

          {/* GPS Pulse overlay */}
          {frame > phoneStart + 15 && (
            <div style={{
              position: 'absolute', top: '42%', left: '48%',
              transform: 'translate(-50%, -50%)',
              width: 0, height: 0,
              display: 'flex', justifyContent: 'center', alignItems: 'center',
            }}>
              {/* Center dot */}
              <div style={{
                position: 'absolute',
                width: 14, height: 14, borderRadius: 7,
                background: '#eab308',
                boxShadow: '0 0 20px #eab308, 0 0 40px rgba(234,179,8,0.4)',
                zIndex: 5
              }} />

              {/* Ring 1 */}
              <div style={{
                position: 'absolute',
                width: 60, height: 60, borderRadius: 30,
                border: '2px solid rgba(234,179,8,0.6)',
                transform: `scale(${pulse1})`,
                opacity: pulse1Op,
              }} />

              {/* Ring 2 */}
              <div style={{
                position: 'absolute',
                width: 60, height: 60, borderRadius: 30,
                border: '2px solid rgba(234,179,8,0.4)',
                transform: `scale(${pulse2})`,
                opacity: pulse2Op,
              }} />
            </div>
          )}

          {/* Vignette for depth */}
          <div style={{
            position: 'absolute', inset: 0,
            boxShadow: 'inset 0 0 80px rgba(0,0,0,0.5)',
            pointerEvents: 'none',
          }} />
        </PhoneMockup>
      </div>
    </AbsoluteFill>
  );
};
