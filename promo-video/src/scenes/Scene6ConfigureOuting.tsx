import { AbsoluteFill, useCurrentFrame, useVideoConfig, spring, interpolate } from 'remotion';
import React from 'react';
import { PhoneMockup } from '../components/PhoneMockup';

/*
 * SCENE 6 — CONFIGURE THE MIDPOINT SESSION
 * Pixel-perfect match: outing_session_main.jpeg → map_screen.jpeg
 */
export const Scene6ConfigureOuting: React.FC = () => {
  const { fps } = useVideoConfig();
  const frame = useCurrentFrame();

  const configEnd = 140;
  const mapStart = 145;

  const phoneSpring = spring({ frame: frame - 3, fps, config: { damping: 14 } });
  const phoneY = interpolate(phoneSpring, [0, 1], [500, 0]);
  const floatY = Math.sin(frame * 0.05) * 3;

  // Interaction timing
  const toggleTime = 25;   // KM→Time toggle
  const selectCat = 50;    // Restaurant selected
  const selectTimer = 75;  // 5 min
  const tapLaunch = 110;

  const toggleSpring = spring({ frame: frame - toggleTime, fps, config: { damping: 14 } });
  const toggleX = interpolate(toggleSpring, [0, 1], [0, 1]); // 0=KM, 1=Time
  const catSelected = frame >= selectCat;
  const timerSelected = frame >= selectTimer;

  const launchScale = (frame >= tapLaunch && frame < tapLaunch + 6)
    ? interpolate(frame, [tapLaunch, tapLaunch + 3, tapLaunch + 6], [1, 0.94, 1], { extrapolateRight: 'clamp' }) : 1;

  const configOp = interpolate(frame, [configEnd, configEnd + 6], [1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const mapOp = interpolate(frame, [mapStart, mapStart + 6], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const confirmTap = (frame >= 190 && frame < 196) ? interpolate(frame, [190, 193, 196], [1, 0.94, 1], { extrapolateRight: 'clamp' }) : 1;

  const titleOp = interpolate(frame, [8, 20], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const titleFade = interpolate(frame, [200, 210], [1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const exitOp = interpolate(frame, [202, 210], [1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  return (
    <AbsoluteFill style={{ backgroundColor: '#050714', justifyContent: 'center', alignItems: 'center', opacity: exitOp }}>
      <div style={{ position: 'absolute', width: '100%', height: '100%',
        background: 'radial-gradient(ellipse at 50% 45%, rgba(20,184,166,0.07) 0%, transparent 55%)' }} />

      <div style={{
        position: 'absolute', top: '5%', width: '100%', textAlign: 'center',
        opacity: titleOp * titleFade, zIndex: 20,
      }}>
        <h1 style={{ fontFamily: 'Inter, system-ui, sans-serif', fontSize: 64, fontWeight: 900, color: 'white', margin: 0, letterSpacing: '-0.02em', lineHeight: 1.15 }}>
          Built for real group decisions.
        </h1>
        <p style={{ fontFamily: 'Inter, system-ui, sans-serif', fontSize: 30, color: '#5eead4', fontWeight: 600, margin: '14px 0 0' }}>
          Pick the category, metric, and timer.
        </p>
      </div>

      <div style={{ transform: `translateY(${phoneY + floatY + 45}px)` }}>
        <PhoneMockup scale={0.95} drift>
          {/* ── CREATE OUTING CONFIG — exact match outing_session_main.jpeg ── */}
          {/* Background Chat Overlay (Blurred) */}
          <div style={{ position: 'absolute', inset: 0, backgroundColor: '#fdfdfd', display: 'flex', flexDirection: 'column', filter: 'blur(8px)', transform: 'scale(1.02)' }}>
            <div style={{ backgroundColor: 'white', padding: '52px 16px 14px', display: 'flex', alignItems: 'center', gap: 12, boxShadow: '0 1px 4px rgba(0,0,0,0.03)' }}>
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#1e293b" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" style={{ flexShrink: 0 }}><path d="M15 18l-6-6 6-6"/></svg>
              <div style={{ width: 44, height: 44, borderRadius: 22, backgroundColor: '#cbd5e1', flexShrink: 0 }} />
              <div style={{ flex: 1, minWidth: 0 }}>
                <p style={{ fontFamily: 'Inter, system-ui, sans-serif', fontSize: 18, fontWeight: 700, color: '#1e293b', margin: 0 }}>test</p>
                <p style={{ fontFamily: 'Inter, system-ui, sans-serif', fontSize: 13, color: '#94a3b8', margin: '2px 0 0' }}>3 members</p>
              </div>
            </div>
            <div style={{ flex: 1, backgroundColor: '#fdfdfd' }} />
          </div>

          {/* Dark Overlay over chat background */}
          <div style={{ position: 'absolute', inset: 0, backgroundColor: 'rgba(0,0,0,0.65)' }} />

          {/* ── CREATE OUTING CONFIG — exact match outing_session_main.jpeg ── */}
          <div style={{
            position: 'absolute', inset: 0,
            opacity: configOp,
          }}>
            {/* Rounded white card sheet */}
            <div style={{
              position: 'absolute', top: 50, left: 0, right: 0, bottom: 0,
              background: '#f6f7f9', borderTopLeftRadius: 36, borderTopRightRadius: 36,
              padding: '12px 24px 0',
              boxShadow: '0 -8px 40px rgba(0,0,0,0.15)',
            }}>
              {/* Handle */}
              <div style={{ width: 40, height: 4, background: '#cbd5e1', borderRadius: 2, margin: '8px auto 28px', opacity: 0.6 }} />

              {/* Header row */}
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 32 }}>
                <div>
                  <h1 style={{ fontFamily: 'Inter, system-ui, sans-serif', fontSize: 32, fontWeight: 800, color: '#2e374d', margin: 0, letterSpacing: '-0.02em' }}>Create Outing</h1>
                  <p style={{ fontFamily: 'Inter, system-ui, sans-serif', fontSize: 16, color: '#94a3b8', margin: '4px 0 0', fontWeight: 500 }}>Find the perfect mid-point</p>
                </div>
                {/* Lightning badge */}
                <div style={{
                  width: 48, height: 48, borderRadius: 24,
                  background: '#e8f3f2',
                  display: 'flex', justifyContent: 'center', alignItems: 'center',
                }}>
                  <svg width="22" height="22" viewBox="0 0 24 24" fill="#0d7975">
                    <path d="M13 2L3 14h9l-1 8 10-12h-9l1-8z"/>
                  </svg>
                </div>
              </div>

              {/* CALCULATION MODE */}
              <p style={{
                fontFamily: 'Inter, system-ui, sans-serif', fontSize: 12, fontWeight: 800, color: '#94a3b8',
                letterSpacing: '0.12em', margin: '0 0 16px',
              }}>CALCULATION MODE</p>

              {/* Segmented control — exact: rounded pill, white sliding thumb */}
              <div style={{
                background: '#fcfcfc', borderRadius: 24, padding: 6,
                display: 'flex', position: 'relative', marginBottom: 36, height: 56,
                boxShadow: 'inset 0 2px 4px rgba(0,0,0,0.02)',
              }}>
                {/* Sliding pill */}
                <div style={{
                  position: 'absolute', top: 6, bottom: 6,
                  left: `calc(${6 + toggleX * 50}%)`,
                  width: 'calc(50% - 12px)',
                  background: 'white', borderRadius: 20,
                  boxShadow: '0 2px 10px rgba(0,0,0,0.06)',
                }} />
                <div style={{
                  flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
                  fontFamily: 'Inter, system-ui, sans-serif', fontSize: 17, fontWeight: 800,
                  color: toggleX < 0.5 ? '#1e2936' : '#cbd5e1', zIndex: 1,
                }}>
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><path d="M16 3h5v5M4 20L21 3M21 16v5h-5M15 21l6-6M3 9l6-6M4 4l6 6"/></svg>
                  KM
                </div>
                <div style={{
                  flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
                  fontFamily: 'Inter, system-ui, sans-serif', fontSize: 17, fontWeight: 800,
                  color: toggleX >= 0.5 ? '#0d7975' : '#cbd5e1', zIndex: 1,
                }}>
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
                  Time
                </div>
              </div>

              {/* SELECT CATEGORY */}
              <p style={{
                fontFamily: 'Inter, system-ui, sans-serif', fontSize: 12, fontWeight: 800, color: '#94a3b8',
                letterSpacing: '0.12em', margin: '0 0 16px',
              }}>SELECT CATEGORY</p>

              <div style={{ display: 'flex', gap: 12, marginBottom: 36 }}>
                {[
                  { icon: <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#f5bd63" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><path d="M3 2v7c0 1.1.9 2 2 2h4a2 2 0 0 0 2-2V2"/><path d="M7 2v20"/><path d="M21 15V2v0a5 5 0 0 0-5 5v6c0 1.1.9 2 2 2h3Zm0 0v7"/></svg>, name: 'Restaurant', bg: '#fdf1e1', selected: catSelected },
                  { icon: <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#927e74" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><path d="M17 8h1a4 4 0 1 1 0 8h-1"/><path d="M3 8h14v9a4 4 0 0 1-4 4H7a4 4 0 0 1-4-4Z"/><line x1="6" y1="2" x2="6" y2="4"/><line x1="10" y1="2" x2="10" y2="4"/><line x1="14" y1="2" x2="14" y2="4"/></svg>, name: 'Cafe', bg: '#f3eceb', selected: false },
                  { icon: <svg width="24" height="24" viewBox="0 0 24 24" fill="#69a96e" stroke="none"><polygon points="12 2 20 12 16 12 24 22 4 22 12 12 8 12 16 2"/></svg>, name: 'Park', bg: '#eef6f0', selected: false },
                ].map((cat, i) => (
                  <div key={i} style={{
                    flex: 1, background: '#fdfdfd', borderRadius: 20, padding: '24px 0',
                    display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 12,
                    border: cat.selected ? '2.5px solid #0d7975' : '2px solid transparent',
                    boxShadow: '0 4px 16px rgba(0,0,0,0.03)',
                    transform: `scale(${cat.selected && frame >= selectCat && frame < selectCat + 6
                      ? interpolate(frame, [selectCat, selectCat + 3, selectCat + 6], [1, 0.94, 1], { extrapolateRight: 'clamp' }) : 1})`,
                  }}>
                    <div style={{
                      width: 52, height: 52, borderRadius: 26, background: cat.bg,
                      display: 'flex', justifyContent: 'center', alignItems: 'center',
                    }}>
                      {cat.icon}
                    </div>
                    <span style={{
                      fontFamily: 'Inter, system-ui, sans-serif', fontSize: 14, fontWeight: cat.selected ? 800 : 700,
                      color: cat.selected ? '#1e293b' : '#64748b',
                    }}>{cat.name}</span>
                  </div>
                ))}
              </div>

              {/* JOIN TIME LIMIT */}
              <p style={{
                fontFamily: 'Inter, system-ui, sans-serif', fontSize: 12, fontWeight: 800, color: '#94a3b8',
                letterSpacing: '0.12em', margin: '0 0 16px',
              }}>JOIN TIME LIMIT</p>

              <div style={{ display: 'flex', gap: 12, marginBottom: 40 }}>
                {['2 min', '5 min', '10 min'].map((t, i) => {
                  const isSelected = timerSelected && i === 1;
                  return (
                    <div key={i} style={{
                      flex: 1, borderRadius: 16, padding: '16px 0', textAlign: 'center',
                      fontFamily: 'Inter, system-ui, sans-serif', fontSize: 16, fontWeight: 800,
                      background: isSelected ? '#293644' : 'white',
                      color: isSelected ? 'white' : '#64748b',
                      boxShadow: isSelected ? '0 8px 20px rgba(41,54,68,0.25)' : 'none',
                    }}>{t}</div>
                  );
                })}
              </div>

              {/* Launch Button — exact: teal gradient pill with sparkle */}
              <div style={{
                background: 'linear-gradient(90deg, #65b7b0, #2a9d8f, #1e787c)',
                borderRadius: 24, padding: '20px 0', width: '100%', textAlign: 'center',
                display: 'flex', justifyContent: 'center', alignItems: 'center', gap: 8,
                fontFamily: 'Inter', fontSize: 20, fontWeight: 700, color: 'white',
                boxShadow: '0 8px 24px rgba(30,120,124,0.35)',
                transform: `scale(${launchScale})`,
              }}>
                <svg width="18" height="18" viewBox="0 0 24 24" fill="white">
                  <path d="M12 2L13.5 8.5L20 10L13.5 11.5L12 18L10.5 11.5L4 10L10.5 8.5L12 2Z"/>
                  <path d="M18 14L18.75 16.25L21 17L18.75 17.75L18 20L17.25 17.75L15 17L17.25 16.25L18 14Z" opacity="0.7"/>
                </svg>
                Launch Outing Session
              </div>
            </div>
          </div>
          
          {/* ── MAP — exact match map_screen.jpeg ── */}
          <div style={{
            position: 'absolute', inset: 0,
            background: '#e6e8e3', // Map base color
            opacity: mapOp,
          }}>
            {/* Fake Google Map Map Graphic Canvas */}
            <div style={{
              position: 'absolute', inset: 0,
            }}>
              {/* Roads matching styling */}
              {[15, 30, 48, 65, 80, 92].map((p, i) => (
                <div key={`h${i}`} style={{ position: 'absolute', top: `${p}%`, left: -50, right: -50, height: i % 2 === 0 ? 8 : 12, background: '#ffffff', transform: `rotate(${Math.sin(i) * 15}deg)`, borderRadius: 6 }} />
              ))}
              {[10, 25, 45, 65, 85].map((p, i) => (
                <div key={`v${i}`} style={{ position: 'absolute', left: `${p}%`, top: -50, bottom: -50, width: i % 2 === 0 ? 8 : 12, background: '#ffffff', transform: `rotate(${Math.cos(i) * 15}deg)`, borderRadius: 6 }} />
              ))}
              {/* Fake POI labels like map screen */}
              {[
                { top: '30%', left: '40%', name: 'Palm Village Restaurant', icon: '🍴', color: '#f97316' },
                { top: '22%', left: '55%', name: 'Mosque', icon: '🕌', color: '#64748b' }
              ].map((poi, i) => (
                <div key={i} style={{ position: 'absolute', top: poi.top, left: poi.left, display: 'flex', alignItems: 'center', gap: 6 }}>
                  <div style={{ width: 22, height: 22, borderRadius: 11, background: poi.color, display: 'flex', justifyContent: 'center', alignItems: 'center', opacity: 0.85 }}>
                     <span style={{ fontSize: 11, color: 'white' }}>{poi.icon}</span>
                  </div>
                  <span style={{ fontFamily: 'Georgia, serif', fontSize: 13, fontWeight: 700, color: poi.color, textShadow: '1px 1px 0px white, -1px -1px 0px white, 1px -1px 0px white, -1px 1px 0px white', letterSpacing: '-0.02em' }}>{poi.name}</span>
                </div>
              ))}

              {/* Under-pin Red Glow */}
              <div style={{ position: 'absolute', top: '50%', left: '50%', width: 60, height: 60, transform: 'translate(-50%, -50%)', background: 'radial-gradient(circle, rgba(255,75,75,0.6) 0%, rgba(255,75,75,0.2) 30%, transparent 60%)' }} />

              {/* Pin */}
              <div style={{ position: 'absolute', top: '50%', left: '50%', transform: 'translate(-50%, -100%)' }}>
                <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
                  <div style={{
                    width: 44, height: 44, borderRadius: '50% 50% 50% 0', background: 'linear-gradient(135deg, #ff6b6b, #ff4b4b)',
                    display: 'flex', justifyContent: 'center', alignItems: 'center', transform: 'rotate(-45deg)'
                  }}>
                    <div style={{ width: 14, height: 14, borderRadius: 7, background: 'white' }} />
                  </div>
                </div>
              </div>
            </div>

            {/* Back Button Overlay */}
            <div style={{ position: 'absolute', top: 56, left: 16, width: 44, height: 44, borderRadius: 22, backgroundColor: 'rgba(50,56,69,0.85)', backdropFilter: 'blur(4px)', display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
               <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" style={{ marginLeft: -2 }}><path d="M15 18l-6-6 6-6"/></svg>
            </div>

            {/* Search bar */}
            <div style={{
              position: 'absolute', top: 114, left: 20, right: 20,
              background: 'white', borderRadius: 20, padding: '16px 20px',
              display: 'flex', alignItems: 'center', gap: 14,
              boxShadow: '0 6px 24px rgba(0,0,0,0.06)',
            }}>
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#65b7b0" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" style={{ flexShrink: 0 }}><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
              <div style={{ fontFamily: 'Inter, system-ui, sans-serif', fontSize: 16, color: '#9ba3b0', fontWeight: 500, lineHeight: 1.3 }}>
                Search for a neighborhood or<br/>place...
              </div>
            </div>

            {/* My location button */}
            <div style={{
              position: 'absolute', bottom: 120, right: 20,
              width: 56, height: 56, borderRadius: 16, background: '#222b36',
              display: 'flex', justifyContent: 'center', alignItems: 'center',
              boxShadow: '0 8px 24px rgba(34,43,54,0.4)',
            }}>
              <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="#378b86" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="4"/><circle cx="12" cy="12" r="9"/><line x1="12" y1="2" x2="12" y2="4"/><line x1="12" y1="20" x2="12" y2="22"/><line x1="2" y1="12" x2="4" y2="12"/><line x1="20" y1="12" x2="22" y2="12"/></svg>
            </div>

            {/* Confirm button — exact match */}
            <div style={{
              position: 'absolute', bottom: 32, left: 24, right: 24,
            }}>
              <div style={{
                background: '#327c7a',
                borderRadius: 16, padding: '18px 0', textAlign: 'center',
                fontFamily: 'Inter, system-ui, sans-serif', fontSize: 20, fontWeight: 800, color: 'white',
                boxShadow: '0 8px 24px rgba(50,124,122,0.3)',
                transform: `scale(${confirmTap})`,
              }}>
                Confirm Start Location
              </div>
            </div>
          </div>
        </PhoneMockup>
      </div>
    </AbsoluteFill>
  );
};
