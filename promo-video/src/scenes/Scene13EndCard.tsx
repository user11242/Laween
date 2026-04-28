import { AbsoluteFill, useCurrentFrame, useVideoConfig, spring, interpolate, Img, staticFile } from 'remotion';
import React from 'react';

/*
 * SCENE 13 — END CARD
 * 150 frames (5s) — Calm, confident brand finish.
 * Unified title system: logo → wordmark → tagline.
 */
export const Scene13EndCard: React.FC = () => {
  const { fps } = useVideoConfig();
  const frame = useCurrentFrame();

  // Logo entry
  const logoSpring = spring({ frame: frame - 15, fps, config: { damping: 12, stiffness: 100 } });
  const logoScale = interpolate(logoSpring, [0, 1], [0.6, 1]);
  const logoOp = interpolate(frame, [15, 30], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  // Wordmark
  const wordSpring = spring({ frame: frame - 35, fps, config: { damping: 14 } });
  const wordOp = interpolate(frame, [35, 50], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const wordY = interpolate(wordSpring, [0, 1], [20, 0]);

  // Tagline
  const tagOp = interpolate(frame, [55, 72], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const tagY = interpolate(spring({ frame: frame - 55, fps, config: { damping: 16 } }), [0, 1], [16, 0]);

  // Ambient pulse
  const pulse = 0.06 + Math.sin(frame * 0.035) * 0.03;

  // Subtle fade out at very end
  const exitOp = interpolate(frame, [140, 150], [1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  return (
    <AbsoluteFill style={{
      backgroundColor: '#050714',
      justifyContent: 'center', alignItems: 'center',
      opacity: exitOp,
    }}>
      {/* Ambient glow */}
      <div style={{
        position: 'absolute', width: '100%', height: '100%',
        background: `radial-gradient(ellipse at 50% 45%, rgba(20,184,166,${pulse}) 0%, transparent 50%)`,
      }} />

      {/* Outer rings */}
      <div style={{
        position: 'absolute',
        width: 840, height: 840, borderRadius: 420,
        border: '1px solid rgba(20,184,166,0.06)',
        opacity: interpolate(frame, [25, 50], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' }),
      }} />
      <div style={{
        position: 'absolute',
        width: 570, height: 570, borderRadius: 285,
        border: '1px solid rgba(20,184,166,0.1)',
        opacity: interpolate(frame, [30, 55], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' }),
      }} />
      <div style={{
        position: 'absolute',
        width: 330, height: 330, borderRadius: 165,
        border: '1px solid rgba(20,184,166,0.08)',
        opacity: interpolate(frame, [35, 60], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' }),
      }} />

      {/* Logo */}
      <div style={{
        display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 20,
        transform: `scale(${logoScale})`, opacity: logoOp,
      }}>
        <Img src={staticFile('app_pin_logo.png')} style={{
          width: 210, height: 210,
          filter: `drop-shadow(0 10px 40px rgba(20,184,166,0.45))`,
        }} />
      </div>

      {/* Wordmark */}
      <div style={{
        position: 'absolute', top: '58%',
        width: '100%', textAlign: 'center',
        opacity: wordOp, transform: `translateY(${wordY}px)`,
      }}>
        <h1 style={{
          fontFamily: 'Inter, system-ui, sans-serif', fontSize: 120, fontWeight: 900,
          color: 'white', margin: 0, letterSpacing: '-0.03em',
          textShadow: '0 4px 40px rgba(20,184,166,0.3)',
        }}>
          Laween
        </h1>
      </div>

      {/* Tagline */}
      <div style={{
        position: 'absolute', top: '75%',
        width: '100%', textAlign: 'center',
        opacity: tagOp, transform: `translateY(${tagY}px)`,
      }}>
        <p style={{
          fontFamily: 'Inter, system-ui, sans-serif', fontSize: 42, fontWeight: 500,
          color: '#94a3b8', margin: 0, letterSpacing: '0.01em',
        }}>
          From chat to meetup, seamlessly.
        </p>
      </div>

      {/* Bottom teal accent line */}
      <div style={{
        position: 'absolute', bottom: 0, left: 0, right: 0, height: 3,
        background: 'linear-gradient(90deg, transparent 20%, #14b8a6 50%, transparent 80%)',
        opacity: interpolate(frame, [60, 85], [0, 0.5], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' }),
      }} />
    </AbsoluteFill>
  );
};
