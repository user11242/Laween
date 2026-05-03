import { AbsoluteFill, useCurrentFrame, useVideoConfig, spring, interpolate, Img, staticFile } from 'remotion';
import React from 'react';
import { PhoneMockup } from '../components/PhoneMockup';

/*
 * SCENE 9 — WINNER
 * 150 frames (5s). "Oliva" wins. Canonical group: Yazan Qattous, Sarah, Ahmad, You.
 */
export const Scene9Winner: React.FC = () => {
  const { fps } = useVideoConfig();
  const frame = useCurrentFrame();

  const phoneSpring = spring({ frame: frame - 3, fps, config: { damping: 14 } });
  const phoneScale = interpolate(phoneSpring, [0, 1], [0.92, 1]);

  // Winner card entrance spring
  const cardSpring = spring({ frame: frame - 12, fps, config: { damping: 12, stiffness: 120 } });
  const cardScale = interpolate(cardSpring, [0, 1], [0.88, 1]);
  const cardOp = interpolate(frame, [12, 22], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  // Gold glow sweep across the winner image
  const sweepX = interpolate(frame, [18, 60], [-100, 200], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  const titleOp = interpolate(frame, [8, 20], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const titleFade = interpolate(frame, [138, 148], [1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const exitOp = interpolate(frame, [142, 150], [1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  const friends = [
    { rank: 1, name: 'Yazan Qattous', dist: '3.2 km', eta: '8 min', avatar: '#14b8a6', arriving: false },
    { rank: 2, name: 'Sarah',         dist: '5.1 km', eta: '12 min', avatar: '#a78bfa', arriving: false },
    { rank: 3, name: 'Ahmad',         dist: '7.4 km', eta: '16 min', avatar: '#f59e0b', arriving: false },
    { rank: 4, name: 'You',           dist: '8.9 km', eta: '19 min', avatar: '#006D77', arriving: false },
  ];

  return (
    <AbsoluteFill style={{ backgroundColor: '#050714', justifyContent: 'center', alignItems: 'center', opacity: exitOp }}>
      <div style={{ position: 'absolute', width: '100%', height: '100%',
        background: 'radial-gradient(ellipse at 50% 45%, rgba(251,191,36,0.05) 0%, transparent 55%)' }} />

      {/* Scene Title — unified system */}
      <div style={{
        position: 'absolute', top: '5%', width: '100%', textAlign: 'center', padding: '0 24px',
        opacity: titleOp * titleFade, zIndex: 20,
      }}>
        <h1 style={{ fontFamily: 'Inter, system-ui, sans-serif', fontSize: 64, fontWeight: 900, color: 'white', margin: 0, letterSpacing: '-0.02em', lineHeight: 1.15 }}>
          The group has a winner.
        </h1>
        <p style={{ fontFamily: 'Inter, system-ui, sans-serif', fontSize: 30, fontWeight: 600, color: '#5eead4', margin: '14px 0 0' }}>
          Oliva is the fairest pick.
        </p>
      </div>

      <div style={{ transform: `scale(${phoneScale}) translateY(80px)` }}>
        <PhoneMockup scale={0.95} drift>
          <div style={{
            position: 'absolute', inset: 0, background: '#f8fafc', overflow: 'hidden',
            display: 'flex', flexDirection: 'column',
          }}>
            {/* Trophy header matching winner_screen.jpeg exactly */}
              <div style={{
                backgroundColor: '#2b3648',
                padding: '64px 20px 24px', display: 'flex', alignItems: 'center', gap: 16,
              }}>
                <div style={{
                  width: 44, height: 44, borderRadius: 22,
                  backgroundColor: '#1e3944',
                  display: 'flex', justifyContent: 'center', alignItems: 'center',
                }}>
                  <span style={{ fontSize: 20, textShadow: '0 2px 4px rgba(0,0,0,0.5)' }}>🏆</span>
                </div>
                <h2 style={{ fontFamily: 'Outfit, system-ui, sans-serif', fontSize: 24, fontWeight: 900, color: 'white', margin: 0, letterSpacing: '0.04em' }}>THE WINNER</h2>
              </div>

            {/* Winner card — Oliva with real photo */}
            <div style={{ padding: '24px 20px 16px', opacity: cardOp, transform: `scale(${cardScale})`, transformOrigin: 'top center' }}>
              <div style={{
                borderRadius: 24, overflow: 'hidden', position: 'relative',
                boxShadow: '0 8px 40px rgba(251,191,36,0.2), 0 4px 20px rgba(0,0,0,0.12)', height: 220,
              }}>
                <Img src={staticFile('oliva_restaurant.jpg')} style={{
                  width: '100%', height: '100%', objectFit: 'cover',
                }} />
                {/* Gold light sweep */}
                <div style={{
                  position: 'absolute', inset: 0,
                  background: `linear-gradient(105deg, transparent ${sweepX - 30}%, rgba(251,191,36,0.22) ${sweepX}%, transparent ${sweepX + 30}%)`,
                  pointerEvents: 'none',
                }} />
                <div style={{
                  position: 'absolute', bottom: 0, left: 0, right: 0, height: '60%',
                  background: 'linear-gradient(180deg, transparent 0%, rgba(0,0,0,0.82) 100%)',
                }} />
                <div style={{ position: 'absolute', bottom: 18, left: 22 }}>
                  <h3 style={{ fontFamily: 'Outfit, system-ui, sans-serif', fontSize: 30, fontWeight: 800, color: 'white', margin: '0 0 4px', textShadow: '0 2px 8px rgba(0,0,0,0.4)' }}>Oliva</h3>
                  <span style={{ fontFamily: 'Outfit, system-ui, sans-serif', fontSize: 15, fontWeight: 800, color: '#5eead4' }}>Winning Destination</span>
                </div>
              </div>
            </div>

            {/* Friends progress list */}
            <div style={{ padding: '8px 20px' }}>
              <p style={{ fontFamily: 'Outfit, system-ui, sans-serif', fontSize: 12, fontWeight: 800, color: '#a9a9a9', letterSpacing: '0.15em', margin: '0 0 14px' }}>
                FRIENDS' PROGRESS
              </p>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
                {friends.map((f, i) => {
                  const entryOp = interpolate(frame, [20 + i * 8, 32 + i * 8], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
                  return (
                    <div key={i} style={{
                      background: 'white', borderRadius: 20, padding: '14px 18px',
                      display: 'flex', alignItems: 'center', gap: 14,
                      boxShadow: '0 2px 12px rgba(0,0,0,0.05)',
                      opacity: entryOp,
                    }}>
                      {/* Rank */}
                      <div style={{
                        width: 38, height: 38, borderRadius: 19, flexShrink: 0,
                        background: i === 0 ? '#fbbf24' : '#f1f5f9',
                        display: 'flex', justifyContent: 'center', alignItems: 'center',
                      }}>
                        <span style={{ fontFamily: 'Outfit, system-ui, sans-serif', fontSize: 16, fontWeight: 800, color: i === 0 ? 'white' : '#64748b' }}>{f.rank}</span>
                      </div>
                      {/* Avatar */}
                      <div style={{
                        width: 38, height: 38, borderRadius: 19, flexShrink: 0,
                        background: f.avatar,
                        display: 'flex', justifyContent: 'center', alignItems: 'center',
                      }}>
                        <span style={{ fontFamily: 'Outfit, system-ui, sans-serif', fontSize: 16, fontWeight: 800, color: 'white' }}>{f.name[0]}</span>
                      </div>
                      {/* Name + metrics */}
                      <div style={{ flex: 1 }}>
                        <p style={{ fontFamily: 'Outfit, system-ui, sans-serif', fontSize: 14, fontWeight: 800, color: '#2D3748', margin: '0 0 4px' }}>{f.name}</p>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                          <span style={{ fontFamily: 'Inter, system-ui, sans-serif', fontSize: 12, color: '#94a3b8', fontWeight: 600 }}>📍 {f.dist}</span>
                          <span style={{ fontFamily: 'Inter, system-ui, sans-serif', fontSize: 12, color: '#94a3b8', fontWeight: 600 }}>⏱ {f.eta}</span>
                        </div>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>

            {/* Bottom action buttons */}
            <div style={{
              position: 'absolute', bottom: 0, left: 0, right: 0, padding: '20px 20px 44px',
              display: 'flex', flexDirection: 'column', gap: 12,
              background: 'linear-gradient(180deg, rgba(248,250,252,0) 0%, #f8fafc 18%)',
            }}>
              <div style={{
                background: 'white', border: '2px solid #006D77', borderRadius: 16, padding: '16px 0',
                display: 'flex', justifyContent: 'center', alignItems: 'center', gap: 10,
              }}>
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#006D77" strokeWidth="2.5"><circle cx="12" cy="12" r="10"/><circle cx="12" cy="12" r="3"/></svg>
                <span style={{ fontFamily: 'Outfit, system-ui, sans-serif', fontSize: 15, fontWeight: 800, color: '#006D77' }}>TRACK FRIENDS' JOURNEY</span>
              </div>
              <div style={{
                background: '#006D77', borderRadius: 16, padding: '16px 0',
                display: 'flex', justifyContent: 'center', alignItems: 'center', gap: 10,
                boxShadow: '0 8px 24px rgba(0,109,119,0.3)',
              }}>
                <svg width="18" height="18" viewBox="0 0 24 24" fill="white"><path d="M22 2L11 13M22 2L15 22L11 13L2 9L22 2Z"/></svg>
                <span style={{ fontFamily: 'Outfit, system-ui, sans-serif', fontSize: 15, fontWeight: 800, color: 'white' }}>GET DIRECTIONS</span>
              </div>
              <div style={{ textAlign: 'center', paddingTop: 4 }}>
                <span style={{ fontFamily: 'Outfit, system-ui, sans-serif', fontSize: 14, fontWeight: 700, color: '#a9a9a9' }}>EXIT DISCOVERY</span>
              </div>
            </div>
          </div>
        </PhoneMockup>
      </div>
    </AbsoluteFill>
  );
};
