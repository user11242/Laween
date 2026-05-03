import { AbsoluteFill, useCurrentFrame, useVideoConfig, spring, interpolate, Img, staticFile } from 'remotion';
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
          Pick the vibe, metric, and timer.
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

          {/* ── CREATE OUTING CONFIG — exact match flutter code ── */}
          <div style={{
            position: 'absolute', inset: 0,
            opacity: configOp,
          }}>
            {/* Rounded white card sheet */}
            <div style={{
              position: 'absolute', bottom: 0, left: 0, right: 0,
              background: 'rgba(255, 255, 255, 0.95)', backdropFilter: 'blur(10px)',
              borderTopLeftRadius: 40, borderTopRightRadius: 40,
              border: '1.5px solid rgba(255,255,255,0.5)',
              padding: '24px 28px',
              boxShadow: '0 -10px 30px rgba(0,0,0,0.1)',
              display: 'flex', flexDirection: 'column',
            }}>
              {/* Handle */}
              <div style={{ width: 45, height: 5, background: 'rgba(150,150,150,0.2)', borderRadius: 3, margin: '0 auto 32px' }} />

              {/* Header row */}
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 40 }}>
                <div>
                  <h1 style={{ fontFamily: 'Outfit, system-ui, sans-serif', fontSize: 28, fontWeight: 800, color: '#2D3748', margin: 0, letterSpacing: '-0.5px' }}>Create Outing</h1>
                  <p style={{ fontFamily: 'Inter, system-ui, sans-serif', fontSize: 14, color: '#9e9e9e', margin: '4px 0 0', fontWeight: 500 }}>Find the perfect mid-point</p>
                </div>
                <div style={{
                  width: 48, height: 48, borderRadius: 24,
                  background: 'rgba(0, 109, 119, 0.1)',
                  display: 'flex', justifyContent: 'center', alignItems: 'center',
                }}>
                  <svg width="24" height="24" viewBox="0 0 24 24" fill="#006D77">
                    <path d="M13 2L3 14h9l-1 8 10-12h-9l1-8z"/>
                  </svg>
                </div>
              </div>

              {/* CALCULATION MODE */}
              <div style={{ fontFamily: 'Outfit, system-ui, sans-serif', fontSize: 12, fontWeight: 800, color: 'rgba(45, 55, 72, 0.4)', letterSpacing: '1.2px', marginBottom: 16, textTransform: 'uppercase' }}>
                CALCULATION MODE
              </div>

              <div style={{
                background: '#F1F5F9', borderRadius: 20, padding: 6,
                display: 'flex', position: 'relative', marginBottom: 32, height: 60,
              }}>
                {/* Sliding pill */}
                <div style={{
                  position: 'absolute', top: 6, bottom: 6,
                  left: `calc(${6 + toggleX * 50}%)`,
                  width: 'calc(50% - 12px)',
                  background: 'white', borderRadius: 15,
                  boxShadow: '0 4px 10px rgba(0,0,0,0.05)',
                }} />
                <div style={{
                  flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
                  fontFamily: 'Outfit, system-ui, sans-serif', fontSize: 16, fontWeight: 800,
                  color: toggleX < 0.5 ? '#2D3748' : '#bdbdbd', zIndex: 1,
                }}>
                  <svg width="20" height="20" viewBox="0 0 24 24" fill={toggleX < 0.5 ? '#006D77' : '#bdbdbd'}>
                    <circle cx="8" cy="7" r="2.5"/><path d="M8 11c-2.5 0-4.5 1.5-4.5 3v1h9v-1c0-1.5-2-3-4.5-3z"/>
                    <circle cx="16" cy="7" r="2.5"/><path d="M16 11c-2.5 0-4.5 1.5-4.5 3v1h9v-1c0-1.5-2-3-4.5-3z"/>
                    <path d="M6 18h12M8 16l-2 2 2 2M16 16l2 2-2 2" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
                  </svg>
                  KM
                </div>
                <div style={{
                  flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
                  fontFamily: 'Outfit, system-ui, sans-serif', fontSize: 16, fontWeight: 800,
                  color: toggleX >= 0.5 ? '#2D3748' : '#bdbdbd', zIndex: 1,
                }}>
                  <svg width="20" height="20" viewBox="0 0 24 24" fill={toggleX >= 0.5 ? '#006D77' : '#bdbdbd'}>
                    <path d="M12 2C6.5 2 2 6.5 2 12s4.5 10 10 10 10-4.5 10-10S17.5 2 12 2zm4.2 14.2L11 13V7h1.5v5.2l4.5 2.7-.8 1.3z"/>
                  </svg>
                  Time
                </div>
              </div>

              {/* SELECT CATEGORY */}
              <div style={{ fontFamily: 'Outfit, system-ui, sans-serif', fontSize: 12, fontWeight: 800, color: 'rgba(45, 55, 72, 0.4)', letterSpacing: '1.2px', marginBottom: 16, textTransform: 'uppercase' }}>
                SELECT CATEGORY
              </div>

              <div style={{ height: 110, display: 'flex', marginBottom: 40 }}>
                {[
                  { name: 'Restaurant', icon: <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#FF9800" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><path d="M3 2v7c0 1.1.9 2 2 2h4a2 2 0 0 0 2-2V2"/><path d="M7 2v20"/><path d="M21 15V2v0a5 5 0 0 0-5 5v6c0 1.1.9 2 2 2h3Zm0 0v7"/></svg>, color: '#FF9800', bg: 'rgba(255, 152, 0, 0.1)', selected: catSelected },
                  { name: 'Cafe', icon: <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#795548" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><path d="M17 8h1a4 4 0 1 1 0 8h-1"/><path d="M3 8h14v9a4 4 0 0 1-4 4H7a4 4 0 0 1-4-4Z"/><line x1="6" y1="2" x2="6" y2="4"/><line x1="10" y1="2" x2="10" y2="4"/><line x1="14" y1="2" x2="14" y2="4"/></svg>, color: '#795548', bg: 'rgba(121, 85, 72, 0.1)', selected: false },
                  { name: 'Park', icon: <svg width="24" height="24" viewBox="0 0 24 24" fill="#4CAF50" stroke="none"><polygon points="12 2 20 12 16 12 24 22 4 22 12 12 8 12 16 2"/></svg>, color: '#4CAF50', bg: 'rgba(76, 175, 80, 0.1)', selected: false },
                ].map((cat, i) => (
                  <div key={i} style={{
                    width: 100, marginRight: 16, flexShrink: 0,
                    background: cat.selected ? 'white' : 'rgba(255,255,255,0.5)',
                    borderRadius: 24,
                    border: cat.selected ? '2px solid #006D77' : '2px solid transparent',
                    boxShadow: cat.selected ? '0 8px 15px rgba(0, 109, 119, 0.15)' : '0 8px 15px rgba(0,0,0,0.03)',
                    display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
                    transform: `scale(${cat.selected && frame >= selectCat && frame < selectCat + 6
                      ? interpolate(frame, [selectCat, selectCat + 3, selectCat + 6], [1, 0.94, 1], { extrapolateRight: 'clamp' }) : 1})`,
                  }}>
                    <div style={{ padding: 12, borderRadius: 24, background: cat.bg, marginBottom: 12, display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
                      {cat.icon}
                    </div>
                    <span style={{ fontFamily: 'Outfit, system-ui, sans-serif', fontSize: 14, fontWeight: cat.selected ? 800 : 500, color: '#2D3748' }}>
                      {cat.name}
                    </span>
                  </div>
                ))}
              </div>

              {/* JOIN TIME LIMIT */}
              <div style={{ fontFamily: 'Outfit, system-ui, sans-serif', fontSize: 12, fontWeight: 800, color: 'rgba(45, 55, 72, 0.4)', letterSpacing: '1.2px', marginBottom: 16, textTransform: 'uppercase' }}>
                JOIN TIME LIMIT
              </div>

              <div style={{ display: 'flex', marginBottom: 48 }}>
                {[2, 5, 10].map((t, i) => {
                  const isSelected = timerSelected && i === 1; // 5 min is selected
                  return (
                    <div key={i} style={{
                      flex: 1, marginRight: t === 10 ? 0 : 12, padding: '16px 0',
                      background: isSelected ? '#2D3748' : 'white',
                      borderRadius: 18, border: `1.5px solid ${isSelected ? '#2D3748' : '#e2e8f0'}`,
                      boxShadow: isSelected ? '0 6px 12px rgba(45, 55, 72, 0.2)' : 'none',
                      textAlign: 'center',
                      fontFamily: 'Outfit, system-ui, sans-serif', fontSize: 16, fontWeight: 800,
                      color: isSelected ? 'white' : '#757575',
                    }}>
                      {t} min
                    </div>
                  );
                })}
              </div>

              {/* Launch Button */}
              <div style={{
                width: '100%', height: 64,
                background: 'linear-gradient(to bottom right, #83C5BE, #006D77)',
                borderRadius: 20,
                boxShadow: launchScale < 0.99
                  ? '0 14px 30px rgba(0,109,119,0.65), 0 0 24px rgba(94,234,212,0.35)'
                  : '0 10px 20px rgba(0, 109, 119, 0.4)',
                display: 'flex', justifyContent: 'center', alignItems: 'center', gap: 12,
                transform: `scale(${launchScale})`,
                marginBottom: 12
              }}>
                <svg width="20" height="20" viewBox="0 0 24 24" fill="white">
                  <path d="M12 2L13.5 8.5L20 10L13.5 11.5L12 18L10.5 11.5L4 10L10.5 8.5L12 2Z"/>
                  <path d="M18 14L18.75 16.25L21 17L18.75 17.75L18 20L17.25 17.75L15 17L17.25 16.25L18 14Z" opacity="0.7"/>
                </svg>
                <span style={{ fontFamily: 'Outfit, system-ui, sans-serif', fontSize: 18, fontWeight: 800, color: 'white' }}>Launch Outing Session</span>
              </div>
            </div>
          </div>
          
          {/* ── MAP — exact match map_screen.jpeg ── */}
          <div style={{
            position: 'absolute', inset: 0,
            background: '#e6e8e3', // Map base color
            opacity: mapOp,
          }}>
            {/* Authentic Map Graphic */}
            <div style={{
              position: 'absolute', inset: 0,
              background: '#f8fafc',
            }}>
              <Img src={staticFile('map_screen.jpeg')} style={{ position: 'absolute', top: 0, left: 0, width: '150%', height: '150%', objectFit: 'cover', opacity: 0.9, transform: 'translate(-20%, -20%)' }} />
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
