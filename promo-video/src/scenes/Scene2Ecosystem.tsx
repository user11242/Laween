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
  const ty = (s: number, d = 8) =>
    interpolate(cf, [s, s + d], [14, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  return (
    <div style={{ position: 'absolute', inset: 0, backgroundColor: '#f6f7f9', display: 'flex', flexDirection: 'column' }}>
      {/* Header */}
      <div style={{ backgroundColor: 'white', padding: '46px 16px 14px', display: 'flex', alignItems: 'center', gap: 12, boxShadow: '0 1px 4px rgba(0,0,0,0.04)', zIndex: 10, flexShrink: 0 }}>
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#1e293b" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" style={{ flexShrink: 0 }}><path d="M15 18l-6-6 6-6" /></svg>
        <div style={{ width: 42, height: 42, borderRadius: 21, background: '#f59e0b', display: 'flex', justifyContent: 'center', alignItems: 'center', flexShrink: 0 }}>
          <span style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 18, fontWeight: 800, color: 'white' }}>W</span>
        </div>
        <div style={{ flex: 1 }}>
          <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 17, fontWeight: 700, color: '#1e293b', margin: 0 }}>Weekend Plans 🎉</p>
          <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 13, color: '#94a3b8', margin: '1px 0 0' }}>4 members</p>
        </div>
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#0d7975" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
          <circle cx="18" cy="5" r="3" /><circle cx="6" cy="12" r="3" /><circle cx="18" cy="19" r="3" />
          <line x1="8.59" y1="13.51" x2="15.42" y2="17.49" /><line x1="15.41" y1="6.51" x2="8.59" y2="10.49" />
        </svg>
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#0d7975" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" style={{ marginLeft: 4 }}>
          <circle cx="12" cy="12" r="10" /><line x1="12" y1="16" x2="12" y2="12" /><line x1="12" y1="8" x2="12.01" y2="8" />
        </svg>
      </div>

      {/* Messages */}
      <div style={{ flex: 1, padding: '12px 14px 8px', display: 'flex', flexDirection: 'column', gap: 10, overflow: 'hidden' }}>

        {/* Ahmed base */}
        <div style={{ display: 'flex', alignItems: 'flex-end', gap: 8, opacity: op(0), transform: `translateY(${ty(0)}px)` }}>
          <div style={{ width: 28, height: 28, borderRadius: 14, background: '#f59e0b', display: 'flex', justifyContent: 'center', alignItems: 'center', flexShrink: 0 }}>
            <span style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 12, fontWeight: 800, color: 'white' }}>A</span>
          </div>
          <div>
            <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 11, color: '#94a3b8', margin: '0 0 3px 4px', fontWeight: 500 }}>Ahmed</p>
            <div style={{ background: 'white', borderRadius: '16px 16px 16px 4px', padding: '9px 13px', boxShadow: '0 2px 8px rgba(0,0,0,0.06)' }}>
              <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 15, color: '#1e293b', margin: 0, lineHeight: 1.4 }}>Let's plan for tonight! 🎉</p>
            </div>
          </div>
        </div>

        {/* User reply */}
        <div style={{ display: 'flex', justifyContent: 'flex-end', opacity: op(5), transform: `translateY(${ty(5)}px)` }}>
          <div style={{ background: '#0d7975', borderRadius: '16px 16px 4px 16px', padding: '9px 13px', boxShadow: '0 2px 8px rgba(13,121,117,0.2)', maxWidth: 210 }}>
            <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 15, color: 'white', margin: 0, lineHeight: 1.4 }}>I'm down! Where should we meet? 🙌</p>
          </div>
        </div>

        {/* Sarah */}
        <div style={{ display: 'flex', alignItems: 'flex-end', gap: 8, opacity: op(10), transform: `translateY(${ty(10)}px)` }}>
          <div style={{ width: 28, height: 28, borderRadius: 14, background: '#a78bfa', display: 'flex', justifyContent: 'center', alignItems: 'center', flexShrink: 0 }}>
            <span style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 12, fontWeight: 800, color: 'white' }}>S</span>
          </div>
          <div>
            <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 11, color: '#94a3b8', margin: '0 0 3px 4px', fontWeight: 500 }}>Sarah</p>
            <div style={{ background: 'white', borderRadius: '16px 16px 16px 4px', padding: '9px 13px', boxShadow: '0 2px 8px rgba(0,0,0,0.06)' }}>
              <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 15, color: '#1e293b', margin: 0, lineHeight: 1.4 }}>Restaurant or a cafe? 🍕</p>
            </div>
          </div>
        </div>

        {/* ── CHAT EVENT 1: Photo (cf=30) ── */}
        <div style={{ display: 'flex', alignItems: 'flex-end', gap: 8, opacity: op(30, 10), transform: `translateY(${ty(30, 10)}px)` }}>
          <div style={{ width: 28, height: 28, borderRadius: 14, background: '#f59e0b', display: 'flex', justifyContent: 'center', alignItems: 'center', flexShrink: 0 }}>
            <span style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 12, fontWeight: 800, color: 'white' }}>A</span>
          </div>
          <div>
            <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 11, color: '#94a3b8', margin: '0 0 3px 4px', fontWeight: 500 }}>Ahmed</p>
            <div style={{ borderRadius: '16px 16px 16px 4px', overflow: 'hidden', boxShadow: '0 3px 12px rgba(0,0,0,0.12)', width: 186 }}>
              <img src={staticFile('shared_image.jpg')} style={{ width: '100%', height: 124, objectFit: 'cover', display: 'block' }} alt="" />
              <div style={{ background: 'white', padding: '6px 10px 8px' }}>
                <span style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 12, color: '#64748b' }}>What about this place? ☕</span>
              </div>
            </div>
          </div>
        </div>

        {/* ── CHAT EVENT 2: Location card (cf=66) ── */}
        <div style={{ display: 'flex', justifyContent: 'flex-end', opacity: op(66, 10), transform: `translateY(${ty(66, 10)}px)` }}>
          <div style={{ background: '#0d7975', borderRadius: 14, overflow: 'hidden', boxShadow: '0 4px 14px rgba(13,121,117,0.25)', width: 188 }}>
            <div style={{ height: 76, background: 'linear-gradient(135deg,#0a5c5a,#0d7975,#14b8a6)', display: 'flex', justifyContent: 'center', alignItems: 'center', position: 'relative' }}>
              <div style={{ position: 'absolute', inset: 0, opacity: 0.12 }}>
                {[25, 50, 75].map(p => <div key={p} style={{ position: 'absolute', top: `${p}%`, left: 0, right: 0, height: 1, background: 'white' }} />)}
                {[33, 66].map(p => <div key={p} style={{ position: 'absolute', left: `${p}%`, top: 0, bottom: 0, width: 1, background: 'white' }} />)}
              </div>
              <div style={{ width: 30, height: 30, borderRadius: 15, background: 'white', display: 'flex', justifyContent: 'center', alignItems: 'center', boxShadow: '0 3px 10px rgba(0,0,0,0.2)', zIndex: 1 }}>
                <svg width="15" height="15" viewBox="0 0 24 24" fill="#0d7975"><path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7z" /></svg>
              </div>
            </div>
            <div style={{ padding: '9px 12px 11px' }}>
              <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 13, fontWeight: 700, color: 'white', margin: '0 0 2px' }}>📍 Current Location Sent</p>
              <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 11, color: 'rgba(255,255,255,0.6)', margin: 0 }}>4 friends · Tap to open</p>
            </div>
          </div>
        </div>

       </div>

      {/* Input bar */}
      <div style={{ padding: '10px 14px 28px', backgroundColor: 'white', display: 'flex', alignItems: 'center', gap: 10, boxShadow: '0 -1px 8px rgba(0,0,0,0.04)', flexShrink: 0 }}>
        <div style={{ width: 38, height: 38, borderRadius: 19, backgroundColor: '#f1f5f9', display: 'flex', justifyContent: 'center', alignItems: 'center', flexShrink: 0 }}>
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#64748b" strokeWidth="2.5" strokeLinecap="round"><line x1="12" y1="5" x2="12" y2="19" /><line x1="5" y1="12" x2="19" y2="12" /></svg>
        </div>
        <div style={{ flex: 1, height: 38, borderRadius: 19, border: '1.5px solid #e2e8f0', display: 'flex', alignItems: 'center', paddingLeft: 14, background: '#fafafa' }}>
          <span style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 14, color: '#94a3b8' }}>Type a message...</span>
        </div>
        <div style={{ width: 38, height: 38, borderRadius: 19, backgroundColor: '#0d7975', display: 'flex', justifyContent: 'center', alignItems: 'center', flexShrink: 0, boxShadow: '0 4px 10px rgba(13,121,117,0.3)' }}>
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" style={{ transform: 'rotate(45deg)', marginLeft: -2 }}>
            <line x1="22" y1="2" x2="11" y2="13" /><polygon points="22 2 15 22 11 13 2 9 22 2" />
          </svg>
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
  const exitOp = clamp(interpolate(frame, [168, 180], [1, 0]));

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
       * appear: f88 | dismiss: f118
       * Amber/planning colour — slides in from left, overlaps phone at mid-level
       */}
      <LargeCallout
        icon={
          <svg width="36" height="36" viewBox="0 0 24 24" fill="#f59e0b">
            <path d="M13 2L3 14h9l-1 8 10-12h-9l1-8z" />
          </svg>
        }
        label="Start an outing session"
        tag="Planning"
        accentColor="#f59e0b"
        iconBg="rgba(245,158,11,0.18)"
        glow="rgba(245,158,11,0.38)"
        borderColor="rgba(245,158,11,0.3)"
        frame={frame}
        appear={88}
        dismiss={118}
        fromLeft={true}
        topPct="48%"
      />

    </AbsoluteFill>
  );
};
