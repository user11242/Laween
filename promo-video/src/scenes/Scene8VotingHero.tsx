import { AbsoluteFill, useCurrentFrame, useVideoConfig, spring, interpolate, Img, staticFile } from 'remotion';
import React from 'react';
import { PhoneMockup } from '../components/PhoneMockup';

/*
 * SCENE 8 — MIDPOINT DISCOVERY + VOTING (HERO)
 * "Oliva" wins. Multi-user voting.  Uses oliva_restaurant.jpg.
 * Vote progression: 0/8 → 3/8 → 6/8 → 8/8 (on Oliva)
 */

const MEMBERS = [
  { letter: 'Y', name: 'Yazan', color: '#14b8a6' },
  { letter: 'S', name: 'Sarah', color: '#a78bfa' },
  { letter: 'O', name: 'Omar', color: '#3b82f6' },
  { letter: 'L', name: 'Lina', color: '#f472b6' },
  { letter: 'A', name: 'Ahmed', color: '#f59e0b' },
  { letter: 'N', name: 'Noor', color: '#ef4444' },
  { letter: 'R', name: 'Rami', color: '#6366f1' },
  { letter: 'D', name: 'Dana', color: '#ec4899' },
];

export const Scene8VotingHero: React.FC = () => {
  const { fps } = useVideoConfig();
  const frame = useCurrentFrame();

  const phoneSpring = spring({ frame: frame - 3, fps, config: { damping: 14 } });
  const phoneScale = interpolate(phoneSpring, [0, 1], [0.9, 1]);
  const phoneOp = interpolate(frame, [3, 15], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  const mapX = interpolate(frame, [0, 270], [0, -25], { extrapolateRight: 'clamp' });
  const mapY = interpolate(frame, [0, 270], [0, -12], { extrapolateRight: 'clamp' });
  // Card phases: 0-90 (Cap soul), 90-180 (Farah), 180-270 (Oliva = winner)
  const currentCard = frame < 90 ? 0 : frame < 180 ? 1 : 2;

  // Votes: progress to 8/8 on the final card (Oliva)
  const voteTimings = [
    { frame: 65, count: 2 },
    { frame: 110, count: 3 },
    { frame: 148, count: 5 },
    { frame: 190, count: 6 },
    { frame: 225, count: 7 },
    { frame: 252, count: 8 },
  ];
  const totalVotes = voteTimings.filter(v => frame >= v.frame).length > 0
    ? voteTimings.filter(v => frame >= v.frame).pop()!.count : 0;

  const voteTap = voteTimings.some(v => frame >= v.frame && frame < v.frame + 5) ? 0.94 : 1;

  const places = [
    { name: 'The Cap soul ...', price: '$', rating: '4.5', reviews: 125, isOliva: false, image: 'capsoul.png', arrivals: [
      { n: 'You', t: '17 min', d: '7.4 km' },
      { n: 'Yazan', t: '16 min', d: '6.5 km' },
      { n: 'Sarah', t: '12 min', d: '4.8 km' },
      { n: 'Ahmad', t: '22 min', d: '9.1 km' },
    ]},
    { name: 'Farah Restaurant', price: '$$', rating: '4.2', reviews: 89, isOliva: false, image: 'alfarah.png', arrivals: [
      { n: 'You', t: '22 min', d: '9.1 km' },
      { n: 'Ahmad', t: '14 min', d: '5.8 km' },
      { n: 'Sarah', t: '8 min', d: '3.2 km' },
      { n: 'Yazan', t: '19 min', d: '7.6 km' },
    ]},
    { name: 'Oliva', price: '$', rating: '4.7', reviews: 203, isOliva: true, image: 'oliva_restaurant.jpg', arrivals: [
      { n: 'You', t: '13 min', d: '5.2 km' },
      { n: 'Yazan', t: '11 min', d: '4.3 km' },
      { n: 'Ahmad', t: '9 min', d: '3.6 km' },
      { n: 'Sarah', t: '18 min', d: '7.8 km' },
    ]},
  ];
  const place = places[currentCard];

  const titleOp = interpolate(frame, [10, 22], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const titleFade = interpolate(frame, [258, 268], [1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const exitOp = interpolate(frame, [262, 270], [1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  const mapMarkers = [
    { letter: 'W', top: 48, left: 32, color: '#0d7975' },  // You
    { letter: 'Y', top: 20, left: 38, color: '#14b8a6' },  // Yazan
    { letter: 'S', top: 26, left: 62, color: '#a78bfa' },  // Sarah
    { letter: 'A', top: 42, left: 18, color: '#f59e0b' },  // Ahmed
  ];

  return (
    <AbsoluteFill style={{ backgroundColor: '#050714', justifyContent: 'center', alignItems: 'center', opacity: exitOp }}>
      <div style={{ position: 'absolute', width: '100%', height: '100%',
        background: 'radial-gradient(ellipse at 50% 45%, rgba(20,184,166,0.06) 0%, transparent 55%)' }} />

      <div style={{
        position: 'absolute', top: '5%', width: '100%', textAlign: 'center', padding: '0 20px',
        opacity: titleOp * titleFade, zIndex: 20,
      }}>
        <h1 style={{ fontFamily: 'Inter, system-ui, sans-serif', fontSize: 64, fontWeight: 900, color: 'white', margin: 0, letterSpacing: '-0.02em', lineHeight: 1.15 }}>
          Compare places. Compare arrivals.
        </h1>
        <p style={{ fontFamily: 'Inter, system-ui, sans-serif', fontSize: 30, fontWeight: 700, color: '#5eead4', margin: '14px 0 0' }}>Vote together.</p>
      </div>

      <div style={{ transform: `scale(${phoneScale}) translateY(80px)`, opacity: phoneOp }}>
        <PhoneMockup scale={0.95} drift>
          {/* ── DARK MAP ── match suggested_midpoint_places_screen.jpeg */}
          <div style={{
            position: 'absolute', inset: 0,
            background: 'linear-gradient(180deg, #18233b 0%, #141c2f 40%, #0d1421 100%)',
            transform: `translate(${mapX}px, ${mapY}px)`,
          }}>
            {[15, 28, 38, 48, 58, 72, 85].map((p, i) => (
              <div key={`h${i}`} style={{ position: 'absolute', top: `${p}%`, left: -50, right: -50, height: Math.random() > 0.5 ? 4 : 2, background: 'rgba(45,212,191,0.08)', transform: `rotate(${Math.sin(i) * 10}deg)` }} />
            ))}
            {[10, 22, 35, 48, 62, 75, 88].map((p, i) => (
              <div key={`v${i}`} style={{ position: 'absolute', left: `${p}%`, top: -50, bottom: -50, width: Math.random() > 0.5 ? 4 : 2, background: 'rgba(45,212,191,0.06)', transform: `rotate(${Math.cos(i) * 10}deg)` }} />
            ))}

            {/* Discovery Room header — exact match top right pill */}
            <div style={{
              position: 'absolute', top: 56, right: 20,
              background: '#252d43', borderRadius: 24, padding: '12px 20px',
              display: 'flex', alignItems: 'center', gap: 10,
              boxShadow: '0 4px 16px rgba(0,0,0,0.4)', zIndex: 10,
            }}>
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#2dd4bf" strokeWidth="2.5"><circle cx="12" cy="12" r="4"/><circle cx="12" cy="12" r="9"/></svg>
              <span style={{ fontFamily: 'Inter, system-ui, sans-serif', fontSize: 16, fontWeight: 700, color: '#f8fafc' }}>Discovery Room</span>
            </div>

            {/* Markers — anchored realistically to the map */}
            {mapMarkers.map((m, i) => (
              <div key={i} style={{
                position: 'absolute', top: `${m.top}%`, left: `${m.left}%`,
                transform: 'translate(-50%, -50%)',
              }}>
                <div style={{
                  width: m.letter === 'W' ? 62 : 52, height: m.letter === 'W' ? 62 : 52,
                  borderRadius: m.letter === 'W' ? 31 : 26,
                  background: m.color,
                  border: `${m.letter === 'W' ? 4 : 3}px solid white`,
                  display: 'flex', justifyContent: 'center', alignItems: 'center',
                  boxShadow: `0 8px 24px ${m.color}60`,
                }}>
                  <span style={{ fontFamily: 'Inter, system-ui, sans-serif', fontSize: m.letter === 'W' ? 28 : 24, fontWeight: 800, color: 'white' }}>{m.letter}</span>
                </div>
              </div>
            ))}

            {/* Laween Venue Pins - 3 distinct colors */}
            {[{ top: 38, left: 54, color: '#f59e0b' }, { top: 32, left: 34, color: '#3b82f6' }, { top: 36, left: 28, color: '#ec4899' }].map((p, i) => (
              <div key={`pin${i}`} style={{
                position: 'absolute', top: `${p.top}%`, left: `${p.left}%`,
                transform: 'translate(-50%, -100%)',
              }}>
                <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
                  <div style={{
                    width: 34, height: 34, borderRadius: '50% 50% 50% 0',
                    background: p.color,
                    display: 'flex', justifyContent: 'center', alignItems: 'center', transform: 'rotate(-45deg)',
                    boxShadow: `0 6px 16px ${p.color}80`, border: '1px solid rgba(255,255,255,0.2)'
                  }}>
                    <div style={{ width: 10, height: 10, borderRadius: 5, background: 'rgba(0,0,0,0.25)' }} />
                  </div>
                </div>
              </div>
            ))}
          </div>

          {/* ── HORIZONTAL BOTTOM CARDS ── match suggested_midpoint_places_screen.jpeg */}
          <div style={{
            position: 'absolute', bottom: 10, left: 0, right: 0,
            display: 'flex', gap: 16, overflow: 'hidden', paddingLeft: 16,
          }}>
            {/* The active card */}
            <div style={{
              background: 'white', borderRadius: 36, overflow: 'hidden',
              minWidth: 340, width: 340, boxShadow: '0 8px 30px rgba(0,0,0,0.2)',
              display: 'flex', flexDirection: 'column',
            }}>
              <div style={{ display: 'flex' }}>
                {/* Photo */}
                <div style={{
                  width: '42%', minHeight: 200, position: 'relative', overflow: 'hidden',
                  background: '#cbd5e1',
                }}>
                  <img src={staticFile(place.image)} style={{
                    width: '100%', height: '100%', objectFit: 'cover', display: 'block',
                  }} />
                </div>

                {/* Details */}
                <div style={{ flex: 1, padding: '20px 16px 14px' }}>
                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 4 }}>
                    <p style={{ fontFamily: 'Inter, system-ui, sans-serif', fontSize: 18, fontWeight: 800, color: '#1e293b', margin: 0 }}>{place.name}</p>
                    <span style={{ fontFamily: 'Inter, system-ui, sans-serif', fontSize: 16, color: '#0d7975', fontWeight: 800 }}>{place.price}</span>
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 16 }}>
                    <span style={{ color: '#f59e0b', fontSize: 13 }}>⭐</span>
                    <span style={{ fontFamily: 'Inter, system-ui, sans-serif', fontSize: 13, fontWeight: 600, color: '#64748b' }}>{place.rating} ({place.reviews})</span>
                  </div>

                  <p style={{ fontFamily: 'Inter, system-ui, sans-serif', fontSize: 12, fontWeight: 800, color: '#cbd5e1', letterSpacing: '0.15em', margin: '0 0 8px' }}>ARRIVALS</p>
                  {place.arrivals.map((a, i) => (
                    <div key={i} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 6 }}>
                      <span style={{ fontFamily: 'Inter, system-ui, sans-serif', fontSize: 13, color: '#1e293b', fontWeight: 600 }}>{a.n}</span>
                      <span style={{ fontFamily: 'Inter, system-ui, sans-serif', fontSize: 13, color: '#0d7975', fontWeight: 800 }}>{a.t} <span style={{ color: '#0d7975', fontWeight: 500, fontSize: 12 }}>({a.d})</span></span>
                    </div>
                  ))}
                </div>
              </div>

              {/* Vote bar */}
              <div style={{
                display: 'flex', justifyContent: 'space-between', alignItems: 'center',
                padding: '16px 20px', borderTop: '1px solid #f1f5f9', background: 'white'
              }}>
                <span style={{ fontFamily: 'Inter, system-ui, sans-serif', fontSize: 16, fontWeight: 800, color: '#0d7975' }}>
                  {totalVotes} / 8 Votes
                </span>
                <div style={{
                  background: totalVotes === 8 ? '#22c55e' : '#0d7975',
                  borderRadius: 20, padding: '12px 30px',
                  fontFamily: 'Inter, system-ui, sans-serif', fontSize: 14, fontWeight: 800, color: 'white',
                  transform: `scale(${voteTap})`,
                  boxShadow: `0 4px 16px ${totalVotes === 8 ? 'rgba(34,197,94,0.3)' : 'rgba(13,121,117,0.3)'}`,
                }}>
                  {totalVotes === 8 ? '✓' : 'VOTE'}
                </div>
              </div>
            </div>

            {/* Glimpse of the next card -> to signify horizontal scroll */}
            <div style={{
              background: 'white', borderRadius: 36, overflow: 'hidden',
              minWidth: 340, width: 340, boxShadow: '0 8px 30px rgba(0,0,0,0.1)',
              display: 'flex', flexDirection: 'column', opacity: 0.95,
            }}>
              {/* Dummy Right Card Content */}
              <div style={{ display: 'flex', height: 200 }}>
                 <div style={{ width: '42%', background: '#cbd5e1' }} />
                 <div style={{ flex: 1, padding: '20px' }}>
                    <div style={{ width: '60%', height: 20, background: '#e2e8f0', borderRadius: 4, marginBottom: 10 }} />
                    <div style={{ width: '40%', height: 14, background: '#e2e8f0', borderRadius: 4 }} />
                 </div>
              </div>
            </div>
          </div>
        </PhoneMockup>
      </div>

      {/* Card indicators */}
      <div style={{ position: 'absolute', bottom: '6%', display: 'flex', gap: 6 }}>
        {[0, 1, 2].map((i) => (
          <div key={i} style={{
            width: currentCard === i ? 22 : 7, height: 7, borderRadius: 4,
            background: currentCard === i ? '#14b8a6' : 'rgba(255,255,255,0.12)',
          }} />
        ))}
      </div>
    </AbsoluteFill>
  );
};
