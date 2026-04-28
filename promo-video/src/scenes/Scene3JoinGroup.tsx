import { AbsoluteFill, interpolate, useCurrentFrame, useVideoConfig, spring } from 'remotion';
import React from 'react';

/*
 *  Scene 3 — START OUTING
 *  Two floating option cards directly on dark canvas matching the exact app UI:
 *  - Exact icon circles, font weights, colors, and chevron from the real app
 *  - Toggle animation between the two cards
 */
export const Scene3JoinGroup: React.FC = () => {
  const { fps } = useVideoConfig();
  const frame = useCurrentFrame();

  // ── Cards entry ──
  const card1Start = 8;
  const card1Spring = spring({ frame: frame - card1Start, fps, config: { damping: 13, mass: 0.9 } });
  const card1Y = interpolate(card1Spring, [0, 1], [80, 0]);
  const card1Op = interpolate(card1Spring, [0, 0.4], [0, 1]);

  const card2Start = 16;
  const card2Spring = spring({ frame: frame - card2Start, fps, config: { damping: 13, mass: 0.9 } });
  const card2Y = interpolate(card2Spring, [0, 1], [80, 0]);
  const card2Op = interpolate(card2Spring, [0, 0.4], [0, 1]);

  // ── Toggle: first active → second active ──
  const toggleFrame = 48;
  const isFirstActive = frame < toggleFrame;

  // Tap press animations
  const tap1Scale = (frame >= 28 && frame < 34)
    ? interpolate(frame, [28, 31, 34], [1, 0.96, 1], { extrapolateRight: 'clamp' })
    : 1;
  const tap2Scale = (frame >= toggleFrame - 4 && frame < toggleFrame + 2)
    ? interpolate(frame, [toggleFrame - 4, toggleFrame - 1, toggleFrame + 2], [1, 0.96, 1], { extrapolateRight: 'clamp' })
    : 1;

  // Floating hover
  const hoverY = Math.sin(frame * 0.05) * 4;

  // ── Title ──
  const titleStart = 20;
  const titleSpring = spring({ frame: frame - titleStart, fps, config: { damping: 14 } });
  const titleY = interpolate(titleSpring, [0, 1], [40, 0]);
  const titleOp = interpolate(frame, [titleStart, titleStart + 12], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  // ── Scene exit ──
  const exitStart = 78;
  const exitSpring = spring({ frame: frame - exitStart, fps, config: { damping: 12 } });
  const exitScale = interpolate(exitSpring, [0, 1], [1, 0.85]);
  const exitOp = interpolate(exitSpring, [0, 0.5], [1, 0]);

  return (
    <AbsoluteFill style={{
      backgroundColor: '#050714',
      justifyContent: 'center',
      alignItems: 'center',
      transform: `scale(${exitScale})`,
      opacity: exitOp,
    }}>

      {/* Ambient glow */}
      <div style={{
        position: 'absolute', width: '100%', height: '100%',
        background: isFirstActive
          ? 'radial-gradient(ellipse at 50% 40%, rgba(20,184,166,0.10) 0%, transparent 55%)'
          : 'radial-gradient(ellipse at 50% 40%, rgba(245,158,11,0.10) 0%, transparent 55%)',
      }} />

      {/* Subtle grid dots */}
      <div style={{
        position: 'absolute', width: '100%', height: '100%',
        backgroundImage: 'radial-gradient(rgba(255,255,255,0.03) 1px, transparent 1px)',
        backgroundSize: '40px 40px',
      }} />

      {/* ══════ CARDS ══════ */}
      <div style={{
        display: 'flex', flexDirection: 'column', gap: 20, alignItems: 'center',
        transform: `translateY(${hoverY - 30}px)`,
      }}>

        {/* ── Card 1: Find Midpoint (exact app UI) ── */}
        <div style={{
          width: 460, padding: '24px 24px',
          borderRadius: 24, // rounded square shape matching original form
          display: 'flex', alignItems: 'center', gap: 18,
          background: isFirstActive ? '#e6f5f3' : 'rgba(230,245,243,0.08)',
          border: isFirstActive ? '2.5px solid #14b8a6' : '2.5px solid rgba(20,184,166,0.15)',
          boxShadow: isFirstActive
            ? '0 0 40px rgba(20,184,166,0.25), 0 20px 50px rgba(0,0,0,0.4)'
            : '0 10px 30px rgba(0,0,0,0.3)',
          transform: `translateY(${card1Y}px) scale(${tap1Scale})`,
          opacity: card1Op,
          position: 'relative', overflow: 'hidden',
          fontFamily: 'Inter, sans-serif',
        }}>
          {/* Active shimmer */}
          {isFirstActive && (
            <div style={{
              position: 'absolute', top: 0, left: -100, width: 80, height: '100%',
              background: 'linear-gradient(90deg, transparent, rgba(255,255,255,0.25), transparent)',
              transform: `translateX(${interpolate(frame % 90, [0, 90], [0, 700])}px) skewX(-20deg)`,
            }} />
          )}

          {/* Icon Circle — teal with sparkle stars (matching app exactly) */}
          <div style={{
            width: 58, height: 58, borderRadius: 29,
            background: isFirstActive
              ? 'linear-gradient(135deg, #b2dfdb, #80cbc4)'
              : 'rgba(178,223,219,0.15)',
            display: 'flex', justifyContent: 'center', alignItems: 'center',
            flexShrink: 0,
            boxShadow: isFirstActive ? '0 4px 16px rgba(20,184,166,0.3)' : 'none',
          }}>
            {/* SVG sparkle stars matching the app icon */}
            <svg width="28" height="28" viewBox="0 0 24 24" fill="none">
              <path d="M12 2L13.5 8.5L20 10L13.5 11.5L12 18L10.5 11.5L4 10L10.5 8.5L12 2Z" 
                fill={isFirstActive ? '#0d7377' : '#4a6a6c'} />
              <path d="M19 14L19.75 16.25L22 17L19.75 17.75L19 20L18.25 17.75L16 17L18.25 16.25L19 14Z" 
                fill={isFirstActive ? '#0d7377' : '#4a6a6c'} />
            </svg>
          </div>

          {/* Text */}
          <div style={{ flex: 1 }}>
            <h3 style={{
              margin: 0, fontSize: 24, fontWeight: 800,
              color: isFirstActive ? '#1a2e35' : '#94a3b8',
            }}>
              Find Midpoint
            </h3>
            <p style={{
              margin: '4px 0 0', fontSize: 16,
              color: isFirstActive ? '#6b8a8e' : '#475569',
              fontWeight: 500,
            }}>
              The fairest spot for everyone
            </p>
          </div>

          {/* Chevron */}
          <span style={{
            fontSize: 28, fontWeight: 300,
            color: isFirstActive ? '#14b8a6' : '#334155',
          }}>›</span>
        </div>

        {/* ── Card 2: Specific Place (exact app UI) ── */}
        <div style={{
          width: 460, padding: '24px 24px',
          borderRadius: 24, // rounded square shape matching original form
          display: 'flex', alignItems: 'center', gap: 18,
          background: !isFirstActive ? '#fef7e8' : 'rgba(254,247,232,0.08)',
          border: !isFirstActive ? '2.5px solid #f59e0b' : '2.5px solid rgba(245,158,11,0.15)',
          boxShadow: !isFirstActive
            ? '0 0 40px rgba(245,158,11,0.25), 0 20px 50px rgba(0,0,0,0.4)'
            : '0 10px 30px rgba(0,0,0,0.3)',
          transform: `translateY(${card2Y}px) scale(${tap2Scale})`,
          opacity: card2Op,
          position: 'relative', overflow: 'hidden',
          fontFamily: 'Inter, sans-serif',
        }}>
          {/* Active shimmer */}
          {!isFirstActive && (
            <div style={{
              position: 'absolute', top: 0, left: -100, width: 80, height: '100%',
              background: 'linear-gradient(90deg, transparent, rgba(255,255,255,0.25), transparent)',
              transform: `translateX(${interpolate(frame % 90, [0, 90], [0, 700])}px) skewX(-20deg)`,
            }} />
          )}

          {/* Icon Circle — warm amber with location pin (matching app exactly) */}
          <div style={{
            width: 58, height: 58, borderRadius: 29,
            background: !isFirstActive
              ? 'linear-gradient(135deg, #fde68a, #fbbf24)'
              : 'rgba(253,230,138,0.15)',
            display: 'flex', justifyContent: 'center', alignItems: 'center',
            flexShrink: 0,
            boxShadow: !isFirstActive ? '0 4px 16px rgba(245,158,11,0.3)' : 'none',
          }}>
            {/* SVG location pin matching the app */}
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
              <path d="M12 2C8.13 2 5 5.13 5 9C5 14.25 12 22 12 22C12 22 19 14.25 19 9C19 5.13 15.87 2 12 2ZM12 11.5C10.62 11.5 9.5 10.38 9.5 9C9.5 7.62 10.62 6.5 12 6.5C13.38 6.5 14.5 7.62 14.5 9C14.5 10.38 13.38 11.5 12 11.5Z" 
                fill={!isFirstActive ? '#d97706' : '#8a7a5a'} />
            </svg>
          </div>

          {/* Text */}
          <div style={{ flex: 1 }}>
            <h3 style={{
              margin: 0, fontSize: 24, fontWeight: 800,
              color: !isFirstActive ? '#3d2e0a' : '#94a3b8',
            }}>
              Specific Place
            </h3>
            <p style={{
              margin: '4px 0 0', fontSize: 16,
              color: !isFirstActive ? '#8a7a5a' : '#475569',
              fontWeight: 500,
            }}>
              I know where we're going
            </p>
          </div>

          {/* Chevron */}
          <span style={{
            fontSize: 28, fontWeight: 300,
            color: !isFirstActive ? '#d97706' : '#334155',
          }}>›</span>
        </div>

        {/* Active indicator dots */}
        <div style={{ display: 'flex', gap: 10, marginTop: 10 }}>
          <div style={{
            width: isFirstActive ? 28 : 10, height: 10, borderRadius: 5,
            background: isFirstActive ? '#14b8a6' : 'rgba(255,255,255,0.15)',
          }} />
          <div style={{
            width: !isFirstActive ? 28 : 10, height: 10, borderRadius: 5,
            background: !isFirstActive ? '#f59e0b' : 'rgba(255,255,255,0.15)',
          }} />
        </div>
      </div>

      {/* ══════ BOTTOM HEADLINE ══════ */}
      <div style={{
        position: 'absolute', bottom: '10%',
        display: 'flex', flexDirection: 'column', alignItems: 'center',
        transform: `translateY(${titleY}px)`, opacity: titleOp,
      }}>
        <h1 style={{
          fontFamily: 'Inter, sans-serif', fontSize: 56, fontWeight: 900, color: 'white',
          margin: 0, textAlign: 'center',
        }}>
          Start Outing
        </h1>
        <p style={{
          fontFamily: 'Inter, sans-serif', fontSize: 24,
          color: '#94a3b8', fontWeight: 500,
          margin: '10px 0 0 0', textAlign: 'center',
        }}>
          How would you like to plan today?
        </p>
      </div>
    </AbsoluteFill>
  );
};
