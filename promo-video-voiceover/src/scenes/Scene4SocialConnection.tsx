import { AbsoluteFill, useCurrentFrame, useVideoConfig, spring, interpolate } from 'remotion';
import React from 'react';
import { PhoneMockup } from '../components/PhoneMockup';

/*
 * SCENE 4 — JOIN GROUP: Full 7-step sequence (210 frames / 7s)
 *
 * Timing (30fps):
 *  f  0-18   : Groups screen
 *  f 18-26   : FAB press-in → bounce → glow
 *  f 28-88   : WHITE MODAL inside phone (held for ~2s)
 *  f 90-108  : Phone fades, white cards appear at same position on dark stage
 *  f 108-120 : White cards CROSSFADE → dark-style cards (same geometry, dark fill)
 *  f 120-124 : Dark cards fully visible — Create highlighted
 *  f 124     : Toggle focus → Join highlighted
 *  f 140-148 : Join card tap
 *  f 148-210 : Join-group flow inside phone
 */

const ec    = (t: number) => 1 - Math.pow(1 - Math.max(0, Math.min(1, t)), 3);
const clamp = (v: number, lo = 0, hi = 1) => Math.max(lo, Math.min(hi, v));

/* ════════════════════════════════════════════════════════════════
 * SHARED MODAL ROW — exact Laween white card, used in BOTH phases
 * ════════════════════════════════════════════════════════════════ */
interface ModalRowProps {
  icon: React.ReactNode;
  iconBg: string;
  title: string;
  subtitle: string;
  active?: boolean;   // teal glow border applied during isolated spotlight
  dimmed?: boolean;   // lower opacity for the non-selected card
  tapScale?: number;
}
const ModalRow: React.FC<ModalRowProps> = ({
  icon, iconBg, title, subtitle,
  active = false, dimmed = false, tapScale = 1,
}) => (
  <div style={{
    background: 'white',
    borderRadius: 20,
    padding: '18px',
    display: 'flex', alignItems: 'center', gap: 16,
    boxShadow: active
      ? '0 0 0 2px rgba(0,109,119,0.55), 0 8px 32px rgba(0,109,119,0.18)'
      : '0 4px 16px rgba(0,0,0,0.05)',
    border: active ? '1.5px solid rgba(0,109,119,0.55)' : '1px solid #f1f5f9',
    opacity: dimmed ? 0.44 : 1,
    transform: `scale(${tapScale})`,
    transformOrigin: 'center',
    // CSS transition drives the smooth active/dimmed state change
    transition: 'opacity 0.35s ease, box-shadow 0.35s ease, border-color 0.35s ease',
  }}>
    {/* Icon circle */}
    <div style={{
      width: 52, height: 52, borderRadius: 26, background: iconBg,
      display: 'flex', justifyContent: 'center', alignItems: 'center', flexShrink: 0,
    }}>
      {icon}
    </div>

    {/* Text */}
    <div style={{ flex: 1 }}>
      <p style={{ fontFamily: 'Outfit,system-ui,sans-serif', fontSize: 17, fontWeight: 700, color: '#2D3748', margin: 0 }}>
        {title}
      </p>
      <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 13, color: '#94a3b8', margin: '4px 0 0' }}>
        {subtitle}
      </p>
    </div>

    {/* Chevron */}
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none"
      stroke={active ? '#006D77' : '#cbd5e1'} strokeWidth="2.5" strokeLinecap="round">
      <path d="M9 18l6-6-6-6"/>
    </svg>
  </div>
);

/* Icon definitions — reused in both phases */
const CreateIcon = () => (
  <svg width="22" height="22" viewBox="0 0 24 24" fill="none"
    stroke="#fb8c00" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
    <rect x="3" y="3" width="18" height="18" rx="4" ry="4"/>
    <line x1="12" y1="8" x2="12" y2="16"/>
    <line x1="8" y1="12" x2="16" y2="12"/>
  </svg>
);
const JoinIcon = () => (
  <svg width="22" height="22" viewBox="0 0 24 24" fill="none"
    stroke="#006D77" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
    <path d="M4 7V4h3"/><path d="M4 17v3h3"/>
    <path d="M20 7V4h-3"/><path d="M20 17v3h-3"/>
    <rect x="8" y="8" width="2" height="2"/>
    <rect x="14" y="8" width="2" height="2"/>
    <rect x="11" y="14" width="2" height="2"/>
  </svg>
);

/* ════════════════════════════════════════════════════════════════
 * GROUPS PAGE (inside phone) — locked UI
 * ════════════════════════════════════════════════════════════════ */
const GroupsPage: React.FC = () => (
  <div style={{ position: 'absolute', inset: 0, backgroundColor: '#f6f7f9', overflow: 'hidden', display: 'flex', flexDirection: 'column' }}>
    {/* Header */}
    <div style={{ background: 'linear-gradient(145deg,#83C5BE 0%,#006D77 100%)', height: 178, position: 'relative', overflow: 'hidden', flexShrink: 0 }}>
      <div style={{ position: 'absolute', top: -50, right: -60, width: 270, height: 270, borderRadius: '50%', background: 'rgba(255,255,255,0.07)' }} />
      <div style={{ position: 'absolute', top: 18, left: 26, right: 22, display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontFamily: 'Inter,system-ui,sans-serif', fontSize: 15, fontWeight: 600, color: 'white' }}>
        <span>4:28</span>
        <div style={{ display: 'flex', gap: 5, alignItems: 'center' }}>
          <svg width="16" height="11" viewBox="0 0 18 12" fill="white"><rect x="1" y="8" width="3" height="4" rx="1"/><rect x="6" y="5" width="3" height="7" rx="1"/><rect x="11" y="2" width="3" height="10" rx="1"/><rect x="16" y="0" width="3" height="12" rx="1" opacity="0.3"/></svg>
          <svg width="13" height="10" viewBox="0 0 16 12" fill="white"><path d="M8 12L0 3.2C2.2.8 5 0 8 0s5.8.8 8 3.2L8 12z"/></svg>
          <div style={{ width: 22, height: 11, borderRadius: 3, border: '1.5px solid rgba(255,255,255,0.5)', paddingLeft: 1, display: 'flex', alignItems: 'center' }}>
            <div style={{ background: '#facc15', width: 11, height: 7, borderRadius: 1 }}/>
          </div>
        </div>
      </div>
      <h2 style={{ position: 'absolute', left: 22, bottom: 22, fontFamily: 'Outfit,system-ui,sans-serif', fontSize: 38, fontWeight: 800, color: 'white', margin: 0 }}>Groups</h2>
    </div>
    {/* Search */}
    <div style={{ padding: '20px 18px 16px', background: '#f6f7f9' }}>
      <div style={{ background: 'white', borderRadius: 18, padding: '13px 18px', display: 'flex', alignItems: 'center', gap: 12, boxShadow: '0 2px 12px rgba(0,0,0,0.04)' }}>
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#006D77" strokeWidth="2.5" strokeLinecap="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
        <span style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 16, color: '#b0b8c1' }}>search...</span>
      </div>
    </div>
    {/* Rows */}
    <div style={{ background: 'white', flex: 1 }}>
      {[
        { name: 'Weekend Plans', sub: "Ahmed: Let's plan for tonight! 🎉", time: '04:18 PM', badge: 3, color: '#f59e0b' },
        { name: 'The girls',     sub: 'Start chatting...',                  time: '',         badge: 0, color: '#e8f3f2', isIcon: true },
        { name: 'UNI',           sub: '🔥 Outing Session: Cafe',            time: '01/04/26', badge: 0, color: '#65a30d' },
      ].map((g, i) => (
        <div key={i} style={{ padding: '14px 18px', display: 'flex', alignItems: 'center', gap: 16, borderBottom: '1px solid #f1f3f5' }}>
          <div style={{ width: 54, height: 54, borderRadius: 27, background: g.isIcon ? '#e8f3f2' : g.color, display: 'flex', justifyContent: 'center', alignItems: 'center', flexShrink: 0 }}>
            {g.isIcon && <svg width="26" height="26" viewBox="0 0 24 24" fill="#006D77"><path d="M16 11c1.66 0 2.99-1.34 2.99-3S17.66 5 16 5c-1.66 0-3 1.34-3 3s1.34 3 3 3zm-8 0c1.66 0 2.99-1.34 2.99-3S9.66 5 8 5C6.34 5 5 6.34 5 8s1.34 3 3 3zm0 2c-2.33 0-7 1.17-7 3.5V19h14v-2.5c0-2.33-4.67-3.5-7-3.5z"/></svg>}
          </div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 3 }}>
              <span style={{ fontFamily: 'Outfit,system-ui,sans-serif', fontSize: 17, fontWeight: 700, color: '#2D3748' }}>{g.name}</span>
              {g.time && <span style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 12, color: i === 0 ? '#006D77' : '#94a3b8', fontWeight: 600 }}>{g.time}</span>}
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 14, color: '#64748b', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', maxWidth: '78%' }}>{g.sub}</span>
              {g.badge > 0 && <div style={{ minWidth: 22, height: 22, borderRadius: 11, background: '#006D77', display: 'flex', justifyContent: 'center', alignItems: 'center', padding: '0 5px' }}><span style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 11, fontWeight: 700, color: 'white' }}>{g.badge}</span></div>}
            </div>
          </div>
        </div>
      ))}
    </div>
    {/* Bottom nav */}
    <div style={{ position: 'absolute', bottom: 0, left: 0, right: 0, height: 78, background: 'white', display: 'flex', justifyContent: 'space-around', alignItems: 'center', paddingBottom: 16, borderTop: '1px solid rgba(0,0,0,0.05)' }}>
      {(['Home','Groups','Favorite','Profile'] as const).map((lbl, i) => (
        <div key={i} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 3 }}>
          {i===0 && <svg width="24" height="24" viewBox="0 0 24 24" fill="#cbd5e1"><path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z"/></svg>}
          {i===1 && <svg width="24" height="24" viewBox="0 0 24 24" fill="#006D77"><path d="M16 11c1.66 0 2.99-1.34 2.99-3S17.66 5 16 5c-1.66 0-3 1.34-3 3s1.34 3 3 3zm-8 0c1.66 0 2.99-1.34 2.99-3S9.66 5 8 5C6.34 5 5 6.34 5 8s1.34 3 3 3zm0 2c-2.33 0-7 1.17-7 3.5V19h14v-2.5c0-2.33-4.67-3.5-7-3.5z"/></svg>}
          {i===2 && <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#cbd5e1" strokeWidth="2" strokeLinejoin="round" strokeLinecap="round"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg>}
          {i===3 && <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#cbd5e1" strokeWidth="2" strokeLinejoin="round" strokeLinecap="round"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>}
          <span style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 12, fontWeight: i===1?600:400, color: i===1?'#006D77':'#94a3b8' }}>{lbl}</span>
        </div>
      ))}
    </div>
  </div>
);

/* ════════════════════════════════════════════════════════════════
 * SINGLE PERSISTENT FAB
 * Transitions from Green (+) to Grey (x) when the modal opens
 * ════════════════════════════════════════════════════════════════ */
const AnimatedFAB: React.FC<{ frame: number, fabScale: number, fabGlow: number, modalEnter: number }> = ({ frame, fabScale, fabGlow, modalEnter }) => {
  // Modal entry takes ~7 frames
  const modalProgress = clamp(interpolate(frame, [modalEnter, modalEnter + 7], [0, 1]));

  const bgGreen = [0, 109, 119];
  const bgGrey = [46, 58, 75];
  const r = Math.round(interpolate(modalProgress, [0, 1], [bgGreen[0], bgGrey[0]]));
  const g = Math.round(interpolate(modalProgress, [0, 1], [bgGreen[1], bgGrey[1]]));
  const b = Math.round(interpolate(modalProgress, [0, 1], [bgGreen[2], bgGrey[2]]));
  const bgColor = `rgb(${r},${g},${b})`;

  const plusRot = interpolate(modalProgress, [0, 1], [0, -90]);
  const plusOp = interpolate(modalProgress, [0, 1], [1, 0]);
  const xRot = interpolate(modalProgress, [0, 1], [90, 0]);
  const xOp = interpolate(modalProgress, [0, 1], [0, 1]);

  const shadowAlpha = interpolate(modalProgress, [0, 1], [0.4, 0.2]);
  const currentGlow = fabGlow * (1 - modalProgress);

  return (
    <div style={{
      position: 'absolute', bottom: 88, right: 20,
      width: 60, height: 60, borderRadius: 18, 
      backgroundColor: bgColor,
      display: 'flex', justifyContent: 'center', alignItems: 'center',
      transform: `scale(${fabScale})`,
      boxShadow: `0 6px 18px rgba(${r},${g},${b},${shadowAlpha}), 0 0 ${currentGlow*28}px ${currentGlow*12}px rgba(0,109,119,${(currentGlow*0.7).toFixed(2)})`,
      zIndex: 20,
    }}>
      <svg style={{ position: 'absolute', opacity: plusOp, transform: `rotate(${plusRot}deg)` }} width="26" height="26" viewBox="0 0 24 24" fill="white">
        <path d="M19 13h-6v6h-2v-6H5v-2h6V5h2v6h6v2z"/>
      </svg>
      <svg style={{ position: 'absolute', opacity: xOp, transform: `rotate(${xRot}deg)` }} width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5" strokeLinecap="round">
        <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
      </svg>
    </div>
  );
};


/* ════════════════════════════════════════════════════════════════
 * IN-PHONE MODAL — uses shared ModalRow
 * ════════════════════════════════════════════════════════════════ */
const InPhoneModal: React.FC<{ modalScale: number }> = ({ modalScale }) => (
  <div style={{ position: 'absolute', inset: 0, display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
    {/* dim backdrop */}
    <div style={{ position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.45)' }} />
    {/* card */}
    <div style={{
      backgroundColor: 'white', borderRadius: 28, width: '88%',
      padding: '26px 22px 28px', display: 'flex', flexDirection: 'column', gap: 18,
      transform: `scale(${modalScale})`, boxShadow: '0 16px 44px rgba(0,0,0,0.16)',
      zIndex: 10, position: 'relative',
    }}>
      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 4 }}>
        <span style={{ fontFamily: 'Outfit,system-ui,sans-serif', fontSize: 22, fontWeight: 800, color: '#2D3748' }}>Groups</span>
        <div style={{ width: 30, height: 30, borderRadius: 15, backgroundColor: '#f1f5f9', display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#64748b" strokeWidth="2.5" strokeLinecap="round">
            <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
          </svg>
        </div>
      </div>
      {/* Create Group — using shared ModalRow */}
      <ModalRow
        icon={<CreateIcon />}
        iconBg="#fff3ec"
        title="Create Group"
        subtitle="Make a new group for your crew"
      />
      {/* Join Group — using shared ModalRow */}
      <ModalRow
        icon={<JoinIcon />}
        iconBg="#ebf7f6"
        title="Join Group"
        subtitle="Enter a code to join an existing group"
      />
    </div>
  </div>
);

/* ════════════════════════════════════════════════════════════════
 * DARK MODAL ROW — identical geometry to ModalRow, dark card fill
 * padding / radius / gap / icon-size are all the same numbers.
 * ════════════════════════════════════════════════════════════════ */
interface DarkRowProps {
  icon: React.ReactNode;
  iconBg: string;          // icon circle bg (kept warm so icon stays readable)
  title: string;
  subtitle: string;
  active?: boolean;         // teal fill + glow
  dimmed?: boolean;
  tapScale?: number;
}
const DarkModalRow: React.FC<DarkRowProps> = ({
  icon, iconBg, title, subtitle,
  active = false, dimmed = false, tapScale = 1,
}) => (
  <div style={{
    /* SAME geometry as ModalRow — only colors differ */
    borderRadius: 20,
    padding: '18px',
    display: 'flex', alignItems: 'center', gap: 16,
    /* Dark fill */
    background: active
      ? 'linear-gradient(135deg, rgba(0,109,119,0.25), rgba(131,197,190,0.12))'
      : 'rgba(255,255,255,0.04)',
    border: active
      ? '1.5px solid rgba(0,109,119,0.55)'
      : '1.5px solid rgba(255,255,255,0.08)',
    boxShadow: active
      ? '0 8px 32px rgba(0,109,119,0.22)'
      : 'none',
    opacity: dimmed ? 0.42 : 1,
    transform: `scale(${tapScale})`,
    transformOrigin: 'center',
    transition: 'opacity 0.35s ease, box-shadow 0.35s ease, border-color 0.35s ease, background 0.35s ease',
  }}>
    {/* Icon circle — same size 52×52 */}
    <div style={{
      width: 52, height: 52, borderRadius: 26,
      background: active ? iconBg : 'rgba(255,255,255,0.07)',
      display: 'flex', justifyContent: 'center', alignItems: 'center', flexShrink: 0,
      transition: 'background 0.3s ease',
    }}>
      {icon}
    </div>
    {/* Text */}
    <div style={{ flex: 1 }}>
      <p style={{
        fontFamily: 'Outfit,system-ui,sans-serif', fontSize: 17, fontWeight: 700,
        color: active ? 'white' : 'rgba(255,255,255,0.38)',
        margin: 0, transition: 'color 0.3s ease',
      }}>{title}</p>
      <p style={{
        fontFamily: 'Inter,system-ui,sans-serif', fontSize: 13,
        color: active ? 'rgba(255,255,255,0.58)' : 'rgba(255,255,255,0.22)',
        margin: '4px 0 0', transition: 'color 0.3s ease',
      }}>{subtitle}</p>
    </div>
    {/* Chevron */}
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none"
      stroke={active ? '#83C5BE' : 'rgba(255,255,255,0.18)'} strokeWidth="2.5" strokeLinecap="round">
      <path d="M9 18l6-6-6-6"/>
    </svg>
  </div>
);

/* ════════════════════════════════════════════════════════════════
 * SPOTLIGHT STAGE
 * Renders ONLY DarkModalRow — no white intermediate layer.
 * Width locked to 425px = phone modal card width (378 * 0.88 * 1.28).
 * Positioned to match phone center so it overlaps perfectly.
 * ════════════════════════════════════════════════════════════════ */
interface SpotlightProps {
  focusOnJoin: boolean;
  joinTap: number;
}
const SpotlightCards: React.FC<SpotlightProps> = ({ focusOnJoin, joinTap }) => (
  // Width = 378 (phone virtual px) × 0.88 (modal '88%') × 1.28 (phone scale) ≈ 425px
  // This matches the exact rendered width of the cards inside the phone modal.
  <div style={{ width: 425, display: 'flex', flexDirection: 'column' }}>
    <div style={{ marginBottom: 16 }}>
      <DarkModalRow
        icon={<CreateIcon />}
        iconBg="#fff3ec"
        title="Create Group"
        subtitle="Make a new group for your crew"
        active={!focusOnJoin}
        dimmed={focusOnJoin}
      />
    </div>
    <DarkModalRow
      icon={<JoinIcon />}
      iconBg="#ebf7f6"
      title="Join Group"
      subtitle="Enter a code to join an existing group"
      active={focusOnJoin}
      dimmed={!focusOnJoin}
      tapScale={1 - joinTap * 0.04}
    />
  </div>
);

/* ════════════════════════════════════════════════════════════════
 * JOIN-GROUP FLOW (inside phone) — existing faithful recreation
 * ════════════════════════════════════════════════════════════════ */
const JoinGroupFlow: React.FC<{ lf: number }> = ({ lf }) => {
  const codeStart  = 34;
  const digitStart = 44;
  const tabP = interpolate(lf, [codeStart, codeStart + 8], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const digits = ['4','8','2','7','1','9'];
  const digitFrames = digits.map((_, i) => digitStart + i * 5);
  const scanY = interpolate(lf % 30, [0, 15, 30], [20, 80, 20]);

  return (
    <div style={{ position: 'absolute', inset: 0, background: '#fdfdfd', display: 'flex', flexDirection: 'column' }}>
      {/* Teal curved header */}
      <div style={{ background: 'linear-gradient(160deg,#83C5BE 0%,#006D77 100%)', padding: '60px 24px 70px', position: 'relative', borderRadius: '0 0 45% 15%', boxShadow: '0 4px 10px rgba(0,109,119,0.2)', flexShrink: 0 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
          <div style={{ width: 44, height: 44, borderRadius: 22, background: 'rgba(255,255,255,0.2)', display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><path d="M15 18l-6-6 6-6"/></svg>
          </div>
          <h2 style={{ fontFamily: 'Outfit,system-ui,sans-serif', fontSize: 26, fontWeight: 700, color: 'white', margin: 0 }}>Join Group</h2>
        </div>
      </div>
      {/* Tab switcher */}
      <div style={{ padding: '0 24px', marginTop: -32, position: 'relative', zIndex: 10, flexShrink: 0 }}>
        <div style={{ background: 'white', borderRadius: 28, padding: 6, display: 'flex', position: 'relative', boxShadow: '0 8px 24px rgba(0,0,0,0.08)' }}>
          <div style={{ position: 'absolute', top: 6, bottom: 6, left: `calc(${tabP * 50}% + 6px)`, width: 'calc(50% - 12px)', background: 'linear-gradient(135deg,#83C5BE,#006D77)', borderRadius: 22, boxShadow: '0 4px 12px rgba(0,109,119,0.3)' }} />
          <div style={{ flex: 1, padding: '16px 0', textAlign: 'center', zIndex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10 }}>
            <svg width="20" height="20" viewBox="0 0 24 24" fill={tabP < 0.5 ? 'white' : '#cbd5e1'}><rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/><rect x="14" y="14" width="7" height="7" rx="1.5"/></svg>
            <span style={{ fontFamily: 'Outfit,system-ui,sans-serif', fontSize: 16, fontWeight: 700, color: tabP < 0.5 ? 'white' : '#94a3b8' }}>Scan QR</span>
          </div>
          <div style={{ flex: 1, padding: '16px 0', textAlign: 'center', zIndex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10 }}>
            <span style={{ fontFamily: 'Outfit,system-ui,sans-serif', fontSize: 16, fontWeight: 700, color: tabP > 0.5 ? 'white' : '#cbd5e1', letterSpacing: '0.05em' }}>***</span>
            <span style={{ fontFamily: 'Outfit,system-ui,sans-serif', fontSize: 16, fontWeight: 700, color: tabP > 0.5 ? 'white' : '#94a3b8' }}>Enter Code</span>
          </div>
        </div>
      </div>
      {/* QR content */}
      <div style={{ opacity: 1 - tabP, position: 'absolute', left: 0, right: 0, top: 210, display: 'flex', flexDirection: 'column', alignItems: 'center', padding: '24px' }}>
        <div style={{ width: '100%', aspectRatio: '1', borderRadius: 22, background: '#0a0a0e', position: 'relative', overflow: 'hidden', boxShadow: 'inset 0 2px 8px rgba(0,0,0,0.3)' }}>
          {[{top:18,left:18,borderTop:'3px solid #14b8a6',borderLeft:'3px solid #14b8a6',borderTopLeftRadius:10},{top:18,right:18,borderTop:'3px solid #14b8a6',borderRight:'3px solid #14b8a6',borderTopRightRadius:10},{bottom:18,left:18,borderBottom:'3px solid #14b8a6',borderLeft:'3px solid #14b8a6',borderBottomLeftRadius:10},{bottom:18,right:18,borderBottom:'3px solid #14b8a6',borderRight:'3px solid #14b8a6',borderBottomRightRadius:10}].map((c,i)=><div key={i} style={{position:'absolute',width:44,height:44,...c as any}}/>)}
          <div style={{ position: 'absolute', left: 22, right: 22, top: `${scanY}%`, height: 2, background: 'linear-gradient(90deg,transparent,rgba(20,184,166,0.6),transparent)' }} />
        </div>
        <h3 style={{ fontFamily: 'Outfit,system-ui,sans-serif', fontSize: 24, fontWeight: 800, color: '#2D3748', margin: '18px 0 6px' }}>Scan to Join</h3>
        <p style={{ fontFamily: 'Inter', fontSize: 15, color: '#94a3b8', textAlign: 'center', margin: 0 }}>Point your camera at the group's QR code to join instantly</p>
        <div style={{ marginTop: 18, border: '2.5px solid #006D77', borderRadius: 16, padding: '14px 0', width: '100%', textAlign: 'center', display: 'flex', justifyContent: 'center', alignItems: 'center', gap: 10 }}>
          <span style={{ fontFamily: 'Outfit,system-ui,sans-serif', fontSize: 18, fontWeight: 700, color: '#006D77' }}>Toggle Flashlight</span>
        </div>
      </div>
      {/* Code content */}
      <div style={{ opacity: tabP, position: 'absolute', left: 0, right: 0, top: 210, display: 'flex', flexDirection: 'column', alignItems: 'center', padding: '32px 24px' }}>
        <div style={{ width: 100, height: 100, borderRadius: 50, background: '#eef2f5', display: 'flex', justifyContent: 'center', alignItems: 'center', marginBottom: 20 }}>
          <svg width="46" height="46" viewBox="0 0 24 24" fill="none" stroke="#006D77" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
            <path d="M18 3a3 3 0 0 0-3 3v12a3 3 0 0 0 3 3 3 3 0 0 0 3-3 3 3 0 0 0-3-3H6a3 3 0 0 0-3 3 3 3 0 0 0 3 3 3 3 0 0 0 3-3V6a3 3 0 0 0-3-3 3 3 0 0 0-3 3 3 3 0 0 0 3 3h12a3 3 0 0 0 3-3 3 3 0 0 0-3-3z"/>
          </svg>
        </div>
        <h3 style={{ fontFamily: 'Outfit,system-ui,sans-serif', fontSize: 26, fontWeight: 800, color: '#2D3748', margin: '0 0 8px' }}>Enter Group Code</h3>
        <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 15, color: '#94a3b8', textAlign: 'center', margin: '0 0 32px' }}>Type the 6-digit code shared by the group settings</p>
        <div style={{ display: 'flex', gap: 8, marginBottom: 40 }}>
          {digits.map((d, i) => {
            const filled = lf >= digitFrames[i];
            return (
              <div key={i} style={{ width: 48, height: 60, borderRadius: 14, background: 'transparent', border: `1.5px solid ${filled ? '#006D77' : '#e2e8f0'}`, display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
                <span style={{ fontFamily: 'Outfit,system-ui,sans-serif', fontSize: 28, fontWeight: 700, color: filled ? '#2D3748' : 'transparent' }}>{d}</span>
              </div>
            );
          })}
        </div>
        <div style={{ background: 'linear-gradient(90deg,#83C5BE,#006D77)', borderRadius: 20, padding: '16px 0', width: '100%', textAlign: 'center', display: 'flex', justifyContent: 'center', alignItems: 'center', gap: 10, boxShadow: '0 6px 20px rgba(0,109,119,0.3)' }}>
          <span style={{ fontFamily: 'Outfit,system-ui,sans-serif', fontSize: 20, fontWeight: 700, color: 'white' }}>Join Group</span>
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5" strokeLinecap="round"><path d="M5 12h14M12 5l7 7-7 7"/></svg>
        </div>
      </div>
    </div>
  );
};

/* ════════════════════════════════════════════════════════════════
 * MAIN SCENE
 * ════════════════════════════════════════════════════════════════ */
export const Scene4SocialConnection: React.FC = () => {
  const { fps } = useVideoConfig();
  const frame = useCurrentFrame();

  /* ─── Phase constants ─── */
  const FAB_PRESS   = 18;   // FAB press starts
  const FAB_PEAK    = 22;
  const FAB_END     = 26;
  const MODAL_ENTER = 28;   // modal slides in
  const MODAL_FULL  = 38;   // spring settles
  const MODAL_HOLD  = 88;   // modal hold ends — KEPT LONG (50 frames = 1.67s)
  const ISO_ENTER   = 90;   // isolated spotlight starts fading in
  const ISO_FULL    = 108;  // spotlight fully visible
  const TOGGLE      = 124;  // Create → Join focus toggle
  const TAP_START   = 140;
  const TAP_PEAK    = 143;
  const JOIN_START  = 148;  // join-group flow starts
  const SCENE_END   = 210;

  /* ─── Global values ─── */
  const exitOp      = interpolate(frame, [SCENE_END - 8, SCENE_END], [1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const headlineOp  = interpolate(frame, [4, 14], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  // Headline fades as modal appears, comes back during phone phase
  const headlineFade = interpolate(frame, [MODAL_ENTER, MODAL_ENTER + 10], [1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  /* ─── Phone entry ─── */
  const phoneSpring = spring({ frame: frame - 3, fps, config: { damping: 14 } });
  const phoneY      = interpolate(phoneSpring, [0, 1], [300, 0]);

  /* ─── FAB animation ─── */
  const fabScale = frame < FAB_PRESS ? 1
    : frame < FAB_PEAK     ? interpolate(frame, [FAB_PRESS, FAB_PEAK], [1, 0.82])
    : frame < FAB_END + 5  ? interpolate(frame, [FAB_PEAK, FAB_END + 5], [0.82, 1.07])
    : frame < FAB_END + 10 ? interpolate(frame, [FAB_END + 5, FAB_END + 10], [1.07, 1.0])
    : 1.0;
  const fabGlow = clamp(interpolate(frame, [FAB_END - 2, FAB_END + 6, FAB_END + 16], [0, 1, 0]));

  /* ─── Modal spring + hold ─── */
  const modalSpring = spring({ frame: frame - MODAL_ENTER, fps, config: { damping: 12, stiffness: 180 } });
  const modalScale  = interpolate(modalSpring, [0, 1], [0.82, 1]);
  const modalOp     = clamp(interpolate(frame, [MODAL_ENTER, MODAL_ENTER + 7], [0, 1]));
  // Modal blends out SLOWLY as spotlight fades in — NOT a hard cut
  const modalFade   = clamp(interpolate(frame, [ISO_ENTER, ISO_FULL], [1, 0]));

  /* ─── Phone phase overall fade ─── */
  // Phone chrome fades out as spotlight takes over, but SLOWLY
  const phoneFade = clamp(interpolate(frame, [ISO_ENTER, ISO_FULL], [1, 0]));

  /* ─── Spotlight phase ─── */
  // Dark cards fade in directly — no white intermediate.
  const isoOp   = clamp(interpolate(frame, [ISO_ENTER, ISO_FULL], [0, 1]));
  const isoFade = clamp(interpolate(frame, [JOIN_START - 8, JOIN_START], [1, 0]));

  // Scale: enters small (matching phone modal size), then expands before toggle
  const EXPAND_START = 112; // start expanding a bit before TOGGLE (124)
  const expandSpring = spring({ frame: frame - EXPAND_START, fps, config: { damping: 18, stiffness: 140 } });
  const isoScale = frame < EXPAND_START
    ? 0.72  // matches the phone modal visual size during transition
    : interpolate(expandSpring, [0, 1], [0.72, 1.65]);  // springs up to highly readable size

  const focusOnJoin = frame >= TOGGLE;
  const joinTap     = clamp(interpolate(frame, [TAP_START, TAP_PEAK, TAP_PEAK + 5], [0, 1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' }));

  /* ─── Join flow ─── */
  const joinFlowOp     = clamp(interpolate(frame, [JOIN_START, JOIN_START + 8], [0, 1]));
  const joinPhoneSpring = spring({ frame: frame - JOIN_START + 2, fps, config: { damping: 14 } });
  const joinPhoneScale  = frame < JOIN_START ? 0 : interpolate(joinPhoneSpring, [0, 1], [0.88, 1]);
  const localJoinFrame  = Math.max(0, frame - JOIN_START);

  return (
    <AbsoluteFill style={{ backgroundColor: '#050714', overflow: 'hidden', opacity: exitOp }}>
      {/* Ambient glow */}
      <div style={{ position: 'absolute', inset: 0, background: 'radial-gradient(ellipse at 50% 50%,rgba(13,121,117,0.06) 0%,transparent 55%)' }} />

      {/* ═══ HEADLINE (before modal appears) ═══ */}
      <div style={{ position: 'absolute', top: '5%', width: '100%', textAlign: 'center', opacity: headlineOp * headlineFade, zIndex: 20 }}>
        <h1 style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 64, fontWeight: 900, color: 'white', margin: 0, letterSpacing: '-0.02em', lineHeight: 1.15 }}>
          Two ways in. Zero friction.
        </h1>
        <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 30, fontWeight: 600, color: '#5eead4', margin: '14px 0 0' }}>
          Create or join in seconds.
        </p>
      </div>

      {/* ═══════════════════════════════════════════════════
       * PHONE PHASE (Groups + Modal)
       * Stays visible until spotlight is fully in
       * ═══════════════════════════════════════════════════ */}
      {frame < JOIN_START && (
        <div style={{
          position: 'absolute', top: '50%', left: '50%',
          transform: `translate(-50%, -50%) translateY(${phoneY + 80}px)`,
          opacity: phoneFade,
        }}>
          <PhoneMockup scale={0.95} drift={frame < MODAL_ENTER}>
            {/* Groups page always behind */}
            <GroupsPage />

            {/* Modal — appears and fades SLOWLY as spotlight takes over */}
            {frame >= MODAL_ENTER && (
              <div style={{ position: 'absolute', inset: 0, opacity: modalOp * modalFade }}>
                <InPhoneModal modalScale={modalScale} />
              </div>
            )}

            {/* Persistent Animated FAB spanning both views */}
            <AnimatedFAB frame={frame} fabScale={fabScale} fabGlow={fabGlow} modalEnter={MODAL_ENTER} />
          </PhoneMockup>
        </div>
      )}

      {/* ═══════════════════════════════════════════════════
       * SPOTLIGHT PHASE
       * Dark cards at EXACT phone modal position + size.
       * No scale animation. Width=425px matches phone modal.
       * Position matches phone: translate(-50%,-50%) + Y=28px.
       * ═══════════════════════════════════════════════════ */}
      {frame >= ISO_ENTER && frame < JOIN_START && (
        <div style={{
          position: 'absolute',
          top: '50%', left: '50%',
          // Scale: small during transition, expands before toggle
          transform: `translate(-50%, -50%) translateY(80px) scale(${isoScale})`,
          opacity: isoOp * isoFade,
          display: 'flex', flexDirection: 'column',
          alignItems: 'center',
        }}>
          {/* Title appears above cards, centered */}
          <h1 style={{
            fontFamily: 'Outfit,system-ui,sans-serif', fontSize: 36, fontWeight: 900,
            color: 'white', margin: '0 0 6px', letterSpacing: '-0.025em',
            textAlign: 'center', width: 425,
            opacity: isoOp,
          }}>Two ways in.</h1>
          <p style={{
            fontFamily: 'Outfit,system-ui,sans-serif', fontSize: 16,
            color: 'rgba(255,255,255,0.48)', fontWeight: 500,
            margin: '0 0 28px', letterSpacing: '-0.01em',
            textAlign: 'center', width: 425,
            opacity: isoOp,
          }}>Zero friction.</p>
          <SpotlightCards focusOnJoin={focusOnJoin} joinTap={joinTap} />
        </div>
      )}

      {/* ═══════════════════════════════════════════════════
       * JOIN-GROUP FLOW (inside phone)
       * ═══════════════════════════════════════════════════ */}
      {frame >= JOIN_START - 4 && (
        <div style={{
          position: 'absolute', top: '50%', left: '50%',
          transform: `translate(-50%, -50%) translateY(80px) scale(${joinPhoneScale})`,
          opacity: joinFlowOp,
        }}>
          <PhoneMockup scale={1.05} drift>
            <JoinGroupFlow lf={localJoinFrame} />
          </PhoneMockup>
        </div>
      )}
    </AbsoluteFill>
  );
};
