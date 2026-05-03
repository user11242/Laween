import {
  AbsoluteFill,
  useCurrentFrame,
  useVideoConfig,
  spring,
  interpolate,
  Img,
  staticFile,
} from 'remotion';
import React from 'react';
import { PhoneMockup } from '../components/PhoneMockup';

/* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 * SCENE 3 — FACE ID LOGIN FLOW  (150 frames / 5 s @ 30 fps)
 *
 * 0–15   Phone enters — real login screen visible
 * 15–28  Face ID button glows + tap
 * 28–48  Screen dims → FaceID dialog slides in
 * 48–64  Phone fades out, dialog floats to centre
 * 64–98  Scan phase — rotating orb + subtle glow behind icon
 * 98–132 Check draws — glow instantly removed, crisp icon
 * 132–150 Hold, exit fade
 * ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ */

/* ─────────────────────────────────────────────────────────
 * FACE ID ICON (Exact match to Flutter app's FaceIdPainter)
 * ───────────────────────────────────────────────────────── */
const FaceIdSVG: React.FC<{ size: number; color?: string; opacity?: number }> = ({
  size,
  color = 'rgba(255,255,255,0.90)',
  opacity = 1,
}) => (
  <svg width={size} height={size} viewBox="0 0 100 100" fill="none" style={{ opacity }}>
    {/* ── CORNER BRACKETS (Sharp) ── */}
    <path d="M 30 10 L 10 10 L 10 30" stroke={color} strokeWidth="6" strokeLinecap="round" strokeLinejoin="round"/>
    <path d="M 70 10 L 90 10 L 90 30" stroke={color} strokeWidth="6" strokeLinecap="round" strokeLinejoin="round"/>
    <path d="M 10 70 L 10 90 L 30 90" stroke={color} strokeWidth="6" strokeLinecap="round" strokeLinejoin="round"/>
    <path d="M 90 70 L 90 90 L 70 90" stroke={color} strokeWidth="6" strokeLinecap="round" strokeLinejoin="round"/>

    {/* ── FACE FEATURES ── */}
    {/* Eyes */}
    <circle cx="35" cy="40" r="5" fill={color}/>
    <circle cx="65" cy="40" r="5" fill={color}/>

    {/* Nose: sharp angles */}
    <path d="M 50 45 L 50 60 L 45 65" stroke={color} strokeWidth="6" strokeLinecap="round" strokeLinejoin="round"/>

    {/* Smile: arc */}
    <path d="M 30 66 Q 50 84 70 66" stroke={color} strokeWidth="6" strokeLinecap="round"/>
  </svg>
);

/* ─────────────────────────────────────────────────────────
 * VERIFICATION CHECK ICON
 * ───────────────────────────────────────────────────────── */
const CheckSVG: React.FC<{
  size: number;
  color?: string;
  drawProgress: number;
  strokeW?: number;
}> = ({ size, color = 'rgba(255,255,255,0.95)', drawProgress, strokeW = 4 }) => {
  const dash = 85;
  return (
    <svg width={size} height={size} viewBox="0 0 100 100" fill="none">
      {/* Smooth thin circle */}
      <circle cx="50" cy="50" r="42"
        stroke={color} strokeWidth={strokeW - 1}
        strokeOpacity="0.88" fill="none"/>
      {/* Compact checkmark — rounded */}
      <path d="M 30 50 L 44 64 L 70 36"
        stroke={color} strokeWidth={strokeW + 1}
        strokeLinecap="round" strokeLinejoin="round"
        strokeDasharray={dash}
        strokeDashoffset={interpolate(drawProgress, [0, 1], [dash, 0])}
        fill="none"/>
    </svg>
  );
};

/* ─────────────────────────────────────────────────────────
 * REACT LOGIN SCREEN  (378 × 832 virtual viewport)
 * Uses real background photo: login_bg.jpg (onboarding_img2)
 * Dark glass overlay keeps text legible — no duplication
 * ───────────────────────────────────────────────────────── */
const LoginScreen: React.FC<{
  dimAmount?: number;
  highlightFaceId?: boolean;
}> = ({ dimAmount = 1, highlightFaceId = false }) => (
  <div style={{
    position: 'absolute', inset: 0, overflow: 'hidden',
    fontFamily: '"Outfit", "Inter", system-ui, sans-serif',
    backgroundColor: '#06090e',
  }}>

    {/* ── Real background photo — friends laughing on street ── */}
    <Img
      src={staticFile('login_bg.jpg')}
      style={{
        position: 'absolute', top: 0, left: 0,
        width: '100%', height: '62%',
        objectFit: 'cover', objectPosition: 'center 20%',
      }}
    />

    {/* ── Gradient overlay — preserves photo mood, darkens text area ── */}
    <div style={{
      position: 'absolute', inset: 0,
      background: [
        'linear-gradient(180deg,',
        '  rgba(6,9,14,0.28) 0%,',
        '  rgba(6,9,14,0.35) 20%,',
        '  rgba(6,9,14,0.60) 40%,',
        '  rgba(6,9,14,0.88) 56%,',
        '  #06090e 68%)',
      ].join(' '),
    }}/>

    {/* ── Dim overlay during tap sequence ── */}
    {dimAmount < 1 && (
      <div style={{
        position: 'absolute', inset: 0, zIndex: 6,
        background: `rgba(0,0,0,${(1 - dimAmount) * 0.46})`,
      }}/>
    )}

    {/* ── STATUS BAR ── */}
    <div style={{
      position: 'absolute', top: 12, left: 0, right: 0,
      display: 'flex', justifyContent: 'space-between', alignItems: 'center',
      padding: '0 24px', zIndex: 20,
    }}>
      <span style={{ color: 'white', fontSize: 15, fontWeight: 700, letterSpacing: '-0.01em' }}>12:43</span>
      <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
        {/* Bars */}
        <svg width="17" height="12" viewBox="0 0 17 12" fill="white">
          <rect x="0"    y="8"   width="3"   height="4"  rx="0.5"/>
          <rect x="4.5"  y="5.5" width="3"   height="6.5" rx="0.5"/>
          <rect x="9"    y="2.5" width="3"   height="9.5" rx="0.5"/>
          <rect x="13.5" y="0"   width="3.5" height="12" rx="0.5"/>
        </svg>
        {/* WiFi */}
        <svg width="15" height="12" viewBox="0 0 15 12" fill="none">
          <circle cx="7.5" cy="11" r="1.5" fill="white"/>
          <path d="M3.5 7.5 Q7.5 3.5 11.5 7.5" stroke="white" strokeWidth="1.4" strokeLinecap="round"/>
          <path d="M0.5 4.5 Q7.5 -1 14.5 4.5" stroke="white" strokeWidth="1.4" strokeLinecap="round"/>
        </svg>
        {/* Battery */}
        <svg width="26" height="13" viewBox="0 0 26 13" fill="none">
          <rect x="0.5" y="0.5" width="22" height="12" rx="3" stroke="white" strokeOpacity="0.45" strokeWidth="1"/>
          <rect x="2"   y="2"   width="18" height="9"  rx="1.5" fill="white"/>
          <path d="M23.5 4 L23.5 9 Q25.5 8.5 25.5 6.5 Q25.5 4.5 23.5 4Z" fill="white" fillOpacity="0.45"/>
        </svg>
      </div>
    </div>

    {/* ── BACK ARROW ── */}
    <div style={{
      position: 'absolute', top: 54, left: 20,
      color: 'rgba(255,255,255,0.72)', fontSize: 26, lineHeight: 1, zIndex: 20,
    }}>‹</div>

    {/* ── HERO TITLE ── */}
    <div style={{
      position: 'absolute', top: 88, left: 0, right: 0,
      textAlign: 'center', zIndex: 20, padding: '0 26px',
    }}>
      <h1 style={{
        color: 'white', margin: 0,
        fontSize: 52, fontWeight: 900, lineHeight: 1.08,
        letterSpacing: '-0.025em',
        textShadow: '0 3px 28px rgba(0,0,0,0.65)',
      }}>
        Let's Meet<br/>Up!
      </h1>
      <div style={{
        width: 48, height: 3.5, borderRadius: 2,
        background: '#006D77', margin: '12px auto 0',
      }}/>
      <p style={{
        color: 'rgba(255,255,255,0.55)', fontSize: 16,
        margin: '10px 0 0', fontWeight: 400, letterSpacing: '0.01em',
      }}>
        Your hangout is waiting.
      </p>
    </div>

    {/* ── FORM AREA — pinned to bottom ── */}
    <div style={{
      position: 'absolute', bottom: 0, left: 0, right: 0,
      padding: '0 22px 42px', zIndex: 20,
    }}>

      {/* Email */}
      <div style={{
        background: 'rgba(255,255,255,0.055)',
        border: '1px solid rgba(255,255,255,0.09)',
        borderRadius: 18, padding: '0 18px',
        height: 58, display: 'flex', alignItems: 'center', gap: 12,
        marginBottom: 10,
      }}>
        <svg width="19" height="19" viewBox="0 0 24 24" fill="none">
          <rect x="2" y="4.5" width="20" height="15" rx="3"
            stroke="rgba(255,255,255,0.38)" strokeWidth="1.7"/>
          <path d="M2 8.5 L12 14.5 L22 8.5"
            stroke="rgba(255,255,255,0.38)" strokeWidth="1.7" strokeLinecap="round"/>
        </svg>
        <span style={{ color: 'rgba(255,255,255,0.30)', fontSize: 15.5 }}>Email</span>
      </div>

      {/* Password */}
      <div style={{
        background: 'rgba(255,255,255,0.055)',
        border: '1px solid rgba(255,255,255,0.09)',
        borderRadius: 18, padding: '0 18px',
        height: 58, display: 'flex', alignItems: 'center', gap: 12,
        marginBottom: 6,
      }}>
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
          <rect x="4" y="11" width="16" height="11" rx="3"
            stroke="rgba(255,255,255,0.38)" strokeWidth="1.7"/>
          <path d="M8 11 L8 7 Q8 3 12 3 Q16 3 16 7 L16 11"
            stroke="rgba(255,255,255,0.38)" strokeWidth="1.7" strokeLinecap="round"/>
        </svg>
        <span style={{ color: 'rgba(255,255,255,0.30)', fontSize: 15.5, flex: 1 }}>Password</span>
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
          <path d="M3 12 Q7 5 12 5 Q17 5 21 12 Q17 19 12 19 Q7 19 3 12Z"
            stroke="rgba(255,255,255,0.22)" strokeWidth="1.7"/>
          <circle cx="12" cy="12" r="3" stroke="rgba(255,255,255,0.22)" strokeWidth="1.7"/>
          <line x1="4" y1="4" x2="20" y2="20"
            stroke="rgba(255,255,255,0.28)" strokeWidth="1.7" strokeLinecap="round"/>
        </svg>
      </div>

      {/* Forgot password */}
      <div style={{ textAlign: 'right', marginBottom: 18 }}>
        <span style={{ color: 'rgba(255,255,255,0.35)', fontSize: 13 }}>Forgot Password?</span>
      </div>

      {/* Continue button */}
      <div style={{
        height: 58, borderRadius: 30,
        background: 'linear-gradient(135deg, #83C5BE 0%, #006D77 100%)',
        boxShadow: '0 6px 26px rgba(0,109,119,0.32)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        marginBottom: 22,
      }}>
        <span style={{ color: 'white', fontSize: 17, fontWeight: 700, letterSpacing: '0.3px' }}>
          Continue
        </span>
      </div>

      {/* Divider */}
      <div style={{ textAlign: 'center', marginBottom: 18 }}>
        <span style={{
          color: 'rgba(255,255,255,0.38)', fontSize: 10.5,
          fontWeight: 700, letterSpacing: '1.6px',
        }}>OR CONTINUE WITH</span>
      </div>

      {/* Social buttons */}
      <div style={{ display: 'flex', justifyContent: 'center', gap: 48 }}>

        {/* Face ID */}
        <div style={{
          width: 58, height: 58, borderRadius: 29,
          background: highlightFaceId ? 'rgba(0,109,119,0.13)' : 'rgba(255,255,255,0.035)',
          border: `1px solid ${highlightFaceId ? 'rgba(0,109,119,0.55)' : 'rgba(255,255,255,0.07)'}`,
          boxShadow: highlightFaceId ? '0 0 22px rgba(0,109,119,0.40)' : 'none',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <FaceIdSVG size={30}/>
        </div>

        {/* Google */}
        <div style={{
          width: 58, height: 58, borderRadius: 29,
          overflow: 'hidden',
          border: '1px solid rgba(255,255,255,0.07)',
        }}>
          <Img src={staticFile('google_logo.jpg')}
            style={{ width: 58, height: 58, objectFit: 'cover' }}/>
        </div>
      </div>
    </div>
  </div>
);

/* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 * MAIN SCENE
 * ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ */
export const Scene3Security: React.FC = () => {
  const { fps } = useVideoConfig();
  const frame = useCurrentFrame();

  /* ── TIMING ── */
  const TAP_GLOW     = 15;
  const TAP_HIT      = 24;
  const SCREEN_DIM   = 28;
  const POPUP_IN     = 33;
  const PHONE_FADE_S = 50;
  const PHONE_FADE_E = 64;
  const SCAN_START   = 64;
  const CHECK_START  = 98;
  const SCENE_FADE   = 136;

  /* ── PHONE ENTRANCE ── */
  const phoneSp      = spring({ frame, fps, config: { damping: 18, stiffness: 210 } });
  const phoneY       = interpolate(phoneSp, [0, 1], [140, 80]);
  const phoneEntryOp = interpolate(frame, [0, 7], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const phoneFadeOp  = interpolate(frame, [PHONE_FADE_S, PHONE_FADE_E], [1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  /* ── SCREEN DIM ── */
  const screenDim    = interpolate(frame, [SCREEN_DIM, SCREEN_DIM + 10], [1, 0.42], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const glowActive   = frame >= TAP_GLOW && frame < TAP_HIT + 5;

  /* ── TAP RIPPLE ── */
  const rippleOp    = frame >= TAP_HIT ? interpolate(frame, [TAP_HIT, TAP_HIT + 15], [0.85, 0], { extrapolateRight: 'clamp' }) : 0;
  const rippleScale = frame >= TAP_HIT ? interpolate(frame, [TAP_HIT, TAP_HIT + 15], [0.75, 2.6], { extrapolateRight: 'clamp' }) : 0;

  /* ── POPUP CARD ── */
  const popupSp      = spring({ frame: frame - POPUP_IN, fps, config: { damping: 14, stiffness: 120 } });
  const popupScale   = interpolate(popupSp, [0, 1], [0.2, 1]);
  const popupOp      = interpolate(frame, [POPUP_IN, POPUP_IN + 7], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const popupGrow    = interpolate(frame, [PHONE_FADE_S, PHONE_FADE_E + 6], [1, 1.42], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  /* ── ICON TRANSITIONS ── */
  const faceIconOp   = interpolate(frame, [SCAN_START - 5, SCAN_START + 8], [1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  const orbOp  = frame >= SCAN_START
    ? interpolate(frame, [SCAN_START, SCAN_START + 8, CHECK_START - 5, CHECK_START + 2], [0, 1, 1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' })
    : 0;
  const orbRot   = frame >= SCAN_START ? (frame - SCAN_START) * 5 : 0;
  const orbPulse = 1 + Math.sin(frame * 0.22) * 0.05;

  // Scan glow — only while scanning, cut immediately when check starts
  const scanGlowOp = frame >= SCAN_START && frame < CHECK_START
    ? orbOp * (0.28 + Math.sin((frame - SCAN_START) * 0.18) * 0.12)
    : 0;

  /* ── CHECKMARK ── */
  const checkSp    = spring({ frame: frame - CHECK_START, fps, config: { damping: 11, stiffness: 105 } });
  const checkOp    = interpolate(frame, [CHECK_START, CHECK_START + 8], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const checkScale = interpolate(checkSp, [0, 1], [0.1, 1]);
  const checkDraw  = interpolate(checkSp, [0, 1], [0, 1]);

  /* ── "Face ID" label — fades when check appears, never returns ── */
  const labelOp = interpolate(frame, [CHECK_START, CHECK_START + 10], [1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  /* ── SCENE TITLE ── */
  const titleSp   = spring({ frame: frame - 3, fps, config: { damping: 14 } });
  const titleOp   = interpolate(frame, [3, 12], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const titleY    = interpolate(titleSp, [0, 1], [24, 0]);
  const titleFade = interpolate(frame, [SCENE_FADE, SCENE_FADE + 12], [1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  /* ── EXIT ── */
  const exitOp = interpolate(frame, [SCENE_FADE, SCENE_FADE + 12], [1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  return (
    <AbsoluteFill style={{ backgroundColor: '#050714', justifyContent: 'center', alignItems: 'center', opacity: exitOp }}>

      {/* Ambient glow */}
      <div style={{
        position: 'absolute', width: '100%', height: '100%',
        background: 'radial-gradient(ellipse at 50% 46%, rgba(20,184,166,0.04) 0%, transparent 52%)',
      }}/>

      <div style={{
        position: 'absolute', top: '5%', width: '100%', textAlign: 'center',
        opacity: titleOp * titleFade, transform: `translateY(${titleY}px)`, zIndex: 20,
      }}>
        <h1 style={{
          fontFamily: 'Inter, system-ui, sans-serif',
          fontSize: 64,
          fontWeight: 900,
          color: 'white', margin: 0, letterSpacing: '-0.02em', lineHeight: 1.15
        }}>
          Fast. Seamless. Protected.
        </h1>
        <p style={{ fontFamily: 'Inter, system-ui, sans-serif', fontSize: 30, fontWeight: 600, color: '#5eead4', margin: '14px 0 0' }}>
          One tap to get in.
        </p>
      </div>

      {/* ══════════════════════════════════════
       *  PHONE  —  scale 1.0 (to fit neatly in 1080p height below the title)
       * ══════════════════════════════════════ */}
      <div style={{
        transform: `translateY(${phoneY}px)`,
        opacity: phoneEntryOp * phoneFadeOp,
        position: 'relative',
      }}>
        <PhoneMockup scale={0.95} drift>

          <LoginScreen dimAmount={screenDim} highlightFaceId={glowActive}/>

          {/* Glow ring on Face ID button */}
          {glowActive && (
            <div style={{
              position: 'absolute',
              left: 136, bottom: 71,
              width: 58, height: 58, borderRadius: 29,
              transform: 'translate(-50%, 50%)',
              border: `2px solid rgba(20,184,166,${0.55 + Math.sin((frame - TAP_GLOW) * 1.1) * 0.38})`,
              background: `rgba(20,184,166,${0.08 + Math.sin((frame - TAP_GLOW) * 1.1) * 0.05})`,
              boxShadow: '0 0 24px rgba(20,184,166,0.40)',
              zIndex: 25,
            }}/>
          )}

          {/* Tap ripple */}
          {rippleOp > 0 && (
            <div style={{
              position: 'absolute',
              left: 136, bottom: 71,
              width: 58, height: 58, borderRadius: 29,
              transform: `translate(-50%, 50%) scale(${rippleScale})`,
              border: `1.5px solid rgba(20,184,166,${rippleOp})`,
              zIndex: 25,
            }}/>
          )}

        </PhoneMockup>
      </div>

      {/* ══════════════════════════════════════
       *  FACE ID VERIFICATION CARD
       *  Premium glass squircle with clean scanning rings
       * ══════════════════════════════════════ */}
      {frame >= POPUP_IN && (
        <div style={{
          position: 'absolute',
          transform: `scale(${popupScale * popupGrow})`,
          opacity: popupOp, zIndex: 30,
        }}>
          <div style={{
            width: 168,
            height: 168,
            background: 'rgba(30, 30, 30, 0.65)',
            backdropFilter: 'blur(40px) saturate(140%)',
            border: '1px solid rgba(255, 255, 255, 0.12)',
            borderRadius: 36,
            display: 'flex',
            flexDirection: 'column',
            justifyContent: 'center',
            alignItems: 'center',
            boxShadow: '0 30px 60px rgba(0,0,0,0.5), inset 0 1px 1px rgba(255,255,255,0.1)',
            position: 'relative',
          }}>

            {/* Icon container */}
            <div style={{
              width: 90, height: 90,
              position: 'relative',
              display: 'flex', justifyContent: 'center', alignItems: 'center',
              transform: `translateY(${labelOp > 0.02 ? -12 : 0}px)`,
            }}>

              {/* Scan glow — subtle radial light during scan */}
              {scanGlowOp > 0 && (
                <div style={{
                  position: 'absolute', inset: -20, borderRadius: '50%',
                  background: `radial-gradient(circle, rgba(94,234,212,${scanGlowOp * 0.8}) 0%, rgba(0,109,119,${scanGlowOp * 0.4}) 45%, transparent 70%)`,
                  filter: 'blur(16px)',
                }}/>
              )}

              {/* PHASE 1: Face ID icon */}
              {faceIconOp > 0.01 && (
                <div style={{ position: 'absolute', opacity: faceIconOp }}>
                  <FaceIdSVG size={72} color="rgba(255,255,255,0.95)"/>
                </div>
              )}

              {/* PHASE 2: Clean Scanning Rings */}
              {orbOp > 0.01 && (
                <div style={{ position: 'absolute', width: 90, height: 90, opacity: orbOp }}>
                  <svg width="90" height="90" viewBox="0 0 100 100" style={{ transformOrigin: '50% 50%', transform: `rotate(${orbRot * 1.5}deg)` }}>
                    {/* Subtle track */}
                    <circle cx="50" cy="50" r="46" stroke="rgba(255,255,255,0.06)" strokeWidth="4.5" fill="none" />
                    {/* Glowing progress ring */}
                    <circle cx="50" cy="50" r="46" stroke="url(#spin-grad)" strokeWidth="4.5" fill="none"
                      strokeDasharray="289" strokeDashoffset={289 * 0.7} strokeLinecap="round"
                    />
                    <defs>
                      <linearGradient id="spin-grad" x1="0%" y1="0%" x2="100%" y2="100%">
                        <stop offset="0%" stopColor="#5EEAD4" />
                        <stop offset="100%" stopColor="#006D77" />
                      </linearGradient>
                    </defs>
                  </svg>
                </div>
              )}

              {/* PHASE 3: Checkmark */}
              {frame >= CHECK_START && checkOp > 0.01 && (
                <div style={{
                  position: 'absolute',
                  opacity: checkOp,
                  transform: `scale(${checkScale})`,
                }}>
                  <CheckSVG size={74} color="rgba(255,255,255,0.98)" drawProgress={checkDraw} strokeW={5.5}/>
                </div>
              )}
            </div>

            {/* "Face ID" label */}
            {labelOp > 0.02 && (
              <div style={{
                position: 'absolute', bottom: 22,
                opacity: labelOp, width: '100%', textAlign: 'center',
              }}>
                <p style={{
                  fontFamily: 'Inter, system-ui, sans-serif',
                  fontSize: 16, fontWeight: 700, color: 'white',
                  margin: 0, letterSpacing: '0.02em',
                }}>
                  Face ID
                </p>
              </div>
            )}
          </div>
        </div>
      )}
    </AbsoluteFill>
  );
};
