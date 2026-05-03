import { AbsoluteFill, useCurrentFrame, useVideoConfig, spring, interpolate } from 'remotion';
import React from 'react';

const clamp = (v: number, lo = 0, hi = 1) => Math.max(lo, Math.min(hi, v));

/* ════════════════════════════════════════════════════════════════
 * ICONS
 * ════════════════════════════════════════════════════════════════ */
const MidpointIcon = () => (
  <svg width="24" height="24" viewBox="0 0 24 24" fill="#006D77">
    <path d="M12 2L13.5 8.5L20 10L13.5 11.5L12 18L10.5 11.5L4 10L10.5 8.5L12 2Z" />
    <path d="M18 14L18.75 16.25L21 17L18.75 17.75L18 20L17.25 17.75L15 17L17.25 16.25L18 14Z" opacity="0.7" />
  </svg>
);

const SpecificPlaceIcon = () => (
  <svg width="24" height="24" viewBox="0 0 24 24" fill="#f59e0b">
    <path d="M12 2C8.13 2 5 5.13 5 9C5 14.25 12 22 12 22C12 22 19 14.25 19 9C19 5.13 15.87 2 12 2ZM12 11.5C10.62 11.5 9.5 10.38 9.5 9C9.5 7.62 10.62 6.5 12 6.5C13.38 6.5 14.5 7.62 14.5 9C14.5 10.38 13.38 11.5 12 11.5Z" />
  </svg>
);

/* ════════════════════════════════════════════════════════════════
 * DARK MODAL ROW — identical to Scene 4 Spotlight style
 * ════════════════════════════════════════════════════════════════ */
interface DarkRowProps {
  icon: React.ReactNode;
  iconBg: string;
  title: string;
  subtitle: string;
  active?: boolean;
  dimmed?: boolean;
  tapScale?: number;
}
const DarkModalRow: React.FC<DarkRowProps> = ({
  icon, iconBg, title, subtitle,
  active = false, dimmed = false, tapScale = 1,
}) => (
  <div style={{
    borderRadius: 20,
    padding: '18px',
    display: 'flex', alignItems: 'center', gap: 16,
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
    <div style={{
      width: 52, height: 52, borderRadius: 26,
      background: active ? iconBg : 'rgba(255,255,255,0.07)',
      display: 'flex', justifyContent: 'center', alignItems: 'center', flexShrink: 0,
      transition: 'background 0.3s ease',
    }}>
      {icon}
    </div>
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
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none"
      stroke={active ? '#83C5BE' : 'rgba(255,255,255,0.18)'} strokeWidth="2.5" strokeLinecap="round">
      <path d="M9 18l6-6-6-6"/>
    </svg>
  </div>
);

/* ════════════════════════════════════════════════════════════════
 * SCENE 5b — OUTING OPTIONS INTERSTITIAL
 * Duration: 120 frames (4 seconds)
 * ════════════════════════════════════════════════════════════════ */
export const Scene5bOutingOptions: React.FC = () => {
  const { fps } = useVideoConfig();
  const frame = useCurrentFrame();

  const ENTER      = 0;
  const EXPAND_START = 22;
  const TOGGLE     = 65;
  const TAP_START  = 95;
  const TAP_PEAK   = 98;
  const FADE_OUT   = 110;
  const SCENE_END  = 120;

  const fadeInOp  = clamp(interpolate(frame, [ENTER, ENTER + 12], [0, 1]));
  const exitOp    = clamp(interpolate(frame, [FADE_OUT, SCENE_END], [1, 0]));
  const sceneOp   = fadeInOp * exitOp;

  // Match and zoom: Start matched to the bottom sheet of Scene 5
  // Expand starts at 22, giving time for the crossfade to finish before zooming
  const expandSpring = spring({ frame: frame - EXPAND_START, fps, config: { damping: 18, stiffness: 120 } });
  
  const sceneScale = frame < EXPAND_START ? 0.74 : interpolate(expandSpring, [0, 1], [0.74, 1.05]);
  const sceneTransY = frame < EXPAND_START ? 342 : interpolate(expandSpring, [0, 1], [342, 0]);
  
  // Specific Place is bottom card, starts active. Find Midpoint is top card, becomes active.
  const focusOnMidpoint = frame >= TOGGLE;
  
  // Tap animation on Find Midpoint
  const tapScale = clamp(interpolate(frame, [TAP_START, TAP_PEAK, TAP_PEAK + 5], [0, 1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' }));

  return (
    <AbsoluteFill style={{ backgroundColor: '#050714', overflow: 'hidden', opacity: sceneOp }}>
      <div style={{ position: 'absolute', inset: 0, background: 'radial-gradient(ellipse at 50% 50%,rgba(13,121,117,0.06) 0%,transparent 55%)' }} />

      <div style={{
        position: 'absolute',
        top: '50%', left: '50%',
        transform: `translate(-50%, -50%) translateY(${sceneTransY}px) scale(${sceneScale})`,
        display: 'flex', flexDirection: 'column',
        alignItems: 'center',
      }}>
        <h1 style={{
          fontFamily: 'Outfit,system-ui,sans-serif', fontSize: 36, fontWeight: 900,
          color: 'white', margin: '0 0 6px', letterSpacing: '-0.025em',
          textAlign: 'center', width: 425,
        }}>Two ways to start.</h1>
        <p style={{
          fontFamily: 'Outfit,system-ui,sans-serif', fontSize: 16,
          color: 'rgba(255,255,255,0.48)', fontWeight: 500,
          margin: '0 0 28px', letterSpacing: '-0.01em',
          textAlign: 'center', width: 425,
        }}>Choose a destination, or find the fairest midpoint.</p>
        
        <div style={{ width: 425, display: 'flex', flexDirection: 'column' }}>
          <div style={{ marginBottom: 20 }}>
            <DarkModalRow
              icon={<MidpointIcon />}
              iconBg="#ebf7f6"
              title="Find Midpoint"
              subtitle="The fairest option for the whole group"
              active={focusOnMidpoint}
              dimmed={!focusOnMidpoint}
              tapScale={1 - tapScale * 0.04}
            />
          </div>
          <DarkModalRow
            icon={<SpecificPlaceIcon />}
            iconBg="#fff3ec"
            title="Specific Place"
            subtitle="For when you already know where you're going"
            active={!focusOnMidpoint}
            dimmed={focusOnMidpoint}
          />
        </div>
      </div>
    </AbsoluteFill>
  );
};
