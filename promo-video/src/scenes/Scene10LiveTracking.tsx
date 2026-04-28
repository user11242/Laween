import { AbsoluteFill, useCurrentFrame, useVideoConfig, spring, interpolate } from 'remotion';
import React from 'react';
import { PhoneMockup } from '../components/PhoneMockup';
import { IosNotification } from '../components/IosNotification';

const clamp = (v: number, min = 0, max = 1) => Math.max(min, Math.min(max, v));

/*
 * SCENE 10 — LIVE TRACKING
 * Visuals fixed to accurately map the real Laween dark map and exact arrival list styles.
 */

const DEST = { top: 32, left: 50 };

const USER_DEFS = [
  {
    letter: 'Y', name: 'Yazan', color: '#14b8a6',
    startTop: 15, startLeft: 22, arriveFrame: 100, maxProgress: 1.0, rank: 1,
  },
  {
    letter: 'S', name: 'Sarah', color: '#a78bfa',
    startTop: 18, startLeft: 82, arriveFrame: 165, maxProgress: 1.0, rank: 2,
  },
  {
    letter: 'A', name: 'Ahmad', color: '#f59e0b',
    startTop: 46, startLeft: 18, arriveFrame: 9999, maxProgress: 0.55, rank: 3,
  },
  {
    letter: 'W', name: 'You', color: '#0d7975',
    startTop: 48, startLeft: 84, arriveFrame: 9999, maxProgress: 0.47, rank: 4,
  },
];

export const Scene10LiveTracking: React.FC = () => {
  const { fps } = useVideoConfig();
  const frame = useCurrentFrame();

  const phoneSpring = spring({ frame: frame - 3, fps, config: { damping: 14 } });
  const phoneScale = interpolate(phoneSpring, [0, 1], [0.92, 1]);

  const mapPanX = interpolate(frame, [0, 210], [0, -10], { extrapolateRight: 'clamp' });
  const mapPanY = interpolate(frame, [0, 210], [0, -7], { extrapolateRight: 'clamp' });

  const titleOp = interpolate(frame, [8, 20], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const titleFade = interpolate(frame, [198, 208], [1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const exitOp = interpolate(frame, [202, 210], [1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  const computedMarkers = USER_DEFS.map((u) => {
    const arrived = frame >= u.arriveFrame;
    const travelEnd = Math.min(u.arriveFrame, 210);
    const rawProgress = interpolate(frame, [0, travelEnd], [0, u.maxProgress], {
      extrapolateLeft: 'clamp', extrapolateRight: 'clamp',
    });
    const progress = arrived ? 1.0 : rawProgress;
    const curTop = u.startTop + (DEST.top - u.startTop) * progress;
    const curLeft = u.startLeft + (DEST.left - u.startLeft) * progress;
    return { ...u, arrived, curTop, curLeft };
  });

  const yazanArrived = frame >= USER_DEFS[0].arriveFrame;
  const sarahArrived = frame >= USER_DEFS[1].arriveFrame;

  const friends = [
    { rank: 1, name: 'Yazan Qattous', dist: yazanArrived ? '0.1 km away' : '1.4 km away', eta: yazanArrived ? 'ARRIVED' : '4', arrived: yazanArrived, color: '#14b8a6' },
    { rank: 2, name: 'Sarah', dist: sarahArrived ? '0.0 km away' : '2.1 km away', eta: sarahArrived ? 'ARRIVED' : '6', arrived: sarahArrived, color: '#a78bfa' },
    { rank: 3, name: 'Ahmad', dist: '4.8 km away', eta: '10', arrived: false, color: '#f59e0b' },
    { rank: 4, name: 'User', dist: '5.5 km away', eta: '11', arrived: false, color: '#0d7975' },
  ];

  // ── Notification 1: Sarah is 2 min away ─────────────────────
  const NOTIF1_ENTER = 45;
  const NOTIF1_EXIT = 95;
  const notif1In = spring({ frame: frame - NOTIF1_ENTER, fps, config: { damping: 14 } });
  const notif1Out = spring({ frame: frame - NOTIF1_EXIT, fps, config: { damping: 14 } });
  const notif1Y = frame < NOTIF1_ENTER ? -100 : frame < NOTIF1_EXIT ? interpolate(notif1In, [0, 1], [-100, 16]) : interpolate(notif1Out, [0, 1], [16, -100]);
  const notif1Op = frame < NOTIF1_ENTER ? 0 : frame < NOTIF1_EXIT ? clamp(interpolate(frame, [NOTIF1_ENTER, NOTIF1_ENTER + 4], [0, 1])) : clamp(interpolate(frame, [NOTIF1_EXIT, NOTIF1_EXIT + 6], [1, 0]));

  // ── Notification 2: Yazan arrived ───────────────────────────
  const NOTIF2_ENTER = 104; // Yazan arrives at frame 100, notif drops slightly after
  const NOTIF2_EXIT = 158;
  const notif2In = spring({ frame: frame - NOTIF2_ENTER, fps, config: { damping: 14 } });
  const notif2Out = spring({ frame: frame - NOTIF2_EXIT, fps, config: { damping: 14 } });
  const notif2Y = frame < NOTIF2_ENTER ? -100 : frame < NOTIF2_EXIT ? interpolate(notif2In, [0, 1], [-100, 16]) : interpolate(notif2Out, [0, 1], [16, -100]);
  const notif2Op = frame < NOTIF2_ENTER ? 0 : frame < NOTIF2_EXIT ? clamp(interpolate(frame, [NOTIF2_ENTER, NOTIF2_ENTER + 4], [0, 1])) : clamp(interpolate(frame, [NOTIF2_EXIT, NOTIF2_EXIT + 6], [1, 0]));

  return (
    <AbsoluteFill style={{ backgroundColor: '#050714', justifyContent: 'center', alignItems: 'center', opacity: exitOp }}>
      <div style={{ position: 'absolute', width: '100%', height: '100%',
        background: 'radial-gradient(ellipse at 50% 45%, rgba(20,184,166,0.05) 0%, transparent 55%)' }} />

      <div style={{
        position: 'absolute', top: '5%', width: '100%', textAlign: 'center', padding: '0 16px',
        opacity: titleOp * titleFade, zIndex: 20,
      }}>
        <h1 style={{ fontFamily: 'Inter, system-ui, sans-serif', fontSize: 64, fontWeight: 900, color: 'white', margin: 0, letterSpacing: '-0.02em', lineHeight: 1.15 }}>
          Track arrivals live.
        </h1>
        <p style={{ fontFamily: 'Inter, system-ui, sans-serif', fontSize: 30, fontWeight: 700, color: '#5eead4', margin: '14px 0 0' }}>
          No more "where are you?" texts.
        </p>
      </div>

      <div style={{ transform: `scale(${phoneScale}) translateY(80px)` }}>
        <PhoneMockup scale={0.95} drift>
          {/* ── DARK MAP LAYER ── */}
          <div style={{
            position: 'absolute', top: -140, left: -140, right: -140, bottom: -140,
            background: '#232a39',
            transform: `translate(${mapPanX}px, ${mapPanY}px) scale(0.85)`,
            overflow: 'hidden',
          }}>
            {/* Dark map blocks/roads styling */}
            <div style={{ position: 'absolute', top: '22%', left: '5%', width: '38%', height: '15%', background: '#2c3547', borderRadius: 8 }} />
            <div style={{ position: 'absolute', top: '42%', left: '5%', width: '38%', height: '20%', background: '#2c3547', borderRadius: 8 }} />
            <div style={{ position: 'absolute', top: '67%', left: '5%', width: '38%', height: '18%', background: '#2c3547', borderRadius: 8 }} />
            <div style={{ position: 'absolute', top: '22%', left: '48%', width: '22%', height: '24%', background: '#2c3547', borderRadius: 8 }} />
            <div style={{ position: 'absolute', top: '51%', left: '48%', width: '22%', height: '34%', background: '#2c3547', borderRadius: 8 }} />
            <div style={{ position: 'absolute', top: '22%', left: '75%', width: '20%', height: '18%', background: '#2c3547', borderRadius: 8 }} />
            <div style={{ position: 'absolute', top: '45%', left: '75%', width: '20%', height: '40%', background: '#2c3547', borderRadius: 8 }} />
            
            {/* Thicker arterial roads */}
            <div style={{ position: 'absolute', top: '39%', left: '-10%', width: '120%', height: 6, background: '#4b5563', transform: 'rotate(-4deg)' }} />
            <div style={{ position: 'absolute', left: '45%', top: '-10%', bottom: '-10%', width: 6, background: '#4b5563', transform: 'rotate(5deg)' }} />

            {/* Hospital/School icons (Subtle map styling elements) */}
            <div style={{ position: 'absolute', top: '30%', left: '30%', width: 20, height: 20, borderRadius: 10, background: '#881337', display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
              <span style={{ color: 'white', fontSize: 12, fontWeight: 700 }}>H</span>
            </div>
            
            {/* ── DESTINATION PIN ── */}
            <div style={{
              position: 'absolute', top: `${DEST.top}%`, left: `${DEST.left}%`,
              transform: 'translate(-50%, -100%)', zIndex: 20,
            }}>
              <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
                <svg width="40" height="40" viewBox="0 0 24 24" fill="#d97706" style={{ filter: 'drop-shadow(0px 8px 6px rgba(0,0,0,0.4))' }}>
                  <path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z"/>
                </svg>
              </div>
            </div>

            {/* ── USER CIRCLES (Initials only) ── */}
            {computedMarkers.map((m) => (
              <div key={m.letter} style={{
                position: 'absolute', top: `${m.curTop}%`, left: `${m.curLeft}%`,
                transform: 'translate(-50%, -50%)', zIndex: 15,
                transition: 'top 0s, left 0s',
              }}>
                <div style={{
                  width: 54, height: 54, borderRadius: 27,
                  background: m.color, border: '3px solid white',
                  display: 'flex', justifyContent: 'center', alignItems: 'center',
                  boxShadow: `0 4px 12px rgba(0,0,0,0.3)`,
                }}>
                  <span style={{ fontFamily: 'Inter, system-ui, sans-serif', fontSize: 26, fontWeight: 800, color: 'white' }}>{m.letter}</span>
                </div>
              </div>
            ))}
          </div>

          {/* Map Overlay Controls */}
          <div style={{
            position: 'absolute', top: 56, left: 16,
            width: 44, height: 44, borderRadius: 22, background: '#1e293b',
            display: 'flex', justifyContent: 'center', alignItems: 'center',
            boxShadow: '0 4px 12px rgba(0,0,0,0.3)', zIndex: 30,
          }}>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
              <path d="M15 18l-6-6 6-6"/>
            </svg>
          </div>

          <div style={{ position: 'absolute', bottom: 380, right: 16, display: 'flex', flexDirection: 'column', gap: 10, zIndex: 30 }}>
            <div style={{ width: 46, height: 46, borderRadius: 23, background: 'white', display: 'flex', justifyContent: 'center', alignItems: 'center', boxShadow: '0 4px 12px rgba(0,0,0,0.2)' }}>
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#64748b" strokeWidth="2.5"><circle cx="12" cy="12" r="8"/><line x1="12" y1="8" x2="12" y2="16"/><line x1="8" y1="12" x2="16" y2="12"/></svg>
            </div>
            <div style={{ width: 46, height: 46, borderRadius: 23, background: 'white', display: 'flex', justifyContent: 'center', alignItems: 'center', boxShadow: '0 4px 12px rgba(0,0,0,0.2)' }}>
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#64748b" strokeWidth="2"><path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5" strokeLinejoin="round"/></svg>
            </div>
          </div>

          {/* ── EXACT ARRIVAL BOTTOM SHEET ── */}
          <div style={{
            position: 'absolute', bottom: 0, left: 0, right: 0,
            background: 'white', borderRadius: '28px 28px 0 0',
            boxShadow: '0 -8px 30px rgba(0,0,0,0.1)',
            padding: '16px 20px 24px', zIndex: 30,
          }}>
            <div style={{ width: 40, height: 4, background: '#cbd5e1', borderRadius: 2, margin: '0 auto 16px' }} />

            <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 16 }}>
              <svg width="20" height="20" viewBox="0 0 24 24" fill="#1e293b">
                <path d="M16 11c1.66 0 2.99-1.34 2.99-3S17.66 5 16 5c-1.66 0-3 1.34-3 3s1.34 3 3 3zm-8 0c1.66 0 2.99-1.34 2.99-3S9.66 5 8 5C6.34 5 5 6.34 5 8s1.34 3 3 3zm0 2c-2.33 0-7 1.17-7 3.5V19h14v-2.5c0-2.33-4.67-3.5-7-3.5z"/>
              </svg>
              <h2 style={{ fontFamily: 'Inter, system-ui, sans-serif', fontSize: 18, fontWeight: 800, color: '#1e293b', margin: 0 }}>
                Friends Arrival Times
              </h2>
            </div>

            <div style={{ display: 'flex', flexDirection: 'column' }}>
              {friends.map((f, i) => (
                <div key={i} style={{
                  display: 'flex', alignItems: 'center', padding: '16px 0',
                  borderBottom: i < friends.length - 1 ? '1px solid #f1f5f9' : 'none',
                }}>
                  {/* Rank Column */}
                  <div style={{ width: 40, display: 'flex', justifyContent: 'center' }}>
                    {f.arrived ? (
                      <div style={{ width: 34, height: 34, borderRadius: 17, background: '#0d7975', display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
                      </div>
                    ) : (
                      <div style={{ width: 34, height: 34, borderRadius: 17, background: '#f1f5f9', display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
                        <span style={{ fontFamily: 'Inter, system-ui, sans-serif', fontSize: 15, fontWeight: 700, color: '#334155' }}>{f.rank}</span>
                      </div>
                    )}
                  </div>

                  {/* Name + Dist */}
                  <div style={{ flex: 1, paddingLeft: 12 }}>
                    <p style={{ fontFamily: 'Inter, system-ui, sans-serif', fontSize: 17, fontWeight: 800, color: '#1e293b', margin: '0 0 4px', letterSpacing: '-0.01em' }}>{f.name}</p>
                    <p style={{ fontFamily: 'Inter, system-ui, sans-serif', fontSize: 13, color: '#94a3b8', margin: 0, fontWeight: 500 }}>{f.dist}</p>
                  </div>

                  {/* Right Badge */}
                  <div>
                    {f.arrived ? (
                      <div style={{ background: '#e0f2fe', borderRadius: 16, padding: '8px 14px' }}>
                        <span style={{ fontFamily: 'Inter, system-ui, sans-serif', fontSize: 11, fontWeight: 800, color: '#0d7975', letterSpacing: '0.05em' }}>ARRIVED</span>
                      </div>
                    ) : (
                      <div style={{ background: '#fef3c7', borderRadius: 16, padding: '8px 16px', display: 'flex', alignItems: 'baseline', gap: 4 }}>
                        <span style={{ fontFamily: 'Inter, system-ui, sans-serif', fontSize: 16, color: '#d97706', fontWeight: 800 }}>{f.eta}</span>
                        <span style={{ fontFamily: 'Inter, system-ui, sans-serif', fontSize: 12, color: '#d97706', fontWeight: 700 }}>min</span>
                      </div>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* ═══ IOS NOTIFICATIONS ═══ */}
          <div style={{
            position: 'absolute', top: 24, left: 16, right: 16,
            transform: `translateY(${notif1Y}px)`, opacity: notif1Op, zIndex: 100,
          }}>
            <IosNotification title="Weekend Plans 🎉" subtitle="Sarah is 2 min away" />
          </div>
          
          <div style={{
            position: 'absolute', top: 24, left: 16, right: 16,
            transform: `translateY(${notif2Y}px)`, opacity: notif2Op, zIndex: 100,
          }}>
            <IosNotification title="Weekend Plans 🎉" subtitle="Yazan arrived" />
          </div>

        </PhoneMockup>
      </div>
    </AbsoluteFill>
  );
};
