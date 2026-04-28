import { AbsoluteFill, useCurrentFrame, useVideoConfig, spring, interpolate, Img, staticFile } from 'remotion';
import React from 'react';
import { PhoneMockup } from '../components/PhoneMockup';
import { SplashAppUI } from '../components/SplashAppUI';

/*
 * SCENE 1 — MULTI-POV CHAOS
 * N/S/E/W layout showing planning frustration.
 * Unifies into the central Hero phone via the Laween Symbol.
 */

// Simulated Pre-Laween Generic Chat
const GenericChatStub: React.FC<{ frame: number, msgs: {text: string, isMe: boolean, fDelay: number}[] }> = ({ frame, msgs }) => {
  const { fps } = useVideoConfig();
  
  return (
    <div style={{ width: '100%', height: '100%', background: '#ffffff', display: 'flex', flexDirection: 'column' }}>
      {/* Generic header */}
      <div style={{ height: 140, background: '#f9fafb', borderBottom: '2px solid #e5e7eb', display: 'flex', alignItems: 'flex-end', padding: '0 24px 20px' }}>
        <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="#3b82f6" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" style={{ marginBottom: 4 }}><path d="M15 18l-6-6 6-6" /></svg>
        <div style={{ width: 56, height: 56, borderRadius: 28, background: '#d1d5db', marginLeft: 16 }} />
        <div style={{ marginLeft: 16 }}>
          <div style={{ fontFamily: 'system-ui', fontWeight: 700, fontSize: 26, color: 'black', lineHeight: 1.2 }}>Group Chat</div>
          <div style={{ fontFamily: 'system-ui', fontSize: 18, color: '#6b7280', lineHeight: 1.2 }}>4 People</div>
        </div>
      </div>
      
      {/* Chaotic messages feed */}
      <div style={{ flex: 1, padding: '24px', display: 'flex', flexDirection: 'column', gap: 20, overflow: 'hidden', justifyContent: 'flex-end', paddingBottom: 40 }}>
        {msgs.map((m, i) => {
          const popSpring = spring({ frame: frame - m.fDelay, fps, config: { damping: 14 } });
          const scale = interpolate(popSpring, [0, 1], [0.8, 1]);
          const op = interpolate(popSpring, [0, 1], [0, 1]);
          
          if (frame < m.fDelay) return null;
          
          return (
            <div key={i} style={{
              alignSelf: m.isMe ? 'flex-end' : 'flex-start',
              background: m.isMe ? '#3b82f6' : '#e5e7eb',
              color: m.isMe ? 'white' : 'black',
              padding: '16px 24px', borderRadius: 32,
              borderBottomRightRadius: m.isMe ? 8 : 32,
              borderBottomLeftRadius: m.isMe ? 32 : 8,
              fontFamily: 'system-ui, -apple-system', fontSize: 26, fontWeight: 500,
              transform: `scale(${scale})`, opacity: op,
              transformOrigin: m.isMe ? 'bottom right' : 'bottom left',
              maxWidth: '85%', lineHeight: 1.35, boxShadow: '0 4px 16px rgba(0,0,0,0.06)'
            }}>
              {m.text}
            </div>
          );
        })}
      </div>
      
      {/* Input bar */}
      <div style={{ height: 100, borderTop: '2px solid #e5e7eb', display: 'flex', alignItems: 'center', padding: '0 24px', background: '#f9fafb' }}>
        <div style={{ flex: 1, height: 64, borderRadius: 32, border: '2px solid #d1d5db', background: 'white', display: 'flex', alignItems: 'center', paddingLeft: 24 }}>
          <span style={{ fontFamily: 'system-ui', fontSize: 22, color: '#9ca3af', fontWeight: 500 }}>iMessage</span>
        </div>
      </div>
    </div>
  );
};

// Simulated Pre-Laween Generic Map
const GenericMapStub: React.FC<{ frame: number }> = ({ frame }) => {
  const { fps } = useVideoConfig();
  const pan = interpolate(spring({ frame: frame - 20, fps, config: { damping: 30 } }), [0, 1], [0, -60]);
  const inputSpring = spring({ frame: frame - 40, fps, config: { damping: 14 } });
  
  return (
    <div style={{ width: '100%', height: '100%', background: '#f5f5f4', position: 'relative', overflow: 'hidden' }}>
      {/* Moving map grid & shapes simulation */}
      <div style={{ position: 'absolute', width: '200%', height: '200%', top: '-50%', left: '-50%', transform: `translate(${pan}px, ${pan}px)` }}>
        <div style={{ position: 'absolute', top: '20%', left: '10%', width: 300, height: 400, background: '#dcfce7', borderRadius: 40 }} />
        <div style={{ position: 'absolute', top: '60%', right: '10%', width: 400, height: 300, background: '#e0f2fe', borderRadius: 40 }} />
        <div style={{ position: 'absolute', top: 0, bottom: 0, left: '40%', width: 24, background: '#ffffff', transform: 'rotate(15deg)' }} />
        <div style={{ position: 'absolute', left: 0, right: 0, top: '45%', height: 32, background: '#ffffff', transform: 'rotate(-5deg)' }} />
        <div style={{ position: 'absolute', inset: 0, backgroundImage: 'radial-gradient(#d1d5db 2px, transparent 0)', backgroundSize: '40px 40px', opacity: 0.8 }} />
      </div>
      
      {/* Generic Map Pin */}
      <div style={{ position: 'absolute', top: '45%', left: '50%', transform: 'translate(-50%, -100%)', display: 'flex', flexDirection: 'column', alignItems: 'center', filter: 'drop-shadow(0 10px 10px rgba(0,0,0,0.3))' }}>
        <div style={{ width: 48, height: 48, background: '#ef4444', borderRadius: '24px 24px 0 24px', transform: 'rotate(45deg)', border: '6px solid white', display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
          <div style={{ width: 14, height: 14, background: '#7f1d1d', borderRadius: 7 }} />
        </div>
      </div>
      
      {/* Search Input */}
      <div style={{ position: 'absolute', top: 64, left: 24, right: 24, background: 'white', borderRadius: 16, boxShadow: '0 8px 32px rgba(0,0,0,0.15)', overflow: 'hidden' }}>
        <div style={{ height: 76, display: 'flex', alignItems: 'center', padding: '0 24px' }}>
          <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#9ca3af" strokeWidth="2.5"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
          <span style={{ fontFamily: 'system-ui', fontSize: 24, color: '#4b5563', marginLeft: 16, fontWeight: 500 }}>Cafe{inputSpring > 0.5 ? 's near' : ''}</span>
          {frame > 40 && frame < 90 && Math.floor(frame / 10) % 2 === 0 && <span style={{ width: 3, height: 26, background: '#3b82f6', marginLeft: 4 }} />}
        </div>
      </div>
      
      {/* Bottom sheet skeleton */}
      <div style={{ position: 'absolute', bottom: 0, left: 0, right: 0, height: 260, background: 'white', borderRadius: '32px 32px 0 0', padding: 32, boxShadow: '0 -8px 32px rgba(0,0,0,0.1)' }}>
        <div style={{ width: 60, height: 6, background: '#e5e7eb', borderRadius: 3, margin: '0 auto 32px' }} />
        <div style={{ width: '70%', height: 36, background: '#f3f4f6', borderRadius: 8, marginBottom: 20 }} />
        <div style={{ width: '50%', height: 24, background: '#f3f4f6', borderRadius: 6 }} />
      </div>
    </div>
  );
};

export const Scene1MultiPOV: React.FC = () => {
  const { fps } = useVideoConfig();
  const frame = useCurrentFrame();

  const titleOp = interpolate(frame, [5, 15], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const titleFade = interpolate(frame, [100, 115], [1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  // Explode phase: phones push away gracefully and fade out to clear the center
  const explodeSpring = spring({ frame: frame - 100, fps, config: { damping: 18, stiffness: 80 } });
  const explode = interpolate(explodeSpring, [0, 1], [0, 1]);

  // --- True Anchor Lock Constants ---
  const SPLASH_LOGO_PIXEL_WIDTH = 129; // Scaled up ~40% to match the visual size of the logo in the phone
  const SPLASH_OPTICAL_OFFSET_Y = -18; // Exact calibrated pixel shift matching the naked optical offset of the provided reference image

  // Anchor Logo Phase: Appears more slowly, holds, then shrinks/fades out elegantly
  const logoOpIn = interpolate(frame, [105, 125], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const logoOpOut = interpolate(frame, [140, 165], [1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const logoOp = frame < 135 ? logoOpIn : logoOpOut;

  // Softer spring for a less aggressive, more premium pop
  const logoEntrySpring = spring({ frame: frame - 105, fps, config: { damping: 16, stiffness: 60 } });
  const logoScaleIn = interpolate(logoEntrySpring, [0, 1], [0.5, 4.0]);
  
  // Longer shrink duration to match the smooth fade out
  const logoScaleOut = interpolate(frame, [140, 165], [4.0, 1.0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const logoScale = frame < 140 ? logoScaleIn : logoScaleOut;

  const PHONES = [
    // Top Phone
    { startX: 0, startY: -130, comp: <GenericChatStub frame={frame} msgs={[
      {text: 'Anyone know a good spot?', isMe: false, fDelay: 0}, 
      {text: 'Where are we meeting?', isMe: true, fDelay: 30}
    ]} /> },
    // Bottom Phone
    { startX: 0, startY: 300, comp: <GenericChatStub frame={frame} msgs={[
      {text: 'Too far for me.', isMe: true, fDelay: 15}, 
      {text: 'Restaurant or cafe?', isMe: false, fDelay: 45}
    ]} /> },
    // Left Phone
    { startX: -450, startY: 70, comp: <GenericMapStub frame={frame} /> },
    // Right Phone
    { startX: 450, startY: 70, comp: <GenericChatStub frame={frame} msgs={[
      {text: 'Still figuring it out...', isMe: false, fDelay: 25}, 
      {text: 'Waiting for a clear plan.', isMe: true, fDelay: 60}
    ]} /> },
  ];

  const floatingText = [
    { text: "Where are we meeting?", x: '20%', y: '25%', delay: 10 },
    { text: "Too far for me.", x: '82%', y: '28%', delay: 20 },
    { text: "Restaurant or cafe?", x: '20%', y: '82%', delay: 35 },
    { text: "Waiting for a clear plan.", x: '80%', y: '78%', delay: 50 },
    { text: "Send the location", x: '10%', y: '50%', delay: 65 },
    { text: "Still figuring it out...", x: '90%', y: '52%', delay: 40 },
  ];

  return (
    <AbsoluteFill style={{ backgroundColor: '#050714', justifyContent: 'center', alignItems: 'center' }}>
      <div style={{ position: 'absolute', width: '100%', height: '100%',
        background: 'radial-gradient(ellipse at 50% 50%, rgba(20,184,166,0.06) 0%, transparent 55%)' }} />

      {/* Floating Chaos Messages */}
      {floatingText.map((t, i) => {
        const floatSpring = spring({ frame: frame - t.delay, fps, config: { damping: 20 } });
        const floatIn = interpolate(floatSpring, [0, 1], [0, 1]);
        const fadeOut = interpolate(frame, [100 + i * 2, 115 + i * 2], [1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
        // Drift upwards
        const drift = interpolate(frame, [t.delay, t.delay + 100], [0, -30], { extrapolateRight: 'clamp' });

        if (frame < t.delay) return null;

        return (
          <div key={i} style={{
            position: 'absolute', left: t.x, top: t.y,
            transform: `translate(-50%, -50%) translateY(${drift}px)`,
            opacity: floatIn * fadeOut * 0.55,
            fontFamily: 'Inter, system-ui', fontSize: 36, fontWeight: 700, color: '#e2e8f0',
            textShadow: '0 8px 32px rgba(255,255,255,0.2)', filter: 'blur(1.5px)',
            pointerEvents: 'none', zIndex: 1, letterSpacing: '-0.02em', whiteSpace: 'nowrap'
          }}>
            {t.text}
          </div>
        );
      })}

      {/* Main Title Safely positioned */}
      <div style={{
        position: 'absolute', top: '5.5%', width: '100%', textAlign: 'center',
        opacity: titleOp * titleFade, zIndex: 20,
      }}>
        <h1 style={{ fontFamily: 'Inter, system-ui, sans-serif', fontSize: 64, fontWeight: 900, color: 'white', margin: 0, letterSpacing: '-0.02em', lineHeight: 1.15 }}>
          One group. One flow.
        </h1>
        <p style={{ fontFamily: 'Inter, system-ui, sans-serif', fontSize: 30, fontWeight: 600, color: '#5eead4', margin: '14px 0 0' }}>
          From chaos to coordination.
        </p>
      </div>

      <div style={{ position: 'absolute', top: '50%', left: '50%', width: 1920, height: 1080, transform: 'translate(-50%, -50%)' }}>
        
        {/* The 4 Pre-Laween Problem Phones */}
        {PHONES.map((p, i) => {
          // Slide in organically
          const inSpring = spring({ frame: frame - (5 + i * 5), fps, config: { damping: 16 } });
          const baseScale = interpolate(inSpring, [0, 1], [0.35, 0.45]); // N/S/E/W original downscaled fit
          const op = interpolate(inSpring, [0, 1], [0, 1]);

          // Explode outwards logic
          const dirX = p.startX > 0 ? 1 : p.startX < 0 ? -1 : 0;
          const dirY = p.startY > 0 ? 1 : p.startY < 0 ? -1 : 0;
          
          const curX = p.startX + (dirX * 350 * explode);
          const curY = p.startY + (dirY * 350 * explode);
          
          // Fade out as they are pushed away
          const finalOp = interpolate(explode, [0, 0.6], [op, 0], { extrapolateRight: 'clamp' });

          return (
            <div key={i} style={{
               position: 'absolute', top: '50%', left: '50%',
               // Apply push away translation
               transform: `translate(-50%, -50%) translate(${curX}px, ${curY}px) scale(${baseScale})`,
               opacity: finalOp, zIndex: 10,
            }}>
              <PhoneMockup scale={1.0} drift={false}>
                {p.comp}
              </PhoneMockup>
            </div>
          );
        })}

        {/* The Master Anchor Logo: Drops in, shrinks, and fades out.*/}
        <div style={{
          position: 'absolute', top: '50%', left: '50%',
          transform: `translate(calc(-50% - 19px), calc(-50% + ${SPLASH_OPTICAL_OFFSET_Y - 49}px)) scale(${logoScale})`,
          opacity: logoOp, zIndex: 15,
          display: 'flex', flexDirection: 'column', alignItems: 'center'
        }}>
          <Img src={staticFile('app_pin_logo.png')} style={{ width: SPLASH_LOGO_PIXEL_WIDTH, height: SPLASH_LOGO_PIXEL_WIDTH, filter: 'drop-shadow(0 10px 40px rgba(20,184,166,0.6))' }} />
        </div>

        {/* Splash Screen Phone: Fades in underneath the single master logo */}
        {frame >= 155 && (
          <div style={{
            position: 'absolute', top: '50%', left: '50%',
            // Sub-pixel positional correction manually mapped from optical discrepancies so the native baked-in logo sits flawlessly aligned below the hard-locked Global Anchor pin.
            transform: `translate(calc(-50% - 22px), calc(-50% - 12px))`,
            // Reveal phone chassis elegantly and slowly underneath the shrinking logo, starting when logo is almost size 1.0
            opacity: interpolate(frame, [160, 175], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' }),
            zIndex: 14 // Resides mathematically beneath the anchor layer
          }}>
            <PhoneMockup scale={0.95} drift={false}>
              <SplashAppUI localFrame={Math.max(0, frame - 160)} />
            </PhoneMockup>
          </div>
        )}
      </div>
    </AbsoluteFill>
  );
};
