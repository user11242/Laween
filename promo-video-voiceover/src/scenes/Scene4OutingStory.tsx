import { AbsoluteFill, interpolate, useCurrentFrame, useVideoConfig, spring } from 'remotion';
import React from 'react';
import { PhoneMockup } from '../components/PhoneMockup';

/*
 *  Scene 4 — DESTINATION LOCKED
 *  Pixel-perfect recreation of locked_outing_screen.jpeg.
 *  Shows the Laween chat interface with multiple "Outing Session / Destination Locked"
 *  cards stacking in a real group chat, inside a premium phone mockup.
 */

const OutingCard: React.FC<{
  delay: number; frame: number; fps: number; showButton?: boolean;
}> = ({ delay, frame, fps, showButton = true }) => {
  const pop = spring({ frame: frame - delay, fps, config: { damping: 14 } });
  const scale = interpolate(pop, [0, 1], [0.85, 1]);
  const opacity = interpolate(pop, [0, 0.3], [0, 1]);

  return (
    <div style={{
      background: 'white',
      borderRadius: 22,
      padding: '20px 18px',
      width: '78%',
      marginLeft: 52,
      marginBottom: 14,
      boxShadow: '0 4px 16px rgba(0,0,0,0.06)',
      transform: `scale(${scale})`,
      opacity,
      transformOrigin: 'top left',
    }}>
      <div style={{ display: 'flex', alignItems: 'center', marginBottom: 14 }}>
        <div style={{
          width: 42, height: 42, borderRadius: 21,
          background: '#ffe4e6',
          display: 'flex', justifyContent: 'center', alignItems: 'center',
          marginRight: 12,
        }}>
          <span style={{ fontSize: 20 }}>📍</span>
        </div>
        <span style={{ fontFamily: 'Inter', fontSize: 20, fontWeight: 800, color: '#1e293b' }}>
          Outing Session
        </span>
      </div>
      <p style={{
        fontFamily: 'Inter', fontSize: 17, fontWeight: 700,
        color: '#0d9488', margin: '0 0 14px',
      }}>
        Destination Locked
      </p>
      {showButton && (
        <>
          <div style={{ width: '100%', height: 1, background: '#f1f5f9', marginBottom: 14 }} />
          <div style={{
            width: '100%', background: '#115e59',
            borderRadius: 30, padding: '14px 0',
            textAlign: 'center', fontFamily: 'Inter',
            fontSize: 18, fontWeight: 700, color: 'white',
            boxShadow: '0 6px 16px rgba(17,94,89,0.25)',
          }}>
            Winner
          </div>
        </>
      )}
    </div>
  );
};

export const Scene4OutingStory: React.FC = () => {
  const { fps } = useVideoConfig();
  const frame = useCurrentFrame();

  // ── Title ──
  const titleSpring = spring({ frame: frame - 3, fps, config: { damping: 14 } });
  const titleY = interpolate(titleSpring, [0, 1], [50, 0]);
  const titleOp = interpolate(frame, [3, 14], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  // ── Phone entry ──
  const phoneStart = 8;
  const phoneSpring = spring({ frame: frame - phoneStart, fps, config: { damping: 14, mass: 1 } });
  const phoneY = interpolate(phoneSpring, [0, 1], [600, 0]);
  const phoneOp = interpolate(frame, [phoneStart, phoneStart + 12], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const floatY = Math.sin(frame * 0.05) * 5;

  // ── Auto-scroll the chat upward to reveal more cards ──
  const scrollStart = 45;
  const scrollY = interpolate(frame, [scrollStart, scrollStart + 60], [0, -120], {
    extrapolateLeft: 'clamp', extrapolateRight: 'clamp',
  });

  // ── Scene exit ──
  const exitStart = 105;
  const exitSpring = spring({ frame: frame - exitStart, fps, config: { damping: 12 } });
  const exitY = interpolate(exitSpring, [0, 1], [0, 1200]);
  const exitOp = interpolate(exitSpring, [0, 0.5], [1, 0]);

  return (
    <AbsoluteFill style={{
      backgroundColor: '#050714',
      justifyContent: 'center',
      alignItems: 'center',
      transform: `translateY(${exitY}px)`,
      opacity: exitOp,
    }}>

      {/* Ambient glow */}
      <div style={{
        position: 'absolute', width: '100%', height: '100%',
        background: 'radial-gradient(ellipse at 50% 40%, rgba(139,92,246,0.12) 0%, transparent 65%)',
      }} />

      {/* Title */}
      <div style={{
        position: 'absolute', top: '6%',
        display: 'flex', flexDirection: 'column', alignItems: 'center',
        transform: `translateY(${titleY}px)`, opacity: titleOp,
      }}>
        <h1 style={{
          fontFamily: 'Inter, sans-serif', fontSize: 78, fontWeight: 900, color: 'white',
          margin: 0, letterSpacing: '-0.03em',
          textShadow: '0 8px 40px rgba(139,92,246,0.4)',
        }}>
          Locked & Loaded
        </h1>
        <p style={{
          fontFamily: 'Inter, sans-serif', fontSize: 26, color: '#c4b5fd', fontWeight: 600,
          margin: '14px 0 0 0', letterSpacing: '0.02em',
          opacity: interpolate(frame, [10, 22], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' }),
        }}>
          Everyone picks. The app decides.
        </p>
      </div>

      {/* Phone */}
      <div style={{
        transform: `translateY(${phoneY + floatY}px)`,
        opacity: phoneOp,
        marginTop: 60,
      }}>
        <PhoneMockup screenStyle={{ backgroundColor: '#f5f5f5' }}>
          {/* Chat Header Bar */}
          <div style={{
            position: 'absolute', top: 0, left: 0, right: 0,
            height: 100, zIndex: 20,
            background: 'linear-gradient(180deg, #f5f5f5 70%, transparent)',
            display: 'flex', alignItems: 'flex-end', padding: '0 18px 10px',
          }}>
            <span style={{ fontFamily: 'Inter', fontSize: 14, color: '#94a3b8', marginRight: 12 }}>←</span>
            <div style={{
              width: 38, height: 38, borderRadius: 19,
              background: 'linear-gradient(135deg, #0d9488, #14b8a6)',
              display: 'flex', justifyContent: 'center', alignItems: 'center',
              marginRight: 10,
            }}>
              <span style={{ fontSize: 18 }}>👥</span>
            </div>
            <div>
              <p style={{ fontFamily: 'Inter', fontSize: 16, fontWeight: 700, color: '#1e293b', margin: 0 }}>خليها على الله</p>
              <p style={{ fontFamily: 'Inter', fontSize: 12, color: '#94a3b8', margin: 0 }}>3 members</p>
            </div>
          </div>

          {/* Scrolling chat content */}
          <div style={{
            position: 'absolute', top: 100, left: 0, right: 0, bottom: 70,
            overflow: 'hidden',
          }}>
            <div style={{ padding: '16px 14px', transform: `translateY(${scrollY}px)` }}>
              {/* User label */}
              <div style={{ display: 'flex', alignItems: 'center', marginBottom: 6, marginLeft: 4 }}>
                <div style={{ width: 32, height: 32, borderRadius: 16, background: '#94a3b8', marginRight: 8 }} />
                <div>
                  <span style={{ fontFamily: 'Inter', fontSize: 11, color: '#94a3b8' }}>11:13 PM</span><br/>
                  <span style={{ fontFamily: 'Inter', fontSize: 13, fontWeight: 700, color: '#0d9488' }}>yazan Akq</span>
                </div>
              </div>

              <OutingCard delay={18} frame={frame} fps={fps} showButton={true} />

              <div style={{ display: 'flex', alignItems: 'center', marginBottom: 6, marginLeft: 4 }}>
                <div style={{ width: 32, height: 32, borderRadius: 16, background: '#94a3b8', marginRight: 8 }} />
                <div>
                  <span style={{ fontFamily: 'Inter', fontSize: 11, color: '#94a3b8' }}>11:17 PM</span><br/>
                  <span style={{ fontFamily: 'Inter', fontSize: 13, fontWeight: 700, color: '#0d9488' }}>yazan Akq</span>
                </div>
              </div>

              <OutingCard delay={35} frame={frame} fps={fps} showButton={true} />

              <div style={{ display: 'flex', alignItems: 'center', marginBottom: 6, marginLeft: 4 }}>
                <div style={{ width: 32, height: 32, borderRadius: 16, background: '#94a3b8', marginRight: 8 }} />
                <div>
                  <span style={{ fontFamily: 'Inter', fontSize: 11, color: '#94a3b8' }}>11:22 PM</span><br/>
                  <span style={{ fontFamily: 'Inter', fontSize: 13, fontWeight: 700, color: '#0d9488' }}>yazan Akq</span>
                </div>
              </div>

              <OutingCard delay={55} frame={frame} fps={fps} showButton={false} />
            </div>
          </div>

          {/* Chat input bar */}
          <div style={{
            position: 'absolute', bottom: 0, left: 0, right: 0, height: 70,
            background: 'white', borderTop: '1px solid #f1f5f9',
            display: 'flex', alignItems: 'center', padding: '0 14px', gap: 10,
          }}>
            <div style={{
              width: 36, height: 36, borderRadius: 18,
              border: '2px solid #e2e8f0', display: 'flex', justifyContent: 'center', alignItems: 'center',
            }}>
              <span style={{ fontSize: 22, color: '#94a3b8' }}>+</span>
            </div>
            <div style={{
              flex: 1, background: '#f8fafc', borderRadius: 22,
              padding: '12px 16px', fontFamily: 'Inter', fontSize: 15, color: '#cbd5e1',
            }}>
              Type a message...
            </div>
            <div style={{
              width: 44, height: 44, borderRadius: 22,
              background: 'linear-gradient(135deg, #14b8a6, #0d9488)',
              display: 'flex', justifyContent: 'center', alignItems: 'center',
            }}>
              <span style={{ fontSize: 20, color: 'white' }}>▶</span>
            </div>
          </div>
        </PhoneMockup>
      </div>
    </AbsoluteFill>
  );
};
