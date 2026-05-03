import { AbsoluteFill, useCurrentFrame, useVideoConfig, spring, interpolate } from 'remotion';
import React from 'react';
import { PhoneMockup } from '../components/PhoneMockup';
import { WeekendChat } from '../components/WeekendChat';

/*
 * SCENE 7 — WAITING ROOM → LOCKED OUTING
 * Multi-user: 1/8 → 3/8 → 5/8 → 8/8 joined, 8 avatars cascade in
 * Then snap to locked outing card in chat (multiple outing cards visible)
 */

const MEMBERS = [
  { letter: 'S', name: 'Sarah', color: '#a78bfa' },
  { letter: 'Y', name: 'Yazan', color: '#14b8a6' },
  { letter: 'O', name: 'Omar', color: '#3b82f6' },
  { letter: 'L', name: 'Lina', color: '#f472b6' },
  { letter: 'A', name: 'Ahmed', color: '#f59e0b' },
  { letter: 'N', name: 'Noor', color: '#ef4444' },
  { letter: 'R', name: 'Rami', color: '#6366f1' },
  { letter: 'D', name: 'Dana', color: '#ec4899' },
];

export const Scene7WaitingRoom: React.FC = () => {
  const { fps } = useVideoConfig();
  const frame = useCurrentFrame();

  const waitEnd = 100;
  const lockedStart = 106;

  const phoneSpring = spring({ frame: frame - 3, fps, config: { damping: 14 } });
  const phoneScale = interpolate(phoneSpring, [0, 1], [0.92, 1]);

  // Countdown
  const countdown = Math.max(0, Math.ceil(interpolate(frame, [10, waitEnd - 10], [5, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' })));

  // Progressive avatar joins — staggered entries, slightly slower for readability
  const joinFrames = [10, 18, 26, 36, 46, 58, 70, 84];
  const joinedCount = joinFrames.filter(f => frame >= f).length;

  // Locked outing entry
  const lockedSpring = spring({ frame: frame - lockedStart, fps, config: { damping: 12 } });
  const lockedOp = interpolate(frame, [lockedStart, lockedStart + 6], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const waitOp = interpolate(frame, [waitEnd, waitEnd + 5], [1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  const title1Op = interpolate(frame, [8, 18], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const title1Fade = interpolate(frame, [waitEnd - 5, waitEnd + 3], [1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const title2Op = interpolate(frame, [lockedStart + 5, lockedStart + 15], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const title2Fade = interpolate(frame, [168, 178], [1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const exitOp = interpolate(frame, [172, 180], [1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  // Session locked flash
  const lockedFlash = countdown === 0 && frame < waitEnd;
  const flashPulse = lockedFlash ? 0.15 + Math.sin(frame * 0.3) * 0.1 : 0;

  return (
    <AbsoluteFill style={{ backgroundColor: '#050714', justifyContent: 'center', alignItems: 'center', opacity: exitOp }}>
      <div style={{ position: 'absolute', width: '100%', height: '100%',
        background: `radial-gradient(ellipse at 50% 45%, rgba(20,184,166,${0.07 + flashPulse}) 0%, transparent 55%)` }} />

      {/* Phase 1 Title */}
      <div style={{
        position: 'absolute', top: '5%', width: '100%', textAlign: 'center',
        opacity: title1Op * title1Fade, zIndex: 20,
      }}>
        <h1 style={{ fontFamily: 'Inter, system-ui, sans-serif', fontSize: 64, fontWeight: 900, color: 'white', margin: 0, letterSpacing: '-0.02em', lineHeight: 1.15 }}>
          Everyone joins. Laween calculates.
        </h1>
        <p style={{ fontFamily: 'Inter, system-ui, sans-serif', fontSize: 30, color: '#5eead4', fontWeight: 600, margin: '14px 0 0' }}>
          Locations come together in real time.
        </p>
      </div>

      {/* Phase 2 Title */}
      <div style={{
        position: 'absolute', top: '5%', width: '100%', textAlign: 'center',
        opacity: title2Op * title2Fade, zIndex: 20,
      }}>
        <h1 style={{ fontFamily: 'Inter, system-ui, sans-serif', fontSize: 64, fontWeight: 900, color: 'white', margin: 0, letterSpacing: '-0.02em', lineHeight: 1.15 }}>
          Session locked.
        </h1>
        <p style={{ fontFamily: 'Inter, system-ui, sans-serif', fontSize: 30, color: '#5eead4', fontWeight: 600, margin: '14px 0 0' }}>
          Time to decide.
        </p>
      </div>

      <div style={{ transform: `scale(${phoneScale}) translateY(80px)` }}>
        <PhoneMockup scale={0.95} drift>
          {/* ── WAITING ROOM ── */}
          <div style={{
            position: 'absolute', inset: 0, background: 'linear-gradient(180deg, #0f172a, #0a0f1e)',
            opacity: waitOp,
            display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
          }}>
            {/* Timer circle */}
            <div style={{
              width: 160, height: 160, borderRadius: 80,
              border: '4px solid rgba(20,184,166,0.15)',
              display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center',
              position: 'relative', marginBottom: 24,
            }}>
              <svg width="160" height="160" viewBox="0 0 160 160" style={{ position: 'absolute' }}>
                <circle cx="80" cy="80" r="76" fill="none" stroke="rgba(20,184,166,0.08)" strokeWidth="4" />
                <circle cx="80" cy="80" r="76" fill="none" stroke="#14b8a6" strokeWidth="4"
                  strokeDasharray={`${2 * Math.PI * 76}`}
                  strokeDashoffset={`${2 * Math.PI * 76 * (countdown / 5)}`}
                  strokeLinecap="round" transform="rotate(-90 80 80)" />
              </svg>
              <span style={{
                fontFamily: 'Inter', fontSize: 56, fontWeight: 800, color: countdown === 0 ? '#14b8a6' : 'white',
              }}>{countdown === 0 ? '✓' : countdown}</span>
              <span style={{ fontFamily: 'Inter', fontSize: 14, color: '#94a3b8', fontWeight: 500 }}>
                {countdown === 0 ? 'Locked!' : 'seconds'}
              </span>
            </div>

            {/* Join label with animated count */}
            <p style={{
              fontFamily: 'Inter', fontSize: 16, fontWeight: 600, color: '#5eead4',
              letterSpacing: '0.08em', margin: '0 0 16px',
            }}>FRIENDS JOINING</p>

            {/* ═══ AVATAR GRID — 8 members ═══ */}
            <div style={{
              display: 'flex', flexWrap: 'wrap', justifyContent: 'center',
              gap: 10, maxWidth: 260, marginBottom: 12,
            }}>
              {MEMBERS.map((m, i) => {
                const entrySpring = spring({ frame: frame - joinFrames[i], fps, config: { damping: 10, stiffness: 180 } });
                const hasJoined = frame >= joinFrames[i];
                return (
                  <div key={i} style={{
                    transform: `scale(${interpolate(entrySpring, [0, 1], [0, 1])})`,
                    opacity: hasJoined ? 1 : 0,
                  }}>
                    <div style={{
                      width: 46, height: 46, borderRadius: 23,
                      background: m.color, border: '3px solid rgba(255,255,255,0.2)',
                      display: 'flex', justifyContent: 'center', alignItems: 'center',
                      boxShadow: `0 4px 12px ${m.color}40`,
                      position: 'relative',
                    }}>
                      <span style={{ fontFamily: 'Inter', fontSize: 18, fontWeight: 800, color: 'white' }}>{m.letter}</span>
                      {/* Green check for joined */}
                      <div style={{
                        position: 'absolute', bottom: -3, right: -3,
                        width: 16, height: 16, borderRadius: 8,
                        background: '#22c55e', border: '2px solid #0f172a',
                        display: 'flex', justifyContent: 'center', alignItems: 'center',
                      }}>
                        <span style={{ fontSize: 8, color: 'white' }}>✓</span>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>

            {/* Join counter — prominent */}
            <div style={{
              background: 'rgba(20,184,166,0.1)', border: '1px solid rgba(20,184,166,0.2)',
              borderRadius: 16, padding: '8px 24px', marginTop: 4,
            }}>
              <span style={{
                fontFamily: 'Inter', fontSize: 22, fontWeight: 800, color: '#5eead4',
              }}>{joinedCount}</span>
              <span style={{
                fontFamily: 'Inter', fontSize: 22, fontWeight: 500, color: '#5eead4',
              }}> / 8 joined</span>
            </div>

            {/* Join names ticker */}
            {joinedCount > 0 && joinedCount < 8 && (
              <p style={{
                fontFamily: 'Inter', fontSize: 13, color: '#94a3b8', margin: '10px 0 0',
                opacity: 0.7,
              }}>
                {MEMBERS[joinedCount - 1].name} just joined
              </p>
            )}
            {joinedCount === 8 && (
              <p style={{
                fontFamily: 'Inter', fontSize: 14, color: '#22c55e', fontWeight: 600,
                margin: '10px 0 0',
              }}>
                ✓ Everyone's in!
              </p>
            )}
          </div>

          {/* ── LOCKED OUTING IN CHAT ── */}
          <div style={{
            position: 'absolute', inset: 0,
            opacity: lockedOp,
          }}>
            <WeekendChat chatShift={230}>
              {/* ORIGINAL LAWEEN CARD WITH SUBTLE CELEBRATORY ACCENTS */}
              <div style={{
                background: 'white', borderRadius: 24, padding: '24px',
                // Subtle pulsating yellow glow border and shadow
                boxShadow: `0 4px 16px rgba(0,0,0,0.03), 0 0 0 1.5px rgba(245,158,11,${0.35 + Math.sin(frame * 0.15) * 0.35}), 0 0 24px rgba(245,158,11,${0.15 + Math.sin(frame * 0.15) * 0.2})`,
                width: 270, transform: `scale(${interpolate(lockedSpring, [0, 1], [0.95, 1])})`,
                transformOrigin: 'top left',
                position: 'relative', // required for absolute badge
                margin: '8px 0 0', // margin to align properly after user message
              }}>
                {/* 2. Small yellow circular crown badge at top right */}
                <div style={{
                  position: 'absolute', top: -12, right: -12,
                  width: 32, height: 32, borderRadius: 16, background: '#f59e0b',
                  display: 'flex', justifyContent: 'center', alignItems: 'center',
                  boxShadow: '0 4px 10px rgba(245,158,11,0.3)', border: '2.5px solid white',
                  zIndex: 2, transform: `scale(${interpolate(lockedSpring, [0.3, 1], [0, 1])})` // springs in
                }}>
                  <span style={{ fontSize: 16 }}>👑</span>
                </div>

                <div style={{ display: 'flex', alignItems: 'center', gap: 14, marginBottom: 20 }}>
                  <div style={{
                    width: 44, height: 44, borderRadius: 22, background: '#fef1f2',
                    display: 'flex', justifyContent: 'center', alignItems: 'center',
                  }}>
                    <svg width="22" height="22" viewBox="0 0 24 24" fill="#ef4444">
                      <path d="M12 2C8.13 2 5 5.13 5 9C5 14.25 12 22 12 22C12 22 19 14.25 19 9C19 5.13 15.87 2 12 2ZM12 11.5C10.62 11.5 9.5 10.38 9.5 9C9.5 7.62 10.62 6.5 12 6.5C13.38 6.5 14.5 7.62 14.5 9C14.5 10.38 13.38 11.5 12 11.5Z"/>
                    </svg>
                  </div>
                  <h4 style={{ fontFamily: 'Outfit, system-ui, sans-serif', fontSize: 20, fontWeight: 800, color: '#2D3748', margin: 0 }}>Outing Session</h4>
                </div>
                <p style={{ fontFamily: 'Outfit, system-ui, sans-serif', fontSize: 16, color: '#006D77', fontWeight: 700, margin: '0 0 16px' }}>
                  Destination Locked
                </p>
                <div style={{ height: 1.5, background: '#f1f5f9', margin: '0 0 16px' }} />
                <div style={{
                  background: '#006D77', borderRadius: 20, padding: '14px 0',
                  textAlign: 'center', fontFamily: 'Outfit, system-ui, sans-serif', fontSize: 18, fontWeight: 700, color: 'white',
                }}>Winner</div>
              </div>
            </WeekendChat>
          </div>
        </PhoneMockup>
      </div>
    </AbsoluteFill>
  );
};
