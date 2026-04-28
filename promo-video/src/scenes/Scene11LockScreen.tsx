import { AbsoluteFill, useCurrentFrame, useVideoConfig, spring, interpolate, Img, staticFile } from 'remotion';
import React from 'react';

/*
 * SCENE 11 — LOCK SCREEN / LIVE ACTIVITY
 * Direct React recreation of the Flutter actual UI reference image.
 */
export const Scene11LockScreen: React.FC = () => {
  const { fps } = useVideoConfig();
  const frame = useCurrentFrame();

  // Story continuity progress logic
  const youProgress = interpolate(frame, [0, 120], [0.42, 0.48], { extrapolateRight: 'clamp' });
  const ahmadProgress = interpolate(frame, [0, 120], [0.50, 0.55], { extrapolateRight: 'clamp' });
  const sarahProgress = interpolate(frame, [0, 120], [0.85, 0.95], { extrapolateRight: 'clamp' });
  const yazanProgress = interpolate(frame, [0, 120], [0.99, 1.0],  { extrapolateRight: 'clamp' });

  // ETAs descending
  const youETA = Math.max(10, Math.round(11 - frame * 0.02));
  const ahmadETA = Math.max(9, Math.round(10 - frame * 0.02));
  const sarahETA = Math.max(1, Math.round(3 - frame * 0.03));
  
  const titleOp = interpolate(frame, [10, 22], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const titleFade = interpolate(frame, [138, 148], [1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const exitOp = interpolate(frame, [142, 150], [1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });


  // Card entry
  const cardSpring = spring({ frame: frame - 15, fps, config: { damping: 14 } });
  const cardY = interpolate(cardSpring, [0, 1], [30, 0]);
  const cardOp = interpolate(frame, [15, 23], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  const users = [
    { letter: 'Y', name: 'Yazan Qattous', dist: '6.5 km', etaText: yazanProgress >= 1 ? 'Arrived' : '1m', prog: yazanProgress },
    { letter: 'S', name: 'Sarah',         dist: '2.1 km', etaText: `${sarahETA}m`, prog: sarahProgress },
    { letter: 'A', name: 'Ahmad',         dist: '5.8 km', etaText: `${ahmadETA}m`, prog: ahmadProgress },
    { letter: 'U', name: 'You',           dist: '7.4 km', etaText: `${youETA}m`, prog: youProgress },
  ];

  return (
    <AbsoluteFill style={{ backgroundColor: '#050714', overflow: 'hidden', opacity: exitOp }}>
      {/* Title above */}
      <div style={{
        position: 'absolute', top: '5%', width: '100%', textAlign: 'center',
        opacity: titleOp * titleFade, zIndex: 20,
      }}>
        <h1 style={{ fontFamily: 'Inter, system-ui, sans-serif', fontSize: 64, fontWeight: 900, color: 'white', margin: 0, letterSpacing: '-0.02em', lineHeight: 1.15 }}>
          Always in the loop.
        </h1>
        <p style={{ fontFamily: 'Inter, system-ui, sans-serif', fontSize: 30, color: '#5eead4', fontWeight: 600, margin: '14px 0 0' }}>
          Even from the lock screen.
        </p>
      </div>

      {/* ═══ PHONE-SIZED LOCK SCREEN ═══ */}
      <div style={{
        position: 'absolute', top: '56%', left: '50%',
        transform: `translate(-50%, -50%) scale(1.35)`,
      }}>
        {/* Phone chassis */}
        <div style={{
          width: 260, height: 560, position: 'relative',
          borderRadius: 38, overflow: 'hidden',
          background: 'linear-gradient(160deg, #3a3a3f, #1c1c21, #0a0a0e)',
          boxShadow: '0 20px 60px rgba(0,0,0,0.6), inset 0 1px 0 rgba(255,255,255,0.15)',
        }}>
          {/* Screen area */}
          <div style={{
            position: 'absolute', top: 4, left: 4, right: 4, bottom: 4,
            borderRadius: 34, overflow: 'hidden',
            backgroundColor: '#0a0d14',
          }}>
            {/* Generic iOS-style subtle gradient background */}
            <div style={{
              position: 'absolute', inset: 0,
              background: 'linear-gradient(135deg, #0f172a 0%, #1b2f4a 50%, #030712 100%)',
            }}>
              {/* Soft abstract blur */}
              <div style={{ position: 'absolute', inset: 0, background: 'radial-gradient(circle at 80% -20%, rgba(20,184,166,0.15) 0%, transparent 60%)' }} />
              <div style={{ position: 'absolute', inset: 0, background: 'radial-gradient(circle at -20% 120%, rgba(167,139,250,0.12) 0%, transparent 50%)' }} />
            </div>

            {/* ── STATUS BAR ── */}
            <div style={{
              position: 'absolute', top: 0, left: 0, right: 0,
              padding: '8px 18px 0', display: 'flex', justifyContent: 'flex-end', alignItems: 'center',
              zIndex: 10,
            }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 5 }}>
                {/* Signal */}
                <div style={{ display: 'flex', alignItems: 'flex-end', gap: 1 }}>
                  {[4, 5.5, 7.5, 10].map((h, i) => (
                    <div key={i} style={{ width: 2.5, height: h, borderRadius: 1, background: i < 3 ? 'white' : 'rgba(255,255,255,0.4)' }} />
                  ))}
                </div>
                {/* Wifi */}
                <svg width="13" height="13" viewBox="0 0 24 24" fill="white"><path d="M1 9l2 2c4.97-4.97 13.03-4.97 18 0l2-2C16.93 2.93 7.08 2.93 1 9zm8 8l3 3 3-3c-1.65-1.66-4.34-1.66-6 0zm-4-4l2 2c2.76-2.76 7.24-2.76 10 0l2-2C15.14 9.14 8.87 9.14 5 13z"/></svg>
                {/* Battery */}
                <div style={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                  <div style={{ width: 20, height: 10, borderRadius: 3, border: '1px solid rgba(255,255,255,0.8)', padding: '1px' }}>
                    <div style={{ width: '80%', height: '100%', borderRadius: 1.5, background: 'white' }} />
                  </div>
                </div>
              </div>
            </div>

            {/* Dynamic Island cutout */}
            <div style={{
              position: 'absolute', top: 6, left: '50%', transform: 'translateX(-50%)',
              width: 80, height: 24, background: '#000', borderRadius: 12, zIndex: 15,
            }} />

            {/* ── DATE + CLOCK ── */}
            <div style={{
              position: 'absolute', top: 60, width: '100%', textAlign: 'center',
            }}>
              <p style={{
                fontFamily: 'Inter, system-ui, sans-serif', fontSize: 14, fontWeight: 600, color: 'rgba(255,255,255,0.9)',
                margin: 0, letterSpacing: '0.01em',
              }}>Sun 12 Apr</p>
              <h1 style={{
                fontFamily: 'Inter, system-ui, sans-serif', fontSize: 72, fontWeight: 300, margin: '-2px 0 0',
                color: 'transparent',
                WebkitTextStroke: '1.5px rgba(255,255,255,0.6)',
                letterSpacing: '-0.02em',
              }}>4:29</h1>
            </div>

            {/* ═══ EXACT FLUTTER LAWEEN LIVE ACTIVITY CARD ═══ */}
            <div style={{
              position: 'absolute', bottom: 78, left: 12, right: 12,
              backgroundColor: '#1d7472', // Exact solid teal color from reference
              borderRadius: 24, padding: '20px',
              boxShadow: '0 8px 30px rgba(0,0,0,0.5)',
              opacity: cardOp, 
              transformOrigin: 'bottom center',
              transform: `translateY(${cardY}px) scale(0.85)`,
            }}>
              
              {/* Header Box (Icon + Title) */}
              <div style={{ display: 'flex', alignItems: 'flex-start', gap: 12, marginBottom: 16 }}>
                <div style={{
                  width: 44, height: 44, borderRadius: 12, flexShrink: 0,
                  background: 'white', display: 'flex', justifyContent: 'center', alignItems: 'center',
                  padding: 8, overflow: 'hidden' // Real app icon sizing
                }}>
                  <Img src={staticFile('app_pin_logo.png')} style={{ width: '100%', height: '100%', objectFit: 'contain' }} />
                </div>
                <div style={{ display: 'flex', flexDirection: 'column', justifyContent: 'center', flex: 1, minWidth: 0, paddingTop: 2 }}>
                  <p style={{ fontFamily: 'Inter, system-ui, sans-serif', fontSize: 15, fontWeight: 800, color: 'white', margin: '0 0 2px', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>Oliva Restaurant a...</p>
                  <p style={{ fontFamily: 'Inter, system-ui, sans-serif', fontSize: 12, color: 'rgba(255,255,255,0.85)', margin: 0, fontWeight: 500 }}>Arriving in {youETA} min</p>
                </div>
              </div>

              {/* Exact React recreation of the Flutter Progress Rows */}
              <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
                {users.map((u, i) => (
                  <div key={i} style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                    {/* Text Row */}
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end', padding: '0 2px' }}>
                      <span style={{ fontFamily: 'Inter, system-ui, sans-serif', fontSize: 13, fontWeight: 800, color: 'white' }}>{u.name}</span>
                      <span style={{ fontFamily: 'Inter, system-ui, sans-serif', fontSize: 11, color: 'rgba(255,255,255,0.7)', fontWeight: 600 }}>{u.etaText} · {u.dist}</span>
                    </div>
                    {/* Slider Row */}
                    <div style={{ position: 'relative', height: 16, display: 'flex', alignItems: 'center' }}>
                      {/* Dark track */}
                      <div style={{ position: 'absolute', left: 0, right: 0, height: 3, borderRadius: 1.5, backgroundColor: '#185d5b' }} />
                      {/* Filled track */}
                      <div style={{ position: 'absolute', left: 0, width: `${u.prog * 100}%`, height: 3, borderRadius: 1.5, backgroundColor: 'rgba(255,255,255,0.8)' }} />
                      {/* Letter Thumb */}
                      <div style={{
                        position: 'absolute', left: `${u.prog * 100}%`, top: '50%', transform: 'translate(-50%, -50%)',
                        width: 14, height: 14, borderRadius: 7,
                        backgroundColor: '#ffffff',
                        display: 'flex', justifyContent: 'center', alignItems: 'center',
                        boxShadow: '0 1px 3px rgba(0,0,0,0.4)',
                        zIndex: 2,
                      }}>
                        <span style={{ fontFamily: 'Inter, system-ui, sans-serif', fontSize: 9, fontWeight: 900, color: '#1d7472' }}>{u.letter}</span>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* ── BOTTOM CONTROLS (Flashlight + Camera) ── */}
            <div style={{
              position: 'absolute', bottom: 18, left: 0, right: 0,
              display: 'flex', justifyContent: 'space-between', padding: '0 28px',
            }}>
              <div style={{ width: 44, height: 44, borderRadius: 22, background: 'rgba(255,255,255,0.2)', display: 'flex', justifyContent: 'center', alignItems: 'center', backdropFilter: 'blur(10px)' }}>
                <svg width="20" height="20" viewBox="0 0 24 24" fill="white"><path d="M9 21c0 .5.4 1 1 1h4c.6 0 1-.5 1-1v-1H9v1zm3-19C8.1 2 5 5.1 5 9c0 2.4 1.2 4.5 3 5.7V17c0 .5.4 1 1 1h6c.6 0 1-.5 1-1v-2.3c1.8-1.3 3-3.4 3-5.7 0-3.9-3.1-7-7-7z"/></svg>
              </div>
              <div style={{ width: 44, height: 44, borderRadius: 22, background: 'rgba(255,255,255,0.2)', display: 'flex', justifyContent: 'center', alignItems: 'center', backdropFilter: 'blur(10px)' }}>
                <svg width="20" height="20" viewBox="0 0 24 24" fill="white"><path d="M12 15.2A3.2 3.2 0 1 0 12 8.8a3.2 3.2 0 0 0 0 6.4zM9 2L7.17 4H4c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2h-3.17L15 2H9z"/></svg>
              </div>
            </div>

            {/* Home indicator */}
            <div style={{
              position: 'absolute', bottom: 5, left: '50%', transform: 'translateX(-50%)',
              width: 100, height: 4, background: 'rgba(255,255,255,0.4)', borderRadius: 2,
            }} />
          </div>
        </div>
      </div>
    </AbsoluteFill>
  );
};
