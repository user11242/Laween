import { AbsoluteFill, useCurrentFrame, useVideoConfig, spring, interpolate, Img, staticFile } from 'remotion';
import React from 'react';
import { PhoneMockup } from '../components/PhoneMockup';
import { IosNotification } from '../components/IosNotification';
import { WeekendChat } from '../components/WeekendChat';

/*
 * SCENE 5b — OUTING RESPONSES (CAUSE-AND-EFFECT FLOW)
 *
 * TIMELINE (180 frames = 6s @ 30fps):
 *   f  0–10  : Scene fades in. Hero phone shows the chat.
 *   f  0–30  : Title "Everyone gets the call." fades in.
 *   f 10–30  : Outing session card slides into the hero phone's chat (cause).
 *   f 35–60  : Three response phones slide in from sides.
 *   f 50–90  : Notifications drop onto each response phone (effect), staggered.
 *   f 90–120 : Notification slides off. App opens on response phones.
 *   f 150–160: All elements fade out. Scene ends.
 */

const clamp = (v: number, lo = 0, hi = 1) => Math.max(lo, Math.min(hi, v));

// Outing session card shown in the chat — proof the outing was actually created
const OutingSessionCard: React.FC<{ opacity: number; slideY: number }> = ({ opacity, slideY }) => (
  <div style={{
    display: 'flex', justifyContent: 'flex-end',
    opacity, transform: `translateY(${slideY}px)`,
    paddingRight: 0,
  }}>
    <div style={{
      background: 'linear-gradient(135deg, #0d7975, #0a5c5a)',
      borderRadius: '16px 16px 4px 16px',
      overflow: 'hidden',
      boxShadow: '0 6px 20px rgba(13,121,117,0.35)',
      width: 220,
    }}>
      {/* Header */}
      <div style={{
        padding: '10px 14px 8px',
        borderBottom: '1px solid rgba(255,255,255,0.12)',
        display: 'flex', alignItems: 'center', gap: 8,
      }}>
        <div style={{
          width: 28, height: 28, borderRadius: 14,
          background: 'rgba(255,255,255,0.18)',
          display: 'flex', justifyContent: 'center', alignItems: 'center', flexShrink: 0,
        }}>
          {/* Lightning bolt = outing */}
          <svg width="14" height="14" viewBox="0 0 24 24" fill="white">
            <path d="M13 2L3 14h9l-1 8 10-12h-9l1-8z" />
          </svg>
        </div>
        <div>
          <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 12, fontWeight: 800, color: 'white', margin: 0, letterSpacing: '-0.01em' }}>Outing Session</p>
          <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 10, color: 'rgba(255,255,255,0.6)', margin: 0 }}>Started by You</p>
        </div>
      </div>
      {/* Body */}
      <div style={{ padding: '10px 14px 12px' }}>
        <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 13, fontWeight: 700, color: 'white', margin: '0 0 4px' }}>Weekend Plans 🎉</p>
        <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 11, color: 'rgba(255,255,255,0.7)', margin: '0 0 10px', lineHeight: 1.4 }}>Find Midpoint · 4 members invited</p>
        <div style={{
          background: 'rgba(255,255,255,0.14)',
          borderRadius: 10, padding: '7px 12px',
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
        }}>
          <svg width="12" height="12" viewBox="0 0 24 24" fill="white">
            <path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7z" />
          </svg>
          <span style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 11, fontWeight: 700, color: 'white' }}>Add Your Location</span>
        </div>
      </div>
    </div>
  </div>
);

// Hero phone: chat with outing card appearing
const HeroPhoneChat: React.FC<{ frame: number }> = ({ frame }) => {
  const cardOp = clamp(interpolate(frame, [10, 22], [0, 1]));
  const cardSlideY = interpolate(
    spring({ frame: frame - 10, fps: 30, config: { damping: 14 } }),
    [0, 1], [24, 0]
  );
  return (
    <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column' }}>
      {/* Pass chatShift=0 — we just need the base chat */}
      <WeekendChat chatShift={0} />
      {/* Outing card overlaid at bottom of the message list */}
      <div style={{
        position: 'absolute',
        bottom: 76, // sits just above the input bar
        left: 14, right: 14,
      }}>
        <OutingSessionCard opacity={cardOp} slideY={cardSlideY} />
      </div>
    </div>
  );
};

// Simulated join flow UIs for response phones
const AuthenticJoinFlows: React.FC<{ type: 'gps' | 'type' | 'map'; frame: number }> = ({ type, frame }) => {
  const op = clamp(interpolate(frame, [0, 10], [0, 1]));
  const loadProg = clamp(interpolate(frame, [15, 60], [0, 1]));

  return (
    <div style={{ width: '100%', height: '100%', background: '#f6f7f9', display: 'flex', flexDirection: 'column', opacity: op, overflow: 'hidden', position: 'relative' }}>

      {type === 'type' && (
        <div style={{ background: 'linear-gradient(145deg,#62b5b3 0%,#309896 40%,#0d7975 100%)', height: 120, padding: '56px 24px 0', position: 'relative', overflow: 'hidden', flexShrink: 0, boxShadow: '0 4px 20px rgba(0,0,0,0.08)' }}>
          <div style={{ position: 'absolute', top: -50, right: -60, width: 270, height: 270, borderRadius: '50%', background: 'rgba(255,255,255,0.07)' }} />
          <h2 style={{ fontFamily: 'Inter, system-ui, sans-serif', fontSize: 28, fontWeight: 800, color: 'white', margin: 0, letterSpacing: '-0.01em' }}>Join Session</h2>
        </div>
      )}

      {type === 'gps' && (
        <div style={{ flex: 1, position: 'relative' }}>
          <Img src={staticFile('map_screen.jpeg')} style={{ position: 'absolute', top: 0, left: 0, right: 0, bottom: '40%', width: '130%', height: '80%', objectFit: 'cover', transform: 'translate(-15%, -5%)' }} />
          <div style={{ position: 'absolute', bottom: 0, left: 0, right: 0, top: '45%', background: '#fff', borderTopLeftRadius: 36, borderTopRightRadius: 36, padding: '36px 24px 30px', display: 'flex', flexDirection: 'column', boxShadow: '0 -10px 40px rgba(0,0,0,0.08)' }}>
            <div style={{ width: 44, height: 6, background: '#e2e8f0', borderRadius: 3, margin: '-20px auto 24px' }} />
            <div style={{ display: 'flex', alignItems: 'center', gap: 18 }}>
              <div style={{ width: 56, height: 56, borderRadius: 28, background: '#e8f3f2', display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
                <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="#0d7975" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10"/><circle cx="12" cy="12" r="3" fill="#0d7975"/></svg>
              </div>
              <div style={{ flex: 1 }}>
                <p style={{ margin: 0, fontFamily: 'Inter, system-ui', fontSize: 20, fontWeight: 800, color: '#1e293b' }}>Current Location</p>
                <p style={{ margin: '4px 0 0', fontFamily: 'Inter, system-ui', fontSize: 15, color: '#64748b', fontWeight: 500 }}>{loadProg > 0.8 ? 'Accurate to 5 meters' : 'Acquiring GPS signal...'}</p>
              </div>
            </div>
            <div style={{ flex: 1 }} />
            <div style={{ width: '100%', height: 64, background: loadProg > 0.8 ? '#0d7975' : '#cbd5e1', borderRadius: 20, display: 'flex', justifyContent: 'center', alignItems: 'center', boxShadow: loadProg > 0.8 ? '0 12px 24px rgba(13,121,117,0.25)' : 'none' }}>
              <span style={{ color: 'white', fontFamily: 'Inter, system-ui', fontWeight: 800, fontSize: 18 }}>Confirm Starting Point</span>
            </div>
          </div>
        </div>
      )}

      {type === 'type' && (
        <div style={{ flex: 1, padding: '24px 20px', display: 'flex', flexDirection: 'column' }}>
          <div style={{ background: 'white', borderRadius: 20, padding: '16px 20px', display: 'flex', alignItems: 'center', gap: 14, boxShadow: '0 2px 14px rgba(0,0,0,0.05)' }}>
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#0d7975" strokeWidth="2.5" strokeLinecap="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
            <span style={{ fontFamily: 'Inter, system-ui', fontSize: 18, fontWeight: 600, color: '#1e293b' }}>Princess sumaya unive{loadProg > 0.5 ? 'rsity|' : '|'}</span>
          </div>
          <div style={{ marginTop: 28, background: 'white', borderRadius: 24, padding: '8px 0', overflow: 'hidden', boxShadow: '0 4px 20px rgba(0,0,0,0.03)' }}>
            <div style={{ padding: '18px 24px', display: 'flex', alignItems: 'center', gap: 18, borderBottom: '1px solid #f1f5f9' }}>
               <div style={{ width: 46, height: 46, borderRadius: 23, background: '#f8fafc', display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
                 <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#64748b" strokeWidth="2"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/><circle cx="12" cy="10" r="3"/></svg>
               </div>
               <div>
                  <p style={{ margin: 0, fontFamily: 'Inter, system-ui', fontSize: 17, fontWeight: 700, color: '#1e293b' }}>Princess Sumaya University</p>
                  <p style={{ margin: '4px 0 0', fontFamily: 'Inter, system-ui', fontSize: 14, color: '#94a3b8', fontWeight: 500 }}>Al Jubeiha, Amman</p>
               </div>
            </div>
          </div>
        </div>
      )}

      {type === 'map' && (
        <div style={{ flex: 1, position: 'relative', overflow: 'hidden', backgroundColor: '#1d2331' }}>
          <Img src={staticFile('dark_map.jpg')} style={{ position: 'absolute', top: 0, left: 0, width: '100%', height: '106%', objectFit: 'cover', transform: 'translateY(-3%)', opacity: interpolate(loadProg, [0, 1], [0.6, 1]) }} />
        </div>
      )}
    </div>
  );
};

export const Scene5bResponses: React.FC = () => {
  const { fps } = useVideoConfig();
  const frame = useCurrentFrame();

  // ── Timing constants ──────────────────────────────────────
  // STEP 1: Hero phone shows — outing card slides in at f10
  const CARD_IN       = 10;
  // STEP 2: Response phones slide in after card is visible
  const PHONES_IN     = 35;
  // STEP 3: Notifications hit response phones, staggered
  const NOTIF_BASE    = 55;   // first notification drops
  const NOTIF_EXIT    = 100;  // notifications slide away
  // STEP 4: App opens on response phones after notification tapped
  const APP_OPEN      = 108;
  // Exit
  const FADE_OUT      = 162;
  const SCENE_END     = 180;

  // ── Global exit ───────────────────────────────────────────
  const exitOp = clamp(interpolate(frame, [FADE_OUT, SCENE_END], [1, 0]));

  // ── Title ─────────────────────────────────────────────────
  const titleOp = clamp(interpolate(frame, [5, 18], [0, 1]));
  const titleFade = clamp(interpolate(frame, [FADE_OUT - 12, FADE_OUT], [1, 0]));

  // ── Response phones entry ─────────────────────────────────
  const resSpring = spring({ frame: frame - PHONES_IN, fps, config: { damping: 14 } });
  const resOp = clamp(interpolate(resSpring, [0, 1], [0, 1]));
  const resExitOp = clamp(interpolate(frame, [FADE_OUT - 15, FADE_OUT], [1, 0]));

  const responses = [
    { x: -620, y: 60,  scale: 0.72, type: 'gps'  as const, delay: 0  },
    { x:  620, y: 60,  scale: 0.72, type: 'type' as const, delay: 5  },
    { x:    0, y: 330, scale: 0.65, type: 'map'  as const, delay: 10 },
  ];

  return (
    <AbsoluteFill style={{ backgroundColor: '#050714', justifyContent: 'center', alignItems: 'center', opacity: exitOp }}>
      <div style={{ position: 'absolute', width: '100%', height: '100%',
        background: 'radial-gradient(ellipse at 50% 50%, rgba(20,184,166,0.04) 0%, transparent 60%)' }} />

      {/* ── Title ─────────────────────────────────────────── */}
      <div style={{
        position: 'absolute', top: '5%', width: '100%', textAlign: 'center',
        opacity: titleOp * titleFade, zIndex: 20,
      }}>
        <h1 style={{ fontFamily: 'Inter, system-ui, sans-serif', fontSize: 64, fontWeight: 900, color: 'white', margin: 0, letterSpacing: '-0.02em', lineHeight: 1.15 }}>
          Everyone gets the call.
        </h1>
        <p style={{ fontFamily: 'Inter, system-ui, sans-serif', fontSize: 30, fontWeight: 600, color: '#5eead4', margin: '14px 0 0' }}>
          Outing posted → group notified → everyone joins.
        </p>
      </div>

      <div style={{ position: 'absolute', top: '50%', left: '50%', width: 1920, height: 1080, transform: 'translate(-50%, -50%)' }}>

        {/* ══ STEP 1 + 2: HERO PHONE — shows outing card being posted in chat ══ */}
        <div style={{ position: 'absolute', top: '50%', left: '50%', transform: 'translate(-50%, -50%) translateY(60px)', zIndex: 10 }}>
          <PhoneMockup scale={0.95} drift={false}>
            <HeroPhoneChat frame={frame} />
          </PhoneMockup>
        </div>

        {/* ══ STEP 3 + 4: RESPONSE PHONES — appear after outing card is posted ══ */}
        {responses.map((p, i) => {
          // Each phone slides in
          const phoneSpring = spring({ frame: frame - (PHONES_IN + p.delay), fps, config: { damping: 14 } });
          const phoneOp = frame >= PHONES_IN + p.delay
            ? clamp(interpolate(phoneSpring, [0, 1], [0, 1]))
            : 0;
          const phoneSlide = interpolate(phoneSpring, [0, 1], [60, 0]);

          // Notification: drops down after card is visible, staggered per phone
          const notifDelay = NOTIF_BASE + i * 8;
          const notifExitDelay = NOTIF_EXIT + i * 4;
          const notifInSp = spring({ frame: frame - notifDelay, fps, config: { damping: 14 } });
          const notifOutSp = spring({ frame: frame - notifExitDelay, fps, config: { damping: 14 } });
          const notifY = frame < notifDelay ? -120
            : frame < notifExitDelay ? interpolate(notifInSp, [0, 1], [-120, 16])
            : interpolate(notifOutSp, [0, 1], [16, -120]);
          const notifOp = frame < notifDelay ? 0
            : frame < notifExitDelay ? clamp(interpolate(frame, [notifDelay, notifDelay + 5], [0, 1]))
            : clamp(interpolate(frame, [notifExitDelay, notifExitDelay + 6], [1, 0]));

          // App opens after notification slides off
          const isAppOpen = frame >= APP_OPEN + p.delay;

          return (
            <div key={i} style={{
              position: 'absolute', top: '50%', left: '50%',
              transform: `translate(-50%, -50%) translate(${p.x}px, ${p.y}px) translateY(${phoneSlide}px) scale(${p.scale})`,
              opacity: phoneOp * resOp * resExitOp,
              zIndex: 5,
            }}>
              <PhoneMockup scale={1.0} drift={false}>
                {/* Lock screen / dark state until app opens */}
                <div style={{ width: '100%', height: '100%', background: 'linear-gradient(135deg, #0f172a, #1e293b)', position: 'relative' }}>

                  {/* App join flow opens after notification tapped */}
                  {isAppOpen && <AuthenticJoinFlows type={p.type} frame={frame - APP_OPEN - p.delay} />}

                  {/* iOS Notification — only on response phones, never on hero */}
                  <div style={{
                    position: 'absolute', top: 0, left: 0, right: 0,
                    display: 'flex', justifyContent: 'center', pointerEvents: 'none',
                    transform: `translateY(${notifY}px)`, zIndex: 50,
                    padding: '0 12px',
                  }}>
                    <IosNotification
                      title="Weekend Plans 🎉"
                      subtitle={"Outing session started\nAdd your location to join"}
                    />
                  </div>

                </div>
              </PhoneMockup>
            </div>
          );
        })}
      </div>
    </AbsoluteFill>
  );
};
