import { AbsoluteFill, useCurrentFrame, useVideoConfig, spring, interpolate, Img, staticFile } from 'remotion';
import React from 'react';
import { PhoneMockup } from '../components/PhoneMockup';
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

// Outing session card shown in the chat — rebuilt from Flutter UI reference
const OutingSessionCard: React.FC<{ opacity: number; slideY: number }> = ({ opacity, slideY }) => (
  <div style={{
    display: 'flex', flexDirection: 'column', alignItems: 'flex-end',
    opacity, transform: `translateY(${slideY}px)`,
    marginTop: 8,
  }}>
    <div style={{
      background: 'white',
      borderRadius: '24px 24px 4px 24px',
      padding: '20px',
      boxShadow: '0 4px 16px rgba(0,0,0,0.06)',
      width: 250,
    }}>
      {/* Top Row: Icon + Title */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 16 }}>
        <div style={{ width: 40, height: 40, borderRadius: 20, background: '#FFE4E6', display: 'flex', justifyContent: 'center', alignItems: 'center', flexShrink: 0 }}>
          <svg width="20" height="20" viewBox="0 0 24 24" fill="#E11D48">
            <path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z" />
          </svg>
        </div>
        <span style={{ fontFamily: 'Outfit,system-ui,sans-serif', fontSize: 18, fontWeight: 900, color: 'black' }}>Outing Session</span>
      </div>

      {/* Subtext - Matches "Live" styling from reference */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 16 }}>
        <span style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 14, fontWeight: 700, color: '#34A853' }}>Live</span>
        <span style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 14, fontWeight: 700, color: '#94a3b8' }}>·</span>
        <span style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 14, fontWeight: 500, color: '#64748b' }}>4:54 min remaining</span>
      </div>

      {/* Divider */}
      <div style={{ height: 1, background: '#F1F5F9', marginBottom: 16 }} />

      {/* Button */}
      <div style={{
        background: '#006D77',
        borderRadius: 24,
        padding: '12px',
        display: 'flex', justifyContent: 'center', alignItems: 'center',
      }}>
        <span style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 15, fontWeight: 700, color: 'white' }}>Join</span>
      </div>
    </div>
    
    {/* Timestamp below card */}
    <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 11, color: '#94a3b8', margin: '6px 4px 0 0', textAlign: 'right' }}>
      12:28 PM <span style={{color: '#83C5BE', letterSpacing: '-0.25em', paddingRight: 4}}>✔✔</span>
    </p>
  </div>
);

const HeroPhoneChat: React.FC<{ frame: number }> = ({ frame }) => {
  const cardOp = clamp(interpolate(frame, [10, 22], [0, 1]));
  const cardSlideY = interpolate(
    spring({ frame: frame - 10, fps: 30, config: { damping: 14 } }),
    [0, 1], [24, 0]
  );
  
  // Animate chat scrolling up when the card appears
  // Card height is ~200px. We scroll the chat up to make room for it natively.
  const chatShift = interpolate(
    spring({ frame: frame - 10, fps: 30, config: { damping: 14 } }),
    [0, 1], [0, 230]
  );

  return (
    <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column' }}>
      <WeekendChat chatShift={chatShift}>
        <OutingSessionCard opacity={cardOp} slideY={cardSlideY} />
      </WeekendChat>
    </div>
  );
};

// High-fidelity iOS lock screen notification
const AuthenticIosNotification: React.FC<{ title: string; subtitle: string; time?: string }> = ({ title, subtitle, time = "1m ago" }) => (
  <div style={{
    width: '100%',
    background: 'rgba(30, 41, 59, 0.65)',
    backdropFilter: 'blur(20px)',
    WebkitBackdropFilter: 'blur(20px)',
    borderRadius: 24,
    padding: '16px',
    display: 'flex', gap: 14,
    boxShadow: '0 8px 32px rgba(0,0,0,0.2)',
    border: '1px solid rgba(255,255,255,0.08)'
  }}>
    <div style={{ width: 44, height: 44, borderRadius: 10, background: 'white', display: 'flex', justifyContent: 'center', alignItems: 'center', flexShrink: 0, overflow: 'hidden' }}>
      <Img src={staticFile('app_pin_logo.png')} style={{ width: '100%', height: '100%', objectFit: 'contain' }} />
    </div>
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 4 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <span style={{ fontFamily: 'system-ui, -apple-system, sans-serif', fontSize: 16, fontWeight: 600, color: 'white', letterSpacing: '-0.01em' }}>{title}</span>
        <span style={{ fontFamily: 'system-ui, -apple-system, sans-serif', fontSize: 13, color: 'rgba(255,255,255,0.6)' }}>{time}</span>
      </div>
      <span style={{ fontFamily: 'system-ui, -apple-system, sans-serif', fontSize: 15, color: 'rgba(255,255,255,0.9)', lineHeight: 1.3, whiteSpace: 'pre-wrap' }}>{subtitle}</span>
    </div>
  </div>
);

// High-fidelity location entry screens matching Flutter references
const ScaleWrapper: React.FC<{ children: React.ReactNode; bg: string }> = ({ children, bg }) => (
  <div style={{ width: '100%', height: '100%', background: bg, overflow: 'hidden' }}>
    <div style={{ width: '125%', height: '125%', transform: 'scale(0.8)', transformOrigin: 'top left', position: 'relative' }}>
      {children}
    </div>
  </div>
);

const AuthenticJoinFlows: React.FC<{ type: 'dark_map' | 'type_search' | 'light_map'; frame: number }> = ({ type, frame }) => {
  const loadProg = clamp(interpolate(frame, [15, 60], [0, 1]));

  if (type === 'dark_map') {
    return (
      <ScaleWrapper bg="#1d2331">
        <Img src={staticFile('dark_map.jpg')} style={{ position: 'absolute', top: 0, left: 0, width: '140%', height: '140%', objectFit: 'cover', transform: 'translate(-15%, -15%)' }} />
        
        {/* Top Search Pill */}
        <div style={{ position: 'absolute', top: 80, left: 24, right: 24, background: 'white', borderRadius: 20, padding: '18px 24px', display: 'flex', alignItems: 'center', gap: 14, boxShadow: '0 6px 20px rgba(0,0,0,0.15)' }}>
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#006D77" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
          <span style={{ fontFamily: 'Inter, system-ui', fontSize: 18, color: '#94a3b8' }}>Search for a neighborhood or plac...</span>
        </div>

        {/* Center Red Pin */}
        <div style={{ position: 'absolute', top: '50%', left: '50%', transform: 'translate(-50%, -50%)', display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
          <div style={{ width: 36, height: 36, background: '#EF4444', borderRadius: '18px 18px 18px 0', transform: 'rotate(-45deg)', display: 'flex', justifyContent: 'center', alignItems: 'center', boxShadow: '0 6px 16px rgba(239,68,68,0.4)' }}>
            <div style={{ width: 14, height: 14, background: 'white', borderRadius: 7 }} />
          </div>
        </div>

        {/* Bottom Confirm Button */}
        <div style={{ position: 'absolute', bottom: 50, left: 24, right: 24, background: '#006D77', borderRadius: 18, padding: '18px', display: 'flex', justifyContent: 'center', alignItems: 'center', boxShadow: '0 6px 20px rgba(0,109,119,0.35)' }}>
          <span style={{ fontFamily: 'Outfit, system-ui', fontSize: 20, fontWeight: 700, color: 'white' }}>Confirm Start Location</span>
        </div>
      </ScaleWrapper>
    );
  }

  if (type === 'light_map') {
    return (
      <ScaleWrapper bg="#f8fafc">
        <Img src={staticFile('map_screen.jpeg')} style={{ position: 'absolute', top: 0, left: 0, width: '140%', height: '140%', objectFit: 'cover', transform: 'translate(-15%, -15%)' }} />
        
        <div style={{ position: 'absolute', top: 80, left: 24, right: 24, background: 'white', borderRadius: 20, padding: '18px 24px', display: 'flex', alignItems: 'center', gap: 14, boxShadow: '0 6px 20px rgba(0,0,0,0.08)' }}>
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#006D77" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
          <span style={{ fontFamily: 'Inter, system-ui', fontSize: 18, color: '#94a3b8' }}>Search for a neighborhood or plac...</span>
        </div>


        {/* Pin removed — map_screen.jpeg already contains the location pin */}


        {/* Bottom Confirm Button */}
        <div style={{ position: 'absolute', bottom: 50, left: 24, right: 24, background: '#006D77', borderRadius: 18, padding: '18px', display: 'flex', justifyContent: 'center', alignItems: 'center', boxShadow: '0 6px 20px rgba(0,109,119,0.35)' }}>
          <span style={{ fontFamily: 'Outfit, system-ui', fontSize: 20, fontWeight: 700, color: 'white' }}>Confirm Start Location</span>
        </div>
      </ScaleWrapper>
    );
  }

  if (type === 'type_search') {
    // Typing starts after APP_OPEN — 6 frames per character, clearly readable
    const typeProg = clamp(interpolate(frame, [5, 47], [0, 1]));
    const fullText = "princes";
    const typedText = fullText.slice(0, Math.floor(typeProg * fullText.length));
    
    // Tap first result after full word is typed
    const isTapped = frame > 58;
    const highlightBg = isTapped ? '#f1f5f9' : 'white';

    return (
      <ScaleWrapper bg="#f8fafc">
        <div style={{ width: '100%', height: '100%', position: 'relative', display: 'flex', flexDirection: 'column' }}>
          {/* Dimmed light map in background */}
          <div style={{ position: 'absolute', inset: 0 }}>
             <Img src={staticFile('custom_map.jpg')} style={{ width: '150%', height: '150%', objectFit: 'cover', opacity: 0.6, transform: 'translate(-20%, -20%)', filter: 'invert(1) hue-rotate(180deg) brightness(1.1) contrast(0.9)' }} />
          </div>

          {/* Top Dropdown Area */}
          <div style={{ position: 'relative', zIndex: 10, flex: 1, padding: '80px 24px 0' }}>
            <div style={{ background: 'white', borderRadius: 20, overflow: 'hidden', boxShadow: '0 12px 40px rgba(0,0,0,0.15)' }}>
              
              {/* Search Input */}
              <div style={{ padding: '20px 24px', display: 'flex', alignItems: 'center', gap: 14, borderBottom: '1px solid #f1f5f9' }}>
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#006D77" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
                <span style={{ fontFamily: 'Inter, system-ui', fontSize: 20, color: '#1e293b', flex: 1 }}>{typedText}<span style={{ opacity: frame % 30 < 15 ? 1 : 0, color: '#006D77' }}>|</span></span>
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
              </div>

              {/* Results (Only show if typed something) */}
              {typedText.length > 2 && (
                <div style={{ display: 'flex', flexDirection: 'column' }}>
                  <div style={{ padding: '20px 24px', display: 'flex', gap: 16, alignItems: 'flex-start', background: highlightBg, transition: 'background 0.2s' }}>
                    <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#006D77" strokeWidth="2" style={{ marginTop: 2 }}><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/><circle cx="12" cy="10" r="3"/></svg>
                    <div>
                      <p style={{ margin: 0, fontFamily: 'Outfit, system-ui', fontSize: 18, fontWeight: 700, color: '#1e293b' }}>Princess Sumaya University for Technology</p>
                      <p style={{ margin: '6px 0 0', fontFamily: 'Inter, system-ui', fontSize: 15, color: '#64748b' }}>Khalil Al-Saket St. Amman, Jordan</p>
                    </div>
                  </div>
                  <div style={{ padding: '20px 24px', display: 'flex', gap: 16, alignItems: 'flex-start', borderTop: '1px solid #f1f5f9' }}>
                    <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#006D77" strokeWidth="2" style={{ marginTop: 2 }}><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/><circle cx="12" cy="10" r="3"/></svg>
                    <div>
                      <p style={{ margin: 0, fontFamily: 'Outfit, system-ui', fontSize: 18, fontWeight: 700, color: '#1e293b' }}>Prince Hamza Hospital</p>
                      <p style={{ margin: '6px 0 0', fontFamily: 'Inter, system-ui', fontSize: 15, color: '#64748b' }}>XWMQ+P56, Al Mahd, Amman, Jordan</p>
                    </div>
                  </div>
                </div>
              )}
              
              {/* Confirm button fades in after tap */}
              {isTapped && (
                 <div style={{ padding: '20px' }}>
                    <div style={{ background: '#006D77', borderRadius: 16, padding: '18px', display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
                      <span style={{ fontFamily: 'Outfit, system-ui', fontSize: 20, fontWeight: 700, color: 'white' }}>Confirm Start Location</span>
                    </div>
                 </div>
              )}
            </div>
          </div>

          {/* Light iOS Keyboard Replica */}
          <div style={{ height: 340, background: '#d1d5db', display: 'flex', flexDirection: 'column', zIndex: 20 }}>
          {/* Suggestion Bar */}
          <div style={{ height: 50, display: 'flex', borderBottom: '1px solid #9ca3af' }}>
            <div style={{ flex: 1, display: 'flex', justifyContent: 'center', alignItems: 'center', borderRight: '1px solid #9ca3af' }}><span style={{ fontFamily: 'system-ui', fontSize: 16, color: '#1e293b' }}>"princes"</span></div>
            <div style={{ flex: 1, display: 'flex', justifyContent: 'center', alignItems: 'center', borderRight: '1px solid #9ca3af' }}><span style={{ fontFamily: 'system-ui', fontSize: 16, color: '#1e293b' }}>princess</span></div>
            <div style={{ flex: 1, display: 'flex', justifyContent: 'center', alignItems: 'center' }}><span style={{ fontFamily: 'system-ui', fontSize: 16, color: '#1e293b' }}>princesses</span></div>
          </div>
          {/* Keys Area */}
          <div style={{ flex: 1, padding: '16px 8px', display: 'flex', flexDirection: 'column', gap: 12 }}>
            {/* Row 1 */}
            <div style={{ display: 'flex', gap: 8, justifyContent: 'center' }}>
              {['q','w','e','r','t','y','u','i','o','p'].map(k => (
                <div key={k} style={{ width: 38, height: 48, background: 'white', borderRadius: 8, display: 'flex', justifyContent: 'center', alignItems: 'center', boxShadow: '0 1px 2px rgba(0,0,0,0.3)' }}>
                  <span style={{ fontFamily: 'system-ui', fontSize: 24, color: 'black' }}>{k}</span>
                </div>
              ))}
            </div>
            {/* Row 2 */}
            <div style={{ display: 'flex', gap: 8, justifyContent: 'center', padding: '0 20px' }}>
              {['a','s','d','f','g','h','j','k','l'].map(k => (
                <div key={k} style={{ width: 38, height: 48, background: 'white', borderRadius: 8, display: 'flex', justifyContent: 'center', alignItems: 'center', boxShadow: '0 1px 2px rgba(0,0,0,0.3)' }}>
                  <span style={{ fontFamily: 'system-ui', fontSize: 24, color: 'black' }}>{k}</span>
                </div>
              ))}
            </div>
            {/* Row 3 */}
            <div style={{ display: 'flex', gap: 8, justifyContent: 'center' }}>
              <div style={{ width: 50, height: 48, background: '#9ca3af', borderRadius: 8, display: 'flex', justifyContent: 'center', alignItems: 'center', boxShadow: '0 1px 2px rgba(0,0,0,0.3)' }}>
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="black" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 19V5M5 12l7-7 7 7"/></svg>
              </div>
              {['z','x','c','v','b','n','m'].map(k => (
                <div key={k} style={{ width: 38, height: 48, background: 'white', borderRadius: 8, display: 'flex', justifyContent: 'center', alignItems: 'center', boxShadow: '0 1px 2px rgba(0,0,0,0.3)' }}>
                  <span style={{ fontFamily: 'system-ui', fontSize: 24, color: 'black' }}>{k}</span>
                </div>
              ))}
              <div style={{ width: 50, height: 48, background: '#9ca3af', borderRadius: 8, display: 'flex', justifyContent: 'center', alignItems: 'center', boxShadow: '0 1px 2px rgba(0,0,0,0.3)' }}>
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="black" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 4H8l-7 8 7 8h13a2 2 0 0 0 2-2V6a2 2 0 0 0-2-2zM18 9l-6 6M12 9l6 6"/></svg>
              </div>
            </div>
            {/* Row 4 */}
            <div style={{ display: 'flex', gap: 8, justifyContent: 'center' }}>
              <div style={{ width: 50, height: 48, background: '#9ca3af', borderRadius: 8, display: 'flex', justifyContent: 'center', alignItems: 'center', boxShadow: '0 1px 2px rgba(0,0,0,0.3)' }}>
                <span style={{ fontFamily: 'system-ui', fontSize: 18, color: 'black' }}>123</span>
              </div>
              <div style={{ flex: 1, height: 48, background: 'white', borderRadius: 8, display: 'flex', justifyContent: 'center', alignItems: 'center', boxShadow: '0 1px 2px rgba(0,0,0,0.3)' }}>
                <span style={{ fontFamily: 'system-ui', fontSize: 18, color: 'black' }}>space</span>
              </div>
              <div style={{ width: 100, height: 48, background: '#007AFF', borderRadius: 8, display: 'flex', justifyContent: 'center', alignItems: 'center', boxShadow: '0 1px 2px rgba(0,0,0,0.3)' }}>
                <span style={{ color: 'white', fontSize: 18, fontWeight: 'bold' }}>Search</span>
              </div>
            </div>
          </div>
        </div>
        </div>
      </ScaleWrapper>
    );
  }

  return null;
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
  const NOTIF_EXIT    = 160;  // notifications slide away
  // STEP 4: App opens on response phones after notification dismissed
  const APP_OPEN      = 168;
  // Exit — extended so type_search has time to type + select after APP_OPEN
  const FADE_OUT      = 270;
  const SCENE_END     = 300;

  // ── Global exit ───────────────────────────────────────────
  const exitOp = clamp(interpolate(frame, [FADE_OUT, SCENE_END], [1, 0]));

  // ── Title ─────────────────────────────────────────────────
  // Fade out title once phones start moving in to make room
  const titleOp = clamp(interpolate(frame, [5, 18], [0, 1]));
  const titleFade = clamp(interpolate(frame, [PHONES_IN, PHONES_IN + 10], [1, 0]));

  // ── Response phones & Hero layout ─────────────────────────
  // Hero phone minimizes and shifts dramatically up so bottom phone has space
  const heroScaleSpring = spring({ frame: frame - PHONES_IN, fps, config: { damping: 14 } });
  const heroScale = interpolate(heroScaleSpring, [0, 1], [0.95, 0.60]);
  const heroSlideY = interpolate(heroScaleSpring, [0, 1], [60, -250]);

  const resSpring = spring({ frame: frame - PHONES_IN, fps, config: { damping: 14 } });
  const resOp = clamp(interpolate(resSpring, [0, 1], [0, 1]));
  const resExitOp = clamp(interpolate(frame, [FADE_OUT - 15, FADE_OUT], [1, 0]));

  // Position 3 phones: Left, Right, and Center Bottom.
  // We use scale 0.60 for all to ensure they fit without overlapping.
  const responses = [
    { x: -650, y: 50, scale: 0.60, type: 'dark_map' as const, delay: 0 },
    { x:  650, y: 50, scale: 0.60, type: 'type_search' as const, delay: 5 },
    { x:    0, y: 290, scale: 0.60, type: 'light_map' as const, delay: 10 },
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
          Real-time invites. Multiple ways to join.
        </p>
      </div>

      <div style={{ position: 'absolute', top: '50%', left: '50%', width: 1920, height: 1080, transform: 'translate(-50%, -50%)' }}>

        {/* ══ STEP 1 + 2: HERO PHONE — shows outing card being posted in chat ══ */}
        <div style={{ position: 'absolute', top: '50%', left: '50%', transform: `translate(-50%, -50%) translateY(${heroSlideY}px)`, zIndex: 10 }}>
          <PhoneMockup scale={heroScale} drift={false}>
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
            : frame < notifExitDelay ? interpolate(notifInSp, [0, 1], [-120, 72])
            : interpolate(notifOutSp, [0, 1], [72, -120]);
          const notifOp = frame < notifDelay ? 0
            : frame < notifExitDelay ? clamp(interpolate(frame, [notifDelay, notifDelay + 5], [0, 1]))
            : clamp(interpolate(frame, [notifExitDelay, notifExitDelay + 6], [1, 0]));

          // All phones wait for notification to dismiss before app opens
          const isAppOpen = frame >= APP_OPEN + p.delay;
          const localFrame = frame - APP_OPEN - p.delay;

          return (
            <div key={i} style={{
              position: 'absolute', top: '50%', left: '50%',
              transform: `translate(-50%, -50%) translate(${p.x}px, ${p.y}px) translateY(${phoneSlide}px) scale(${p.scale})`,
              opacity: phoneOp * resOp * resExitOp,
              zIndex: 20 + i, // Above hero phone
            }}>
              <PhoneMockup scale={1.0} drift={false}>
                <div style={{ width: '100%', height: '100%', position: 'relative', overflow: 'hidden' }}>
                  {/* Join Flow UI running immediately (simulating the app state underneath) */}
                  <AuthenticJoinFlows type={p.type} frame={localFrame} />

                  {/* Dark overlay simulating lock screen/app background before app fully opens */}
                  <div style={{
                    position: 'absolute', inset: 0,
                    background: 'linear-gradient(135deg, #0f172a, #1e293b)',
                    opacity: isAppOpen ? 0 : 1,
                    transition: 'opacity 0.3s'
                  }} />

                  {/* High-Fidelity iOS Notification */}
                  <div style={{
                    position: 'absolute', top: 0, left: 0, right: 0,
                    display: 'flex', justifyContent: 'center', pointerEvents: 'none',
                    transform: `translateY(${notifY}px)`, zIndex: 50,
                    padding: '0 12px',
                    opacity: notifOp
                  }}>
                    <AuthenticIosNotification
                      title="Weekend Plans 🎉"
                      subtitle={"Outing session started"}
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
