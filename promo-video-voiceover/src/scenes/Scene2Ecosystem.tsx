import {
  AbsoluteFill, useCurrentFrame, useVideoConfig,
  spring, interpolate, Img, staticFile,
} from 'remotion';
import React from 'react';
import { PhoneMockup } from '../components/PhoneMockup';

/*
 * SCENE 2 — THE ECOSYSTEM (final)
 *
 * 145 frames · no offset trick · starts directly in group chat
 * cf = frame (no phase offset needed)
 *
 * Chat events:
 *   cf  0-10  : base messages appear (Ahmed, User, Sarah)
 *   cf  30    : photo event appears in chat
 *   cf  66    : location card appears in chat
 *   cf 100    : outing session card appears in chat
 *
 * Callout timing:
 *   PHOTO   : appear=15, dismiss=46  (photo visible by f30, bubble gone at f46)
 *   LOCATION: appear=52, dismiss=82  (location visible by f66, bubble ONLY gone at f82)
 *   OUTING  : appear=88, dismiss=118 (outing visible by f100, bubble gone at f118)
 *
 * Phone stays visible throughout and never disappears before events resolve.
 */

const ec    = (t: number) => 1 - Math.pow(1 - Math.max(0, Math.min(1, t)), 3);
const clamp = (v: number, lo = 0, hi = 1) => Math.max(lo, Math.min(hi, v));

/* ════════════════════════════════════════════════════════════════
 * GROUP CHAT — faithful Laween UI
 * cf = frame directly; base messages start at cf=0
 * ════════════════════════════════════════════════════════════════ */
const GroupChat: React.FC<{ cf: number }> = ({ cf }) => {
  const op = (s: number, d = 8) =>
    interpolate(cf, [s, s + d], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  
  // Adjusted translateY to accommodate the new messages.
  const ty = (s: number, d = 8) => {
    const entry = interpolate(cf, [s, s + d], [14, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
    const scroll1 = interpolate(cf, [50, 58], [0, -110], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
    const scroll2 = interpolate(cf, [115, 122], [0, -90], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
    return entry + scroll1 + scroll2;
  };

  // Typing Sequence Logic
  const typingStart = 85;
  const typingEnd = 110;
  const messageSent = 115;
  const fullText = "Let's start an outing session.";
  
  const textChars = Math.floor(interpolate(cf, [typingStart, typingEnd], [0, fullText.length], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' }));
  const currentText = fullText.substring(0, textChars);
  const isTyping = cf >= typingStart && cf < messageSent;
  const hasText = currentText.length > 0 && cf < messageSent;
  const showNewMessage = cf >= messageSent;
  
  // Button press effect at messageSent
  const sendScale = interpolate(cf, [messageSent - 2, messageSent, messageSent + 2], [1, 0.8, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  return (
    <div style={{ position: 'absolute', inset: 0, backgroundColor: '#F5F6F8', display: 'flex', flexDirection: 'column' }}>
      {/* Header - Fidelity Matched */}
      <div style={{ backgroundColor: 'white', padding: '46px 16px 14px', display: 'flex', alignItems: 'center', gap: 12, boxShadow: '0 1px 4px rgba(0,0,0,0.04)', zIndex: 10, flexShrink: 0 }}>
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#1e293b" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" style={{ flexShrink: 0 }}><path d="M15 18l-6-6 6-6" /></svg>
        <div style={{ width: 42, height: 42, borderRadius: 21, background: '#f59e0b', display: 'flex', justifyContent: 'center', alignItems: 'center', flexShrink: 0 }}>
          <span style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 18, fontWeight: 800, color: 'white' }}>W</span>
        </div>
        <div style={{ flex: 1 }}>
          <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 17, fontWeight: 800, color: '#1e293b', margin: 0 }}>Weekend Plans 🎉</p>
          <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 13, color: '#94a3b8', margin: '1px 0 0' }}>4 members</p>
        </div>
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#006D77" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
          <circle cx="18" cy="5" r="3" /><circle cx="6" cy="12" r="3" /><circle cx="18" cy="19" r="3" />
          <line x1="8.59" y1="13.51" x2="15.42" y2="17.49" /><line x1="15.41" y1="6.51" x2="8.59" y2="10.49" />
        </svg>
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#006D77" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" style={{ marginLeft: 8 }}>
          <circle cx="12" cy="12" r="10" /><line x1="12" y1="16" x2="12" y2="12" /><line x1="12" y1="8" x2="12.01" y2="8" />
        </svg>
      </div>

      {/* Messages Area */}
      <div style={{ flex: 1, padding: '16px 14px 8px', display: 'flex', flexDirection: 'column', gap: 12, overflow: 'hidden' }}>
        
        {/* Date Pill */}
        <div style={{ display: 'flex', justifyContent: 'center', marginBottom: 4, transform: `translateY(${ty(0)}px)` }}>
          <div style={{ background: 'white', padding: '4px 12px', borderRadius: 12, boxShadow: '0 1px 2px rgba(0,0,0,0.02)' }}>
            <span style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 12, color: '#64748b', fontWeight: 600 }}>Yesterday</span>
          </div>
        </div>

        {/* Ahmed base */}
        <div style={{ display: 'flex', alignItems: 'flex-end', gap: 8, opacity: op(0), transform: `translateY(${ty(0)}px)` }}>
          <div style={{ width: 28, height: 28, borderRadius: 14, background: '#f59e0b', display: 'flex', justifyContent: 'center', alignItems: 'center', flexShrink: 0, marginBottom: 2 }}>
            <span style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 12, fontWeight: 800, color: 'white' }}>A</span>
          </div>
          <div style={{ background: 'white', borderRadius: '4px 16px 16px 16px', padding: '8px 12px', boxShadow: '0 1px 2px rgba(0,0,0,0.03)', maxWidth: '80%' }}>
            <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 12, color: '#006D77', margin: '0 0 2px 0', fontWeight: 700 }}>Ahmed</p>
            <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 15, color: '#1e293b', margin: 0, lineHeight: 1.4 }}>Let's plan for tonight! 🎉</p>
            <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 11, color: '#94a3b8', margin: '4px 0 0 0' }}>03:57 AM</p>
          </div>
        </div>

        {/* User reply */}
        <div style={{ display: 'flex', justifyContent: 'flex-end', opacity: op(5), transform: `translateY(${ty(5)}px)` }}>
          <div style={{ background: 'linear-gradient(135deg, #83C5BE, #006D77)', borderRadius: '16px 4px 16px 16px', padding: '8px 12px', boxShadow: '0 2px 6px rgba(0,109,119,0.15)', maxWidth: '80%' }}>
            <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 15, color: 'white', margin: 0, lineHeight: 1.4 }}>I'm down! Where should we meet? 👀</p>
            <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 11, color: 'rgba(255,255,255,0.75)', margin: '4px 0 0 0', textAlign: 'right' }}>03:58 AM <span style={{color: '#83C5BE', letterSpacing: '-0.25em', paddingRight: 4}}>✔✔</span></p>
          </div>
        </div>

        {/* Sarah */}
        <div style={{ display: 'flex', alignItems: 'flex-end', gap: 8, opacity: op(10), transform: `translateY(${ty(10)}px)` }}>
          <div style={{ width: 28, height: 28, borderRadius: 14, background: '#a78bfa', display: 'flex', justifyContent: 'center', alignItems: 'center', flexShrink: 0, marginBottom: 2 }}>
            <span style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 12, fontWeight: 800, color: 'white' }}>S</span>
          </div>
          <div style={{ background: 'white', borderRadius: '4px 16px 16px 16px', padding: '8px 12px', boxShadow: '0 1px 2px rgba(0,0,0,0.03)', maxWidth: '80%' }}>
            <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 12, color: '#006D77', margin: '0 0 2px 0', fontWeight: 700 }}>Sarah</p>
            <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 15, color: '#1e293b', margin: 0, lineHeight: 1.4 }}>Restaurant or a cafe? 🍕</p>
            <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 11, color: '#94a3b8', margin: '4px 0 0 0' }}>04:19 AM</p>
          </div>
        </div>

        {/* ── CHAT EVENT 1: Photo (cf=30) ── */}
        <div style={{ display: 'flex', alignItems: 'flex-end', gap: 8, opacity: op(30, 10), transform: `translateY(${ty(30, 10)}px)` }}>
          <div style={{ width: 28, height: 28, borderRadius: 14, background: '#f59e0b', display: 'flex', justifyContent: 'center', alignItems: 'center', flexShrink: 0, marginBottom: 2 }}>
            <span style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 12, fontWeight: 800, color: 'white' }}>A</span>
          </div>
          <div style={{ background: 'white', borderRadius: '4px 16px 16px 16px', padding: '4px', boxShadow: '0 1px 2px rgba(0,0,0,0.03)', maxWidth: '80%' }}>
            <img src={staticFile('shared_image.jpg')} style={{ width: 200, height: 130, objectFit: 'cover', borderRadius: '4px 12px 4px 4px', display: 'block' }} alt="" />
            <div style={{ padding: '6px 8px' }}>
              <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 15, color: '#1e293b', margin: 0, lineHeight: 1.4 }}>What about this place? 🧋</p>
              <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 11, color: '#94a3b8', margin: '4px 0 0 0' }}>12:20 PM</p>
            </div>
          </div>
        </div>

        {/* ── NEW CHAT EVENT: Context (cf=50) ── */}
        <div style={{ display: 'flex', alignItems: 'flex-end', gap: 8, opacity: op(50, 10), transform: `translateY(${ty(50, 10)}px)` }}>
          <div style={{ width: 28, height: 28, borderRadius: 14, background: '#a78bfa', display: 'flex', justifyContent: 'center', alignItems: 'center', flexShrink: 0, marginBottom: 2 }}>
            <span style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 12, fontWeight: 800, color: 'white' }}>S</span>
          </div>
          <div style={{ background: 'white', borderRadius: '4px 16px 16px 16px', padding: '8px 12px', boxShadow: '0 1px 2px rgba(0,0,0,0.03)', maxWidth: '80%' }}>
            <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 12, color: '#006D77', margin: '0 0 2px 0', fontWeight: 700 }}>Sarah</p>
            <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 15, color: '#1e293b', margin: 0, lineHeight: 1.4 }}>I'll send my location.</p>
            <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 11, color: '#94a3b8', margin: '4px 0 0 0' }}>12:22 PM</p>
          </div>
        </div>

        {/* ── CHAT EVENT 2: Location card (cf=66) ── */}
        <div style={{ display: 'flex', alignItems: 'flex-end', gap: 8, opacity: op(66, 10), transform: `translateY(${ty(66, 10)}px)` }}>
          <div style={{ width: 28, height: 28, borderRadius: 14, background: '#a78bfa', display: 'flex', justifyContent: 'center', alignItems: 'center', flexShrink: 0, marginBottom: 2 }}>
            <span style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 12, fontWeight: 800, color: 'white' }}>S</span>
          </div>
          <div style={{ background: 'white', borderRadius: '4px 16px 16px 16px', overflow: 'hidden', boxShadow: '0 1px 3px rgba(0,0,0,0.04)', width: 220 }}>
            <div style={{ height: 80, background: 'linear-gradient(135deg, #a78bfa, #8b5cf6)', display: 'flex', justifyContent: 'center', alignItems: 'center', position: 'relative' }}>
              <div style={{ position: 'absolute', inset: 0, opacity: 0.15 }}>
                {[25, 50, 75].map(p => <div key={p} style={{ position: 'absolute', top: `${p}%`, left: 0, right: 0, height: 1, background: 'white' }} />)}
                {[33, 66].map(p => <div key={p} style={{ position: 'absolute', left: `${p}%`, top: 0, bottom: 0, width: 1, background: 'white' }} />)}
              </div>
              <div style={{ width: 34, height: 34, borderRadius: 17, background: 'white', display: 'flex', justifyContent: 'center', alignItems: 'center', boxShadow: '0 4px 12px rgba(0,0,0,0.15)', zIndex: 1 }}>
                <svg width="18" height="18" viewBox="0 0 24 24" fill="#8b5cf6"><path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7z" /></svg>
              </div>
            </div>
            <div style={{ padding: '10px 12px' }}>
              <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 12, color: '#8b5cf6', margin: '0 0 2px 0', fontWeight: 700 }}>Sarah</p>
              <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 14, fontWeight: 700, color: '#1e293b', margin: '0 0 2px' }}>Current Location</p>
              <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 12, color: '#64748b', margin: 0 }}>Tap to open</p>
              <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 11, color: '#94a3b8', margin: '6px 0 0 0' }}>12:25 PM</p>
            </div>
          </div>
        </div>

        {/* ── NEW EVENT: Typing Message Sent (cf=115) ── */}
        <div style={{ display: 'flex', justifyContent: 'flex-end', opacity: op(messageSent, 6), transform: `translateY(${ty(messageSent, 6)}px)` }}>
          <div style={{ background: 'linear-gradient(135deg, #83C5BE, #006D77)', borderRadius: '16px 4px 16px 16px', padding: '8px 12px', boxShadow: '0 2px 6px rgba(0,109,119,0.15)', maxWidth: '80%' }}>
            <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 15, color: 'white', margin: 0, lineHeight: 1.4 }}>Let's start an outing session.</p>
            <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 11, color: 'rgba(255,255,255,0.75)', margin: '4px 0 0 0', textAlign: 'right' }}>12:27 PM <span style={{color: '#83C5BE', letterSpacing: '-0.25em', paddingRight: 4}}>✔✔</span></p>
          </div>
        </div>

       </div>

      {/* Input bar - High Fidelity Floating Pill */}
      <div style={{ padding: '8px 16px 24px', backgroundColor: 'transparent', flexShrink: 0 }}>
        <div style={{ display: 'flex', alignItems: 'center', backgroundColor: 'white', borderRadius: 30, padding: '6px 6px 6px 12px', boxShadow: '0 4px 16px rgba(0,0,0,0.06)' }}>
          {/* Plus button */}
          <div style={{ width: 32, height: 32, borderRadius: 16, backgroundColor: '#e0f2f1', display: 'flex', justifyContent: 'center', alignItems: 'center', flexShrink: 0 }}>
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#006D77" strokeWidth="2.5" strokeLinecap="round"><line x1="12" y1="5" x2="12" y2="19" /><line x1="5" y1="12" x2="19" y2="12" /></svg>
          </div>
          
          {/* Text Input Area */}
          <div style={{ flex: 1, paddingLeft: 12, display: 'flex', alignItems: 'center', position: 'relative' }}>
            {!isTyping && !showNewMessage && (
              <span style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 15, color: '#94a3b8' }}>Type a message...</span>
            )}
            {(isTyping || (!showNewMessage && hasText)) && (
              <span style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 15, color: '#1e293b' }}>
                {currentText}
                <span style={{ opacity: cf % 30 < 15 ? 1 : 0, marginLeft: 1, color: '#006D77' }}>|</span>
              </span>
            )}
          </div>
          
          {/* Action Button (Mic or Send) */}
          <div style={{ 
            width: 36, height: 36, borderRadius: 18, backgroundColor: '#006D77', 
            display: 'flex', justifyContent: 'center', alignItems: 'center', flexShrink: 0, 
            boxShadow: '0 2px 8px rgba(0,109,119,0.25)',
            transform: `scale(${sendScale})`,
          }}>
            {hasText ? (
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" style={{ transform: 'translateX(-1px)' }}>
                <line x1="22" y1="2" x2="11" y2="13" /><polygon points="22 2 15 22 11 13 2 9 22 2" />
              </svg>
            ) : (
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                <path d="M12 1a3 3 0 0 0-3 3v8a3 3 0 0 0 6 0V4a3 3 0 0 0-3-3z" /><path d="M19 10v2a7 7 0 0 1-14 0v-2" /><line x1="12" y1="19" x2="12" y2="23" /><line x1="8" y1="23" x2="16" y2="23" />
              </svg>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

/* ════════════════════════════════════════════════════════════════
 * LARGE PREMIUM CALLOUT
 * Much bigger than HeroCallout — 360px min, 76px icon, 23px label.
 * Anchors to LEFT or RIGHT edge of frame, partially covers phone.
 * ════════════════════════════════════════════════════════════════ */
interface CalloutProps {
  icon: React.ReactNode;
  label: string;
  tag: string;
  accentColor: string;
  iconBg: string;
  glow: string;
  borderColor: string;
  frame: number;
  appear: number;   // bubble starts entering at this frame
  dismiss: number;  // bubble starts exiting at this frame (AFTER its chat event)
  fromLeft: boolean;
  topPct: string;
}

const LargeCallout: React.FC<CalloutProps> = ({
  icon, label, tag, accentColor, iconBg, glow, borderColor,
  frame, appear, dismiss, fromLeft, topPct,
}) => {
  if (frame < appear - 2) return null;

  const inT  = clamp(ec((frame - appear) / 14));
  const outT = dismiss > 0 ? clamp(ec((frame - dismiss) / 14)) : 0;
  const opacity = inT * (1 - outT);
  if (opacity < 0.01) return null;

  // Slide in from the anchor side, slide out the same way
  const slideX = fromLeft
    ? (1 - inT) * -280 + outT * -140
    : (1 - inT) * 280 + outT * 140;
  const scale  = 0.86 + inT * 0.14 - outT * 0.04;
  const floatY = Math.sin(frame * 0.04 + appear) * 5;

  return (
    <div style={{
      position: 'absolute',
      top: topPct,
      ...(fromLeft ? { left: '8%' } : { right: '8%' }),
      transform: `translateX(${slideX}px) translateY(${floatY}px) scale(${scale})`,
      transformOrigin: fromLeft ? 'left center' : 'right center',
      opacity,
      zIndex: 40,
      pointerEvents: 'none',
    }}>
      {/* Glow halo — large and diffuse */}
      <div style={{
        position: 'absolute', inset: -40, borderRadius: 60,
        background: glow, filter: 'blur(44px)',
        opacity: 0.82 * inT * (1 - outT),
      }} />

      {/* Card */}
      <div style={{
        position: 'relative',
        background: 'rgba(5,9,20,0.94)',
        border: `1.5px solid ${borderColor}`,
        borderRadius: 28,
        padding: '24px 40px 24px 24px',
        display: 'flex', alignItems: 'center', gap: 22,
        backdropFilter: 'blur(32px)',
        boxShadow: '0 28px 80px rgba(0,0,0,0.65), 0 0 0 1px rgba(255,255,255,0.04)',
        minWidth: 360, maxWidth: 440,
      }}>
        {/* Icon */}
        <div style={{
          width: 76, height: 76, borderRadius: 22, background: iconBg,
          display: 'flex', justifyContent: 'center', alignItems: 'center', flexShrink: 0,
          boxShadow: `0 6px 24px ${accentColor}28`,
        }}>
          {icon}
        </div>

        {/* Text */}
        <div style={{ flex: 1 }}>
          {/* Tag */}
          <div style={{ display: 'flex', alignItems: 'center', gap: 7, marginBottom: 9 }}>
            <div style={{ width: 7, height: 7, borderRadius: '50%', background: accentColor }} />
            <span style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 11, fontWeight: 700, color: accentColor, letterSpacing: '0.1em', textTransform: 'uppercase' }}>{tag}</span>
          </div>
          {/* Label */}
          <p style={{
            fontFamily: 'Inter,system-ui,sans-serif', fontSize: 23, fontWeight: 800,
            color: 'white', margin: 0, lineHeight: 1.15, letterSpacing: '-0.02em',
          }}>{label}</p>
        </div>
      </div>
    </div>
  );
};

/* ════════════════════════════════════════════════════════════════
 * MAIN SCENE 2 — 145 frames
 * cf = frame (no offset); phone stays visible throughout
 * ════════════════════════════════════════════════════════════════ */
export const Scene2Ecosystem: React.FC = () => {
  const { fps } = useVideoConfig();
  const frame = useCurrentFrame();

  // cf = frame directly; chat events fire at frame 30, 66, 100
  const cf = frame;

  // Phone entry
  const phoneSpring = spring({ frame: frame - 3, fps, config: { damping: 14, stiffness: 120 } });
  const phoneY  = interpolate(phoneSpring, [0, 1], [280, 0]);
  const phoneOp = clamp(interpolate(frame, [3, 16], [0, 1]));

  // Title entry
  const titleSpring = spring({ frame: frame - 4, fps, config: { damping: 14 } });
  const titleOp  = clamp(interpolate(frame, [4, 18], [0, 1]));
  const titleY   = interpolate(titleSpring, [0, 1], [24, 0]);

  // Exit — dissolve over last 12 frames so it flows into Scene5
  const exitOp = clamp(interpolate(frame, [208, 220], [1, 0]));

  return (
    <AbsoluteFill style={{ backgroundColor: '#050714', overflow: 'hidden', opacity: exitOp }}>
      {/* Ambient teal glow */}
      <div style={{ position: 'absolute', inset: 0, background: 'radial-gradient(ellipse at 50% 58%,rgba(13,121,117,0.055) 0%,transparent 55%)' }} />

      {/* ═══ HEADLINE ═══ */}
      <div style={{
        position: 'absolute', top: '5%', width: '100%', textAlign: 'center',
        padding: '0 48px',
        opacity: titleOp,
        transform: `translateY(${titleY}px)`,
        zIndex: 20,
      }}>
        <h1 style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 64, fontWeight: 900, color: 'white', margin: 0, lineHeight: 1.15, letterSpacing: '-0.02em' }}>
          Everything your meetup needs
        </h1>
        <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 30, color: '#5eead4', fontWeight: 600, margin: '14px 0 0', letterSpacing: '-0.01em' }}>
          in one app.
        </p>
      </div>

      {/* ═══ PHONE — stays visible the entire scene ═══ */}
      <div style={{
        position: 'absolute', top: '50%', left: '50%',
        transform: `translate(-50%,-50%) translateY(${frame >= 40 ? 45 : phoneY + 80}px)`,
        opacity: frame >= 20 ? 1 : phoneOp,
      }}>
        <PhoneMockup scale={0.95} drift={false}>
          {/* Group chat — same chat context throughout, no phase switch */}
          <GroupChat cf={cf} />
        </PhoneMockup>
      </div>

      {/* ═══ CALLOUT 1: Photo shared ═══
       * appear: f15 | chat photo fires: cf=30 | dismiss: f46 (photo visible for 16f before bubble leaves)
       */}
      <LargeCallout
        icon={
          <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="#c084fc" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
            <rect x="3" y="3" width="18" height="18" rx="2" ry="2" /><circle cx="8.5" cy="8.5" r="1.5" /><polyline points="21 15 16 10 5 21" />
          </svg>
        }
        label="Share a photo"
        tag="Media"
        accentColor="#c084fc"
        iconBg="rgba(192,132,252,0.15)"
        glow="rgba(167,139,250,0.42)"
        borderColor="rgba(192,132,252,0.3)"
        frame={frame}
        appear={15}
        dismiss={46}
        fromLeft={true}
        topPct="28%"
      />

      {/* ═══ CALLOUT 2: Location sent ═══
       * appear: f52 | location card fires: cf=66 | dismiss: f82 (card visible for 16f before bubble leaves)
       * CRITICAL: phone mockup stays visible — bubble dismisses ONLY after location is in chat
       */}
      <LargeCallout
        icon={
          <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="#14b8a6" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
            <path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7z" /><circle cx="12" cy="9" r="2.5" />
          </svg>
        }
        label="Send your location"
        tag="Live sharing"
        accentColor="#2dd4bf"
        iconBg="rgba(20,184,166,0.15)"
        glow="rgba(20,184,166,0.42)"
        borderColor="rgba(45,212,191,0.3)"
        frame={frame}
        appear={52}
        dismiss={82}
        fromLeft={false}
        topPct="22%"
      />

      {/* ═══ CALLOUT 3: Outing session started ═══
       * appear: f130 | dismiss: f180
       * Amber/planning colour — slides in from left, overlaps phone at mid-level
       */}
      <LargeCallout
        icon={
          <svg width="36" height="36" viewBox="0 0 24 24" fill="#f59e0b">
            <line x1="12" y1="5" x2="12" y2="19" stroke="#f59e0b" strokeWidth="3" strokeLinecap="round" />
            <line x1="5" y1="12" x2="19" y2="12" stroke="#f59e0b" strokeWidth="3" strokeLinecap="round" />
          </svg>
        }
        label="Tap + to plan together"
        tag="Planning"
        accentColor="#f59e0b"
        iconBg="rgba(245,158,11,0.18)"
        glow="rgba(245,158,11,0.38)"
        borderColor="rgba(245,158,11,0.3)"
        frame={frame}
        appear={130}
        dismiss={180}
        fromLeft={true}
        topPct="48%"
      />

    </AbsoluteFill>
  );
};
