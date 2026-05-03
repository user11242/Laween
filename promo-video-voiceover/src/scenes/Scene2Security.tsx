import { AbsoluteFill, interpolate, useCurrentFrame, useVideoConfig, spring } from 'remotion';
import React from 'react';
import { PhoneMockup } from '../components/PhoneMockup';

/*
 *  Scene 2 — SECURITY
 *
 *  Phase 1 (0-42):   Phone mockup with exact Face ID permission dialog.
 *  Phase 2 (42-58):  "Allow" tapped → phone dims, green Face ID icon zooms/glows to center.
 *  Phase 3 (58-75):  Dark card with Face ID face icon (bracket corners + face) + "Face ID" text.
 *  Phase 4 (75-92):  Face morphs into swirling orbiting rings (the iOS processing animation).
 *  Phase 5 (92-110): Rings resolve into circle with checkmark + "Face ID" text.
 *  Phase 6 (110+):   Scene exit.
 */
export const Scene2Security: React.FC = () => {
  const { fps } = useVideoConfig();
  const frame = useCurrentFrame();

  // ═══════════════════════════════════════════
  //  TITLE
  // ═══════════════════════════════════════════
  const titleSpring = spring({ frame: frame - 5, fps, config: { damping: 14, mass: 0.8 } });
  const titleY = interpolate(titleSpring, [0, 1], [60, 0]);
  const titleOp = interpolate(frame, [5, 18], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const titleFadeOut = interpolate(frame, [40, 50], [1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  const subStart = 12;
  const subOp = interpolate(frame, [subStart, subStart + 12], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const subY = interpolate(spring({ frame: frame - subStart, fps, config: { damping: 16 } }), [0, 1], [30, 0]);

  // ═══════════════════════════════════════════
  //  PHASE 1: Phone with Face ID dialog
  // ═══════════════════════════════════════════
  const phoneStart = 10;
  const phoneSpring = spring({ frame: frame - phoneStart, fps, config: { damping: 14, mass: 1 } });
  const phoneY = interpolate(phoneSpring, [0, 1], [500, 0]);
  const phoneOp = interpolate(frame, [phoneStart, phoneStart + 12], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const floatY = Math.sin(frame * 0.06) * 4;

  // "Allow" tap at frame 42
  const tapFrame = 42;
  const allowScale = (frame >= tapFrame && frame < tapFrame + 6)
    ? interpolate(frame, [tapFrame, tapFrame + 3, tapFrame + 6], [1, 0.90, 1], { extrapolateRight: 'clamp' })
    : 1;

  // Phone dims & stays visible behind the glowing icon (like inspo image 1)
  const phoneDimStart = 44;
  const phoneDimOp = interpolate(frame, [phoneDimStart, phoneDimStart + 14], [1, 0.15], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const phoneFinalFade = interpolate(frame, [58, 66], [0.15, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  // ═══════════════════════════════════════════
  //  PHASE 2: Green icon zooms to center (over dimmed phone)
  // ═══════════════════════════════════════════
  const iconZoomStart = 44;
  const iconZoomSpring = spring({ frame: frame - iconZoomStart, fps, config: { damping: 12, mass: 0.8 } });
  const iconScale = interpolate(iconZoomSpring, [0, 1], [0.4, 1]);
  const iconOp = interpolate(frame, [iconZoomStart, iconZoomStart + 8], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const iconFadeOut = interpolate(frame, [56, 62], [1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  // Glow pulse behind the icon
  const glowPulse = 1 + Math.sin((frame - iconZoomStart) * 0.2) * 0.1;

  // ═══════════════════════════════════════════
  //  PHASE 3: Dark card with Face ID face icon
  // ═══════════════════════════════════════════
  const cardStart = 58;
  const cardSpring = spring({ frame: frame - cardStart, fps, config: { damping: 14 } });
  const cardScale = interpolate(cardSpring, [0, 1], [0.85, 1]);
  const cardOp = interpolate(frame, [cardStart, cardStart + 8], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  // Face icon visible in card (before it morphs to rings)
  const faceIconOp = interpolate(frame, [75, 80], [1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  // ═══════════════════════════════════════════
  //  PHASE 4: Swirling orbiting rings
  // ═══════════════════════════════════════════
  const ringStart = 76;
  const ringOp = interpolate(frame, [ringStart, ringStart + 6], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const ringFade = interpolate(frame, [90, 95], [1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  // Ring rotation angles
  const ringAngle1 = (frame - ringStart) * 6;
  const ringAngle2 = (frame - ringStart) * -4 + 60;
  const ringAngle3 = (frame - ringStart) * 5 + 120;

  // ═══════════════════════════════════════════
  //  PHASE 5: Checkmark circle
  // ═══════════════════════════════════════════
  const checkStart = 92;
  const checkSpring = spring({ frame: frame - checkStart, fps, config: { damping: 10, stiffness: 120 } });
  const checkScale = interpolate(checkSpring, [0, 1], [0.5, 1]);
  const checkOp = interpolate(frame, [checkStart, checkStart + 6], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  // Card fade out at end
  const cardFinalOp = interpolate(frame, [108, 116], [1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  // ═══════════════════════════════════════════
  //  SCENE EXIT
  // ═══════════════════════════════════════════
  const exitStart = 112;
  const exitSpring = spring({ frame: frame - exitStart, fps, config: { damping: 12 } });
  const exitScale = interpolate(exitSpring, [0, 1], [1, 0.8]);
  const exitOp = interpolate(exitSpring, [0, 0.6], [1, 0]);

  return (
    <AbsoluteFill style={{
      backgroundColor: '#050714',
      justifyContent: 'center',
      alignItems: 'center',
      transform: `scale(${exitScale})`,
      opacity: exitOp,
    }}>

      {/* Ambient glow — intensifies during icon zoom */}
      <div style={{
        position: 'absolute', width: '120%', height: '120%',
        background: frame >= iconZoomStart && frame < 66
          ? `radial-gradient(ellipse at 50% 45%, rgba(34,197,94,${0.15 + Math.sin((frame - iconZoomStart) * 0.15) * 0.08}) 0%, transparent 50%)`
          : 'radial-gradient(ellipse at 50% 30%, rgba(16,185,129,0.10) 0%, transparent 60%)',
      }} />

      {/* ═══ TITLE ═══ */}
      <div style={{
        position: 'absolute', top: '8%',
        display: 'flex', flexDirection: 'column', alignItems: 'center',
        transform: `translateY(${titleY}px)`, opacity: titleOp * titleFadeOut,
        zIndex: 10,
      }}>
        <h1 style={{
          fontFamily: 'Inter, sans-serif', fontSize: 78, fontWeight: 900, color: 'white',
          margin: 0, letterSpacing: '-0.03em',
          textShadow: '0 8px 40px rgba(16,185,129,0.45)',
        }}>
          Ironclad Security
        </h1>
        <p style={{
          fontFamily: 'Inter, sans-serif', fontSize: 28, color: '#6ee7b7', fontWeight: 600,
          margin: '16px 0 0 0', opacity: subOp,
          transform: `translateY(${subY}px)`, letterSpacing: '0.04em',
        }}>
          Face ID · Phone Verification · Zero Friction
        </p>
      </div>

      {/* ═══ PHASE 1: PHONE (dims but stays visible behind icon) ═══ */}
      <div style={{
        transform: `translateY(${phoneY + floatY}px)`,
        opacity: phoneOp * (frame < 58 ? phoneDimOp : phoneFinalFade),
        marginTop: 80,
        filter: frame >= phoneDimStart ? `brightness(${interpolate(frame, [phoneDimStart, phoneDimStart + 14], [1, 0.3], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' })})` : 'none',
      }}>
        <PhoneMockup>
          {/* Background */}
          <div style={{
            position: 'absolute', inset: 0,
            background: 'linear-gradient(180deg, #4a6055 0%, #2a3a3c 30%, #0c1a1c 60%, #0a0e14 100%)',
          }} />

          {/* "Let's Meet Up!" */}
          <div style={{ position: 'absolute', top: '14%', width: '100%', textAlign: 'center' }}>
            <h2 style={{
              fontFamily: 'Inter, sans-serif', fontSize: 48, fontWeight: 900,
              color: 'rgba(255,255,255,0.65)', margin: 0, lineHeight: 1.05,
            }}>
              Let's Meet<br/>Up!
            </h2>
            <div style={{ width: 60, height: 4, borderRadius: 2, background: '#14b8a6', margin: '14px auto 0' }} />
          </div>

          {/* Face ID Dialog */}
          <div style={{
            position: 'absolute', top: '32%', left: '7%', right: '7%',
            background: 'rgba(50,58,62,0.92)', backdropFilter: 'blur(40px)',
            borderRadius: 18, padding: '26px 22px 18px',
            boxShadow: '0 20px 60px rgba(0,0,0,0.5)',
          }}>
            {/* Green icon */}
            <div style={{
              width: 60, height: 60, borderRadius: 15,
              background: 'linear-gradient(135deg, #4ade80, #22c55e)',
              display: 'flex', justifyContent: 'center', alignItems: 'center',
              marginBottom: 16, boxShadow: '0 6px 20px rgba(34,197,94,0.4)',
            }}>
              <svg width="32" height="32" viewBox="0 0 32 32" fill="none">
                <path d="M5 10V7C5 5.9 5.9 5 7 5H10" stroke="white" strokeWidth="2.2" strokeLinecap="round"/>
                <path d="M22 5H25C26.1 5 27 5.9 27 7V10" stroke="white" strokeWidth="2.2" strokeLinecap="round"/>
                <path d="M27 22V25C27 26.1 26.1 27 25 27H22" stroke="white" strokeWidth="2.2" strokeLinecap="round"/>
                <path d="M10 27H7C5.9 27 5 26.1 5 25V22" stroke="white" strokeWidth="2.2" strokeLinecap="round"/>
                <circle cx="12" cy="13" r="1.3" fill="white"/>
                <circle cx="20" cy="13" r="1.3" fill="white"/>
                <path d="M16 14V18" stroke="white" strokeWidth="1.5" strokeLinecap="round"/>
                <path d="M12 21C12 21 13.5 23 16 23C18.5 23 20 21 20 21" stroke="white" strokeWidth="1.5" strokeLinecap="round"/>
              </svg>
            </div>

            <p style={{ fontFamily: 'Inter', fontSize: 19, fontWeight: 700, color: 'white', margin: '0 0 8px', lineHeight: 1.35 }}>
              Do you want to allow "Laween" to use Face ID?
            </p>
            <p style={{ fontFamily: 'Inter', fontSize: 14, color: '#9ca3af', margin: '0 0 20px', lineHeight: 1.5 }}>
              Laween uses Face ID to allow you to sign in quickly and securely.
            </p>

            <div style={{ display: 'flex', gap: 10 }}>
              <div style={{
                flex: 1, background: 'rgba(255,255,255,0.12)', borderRadius: 12,
                padding: '13px 0', textAlign: 'center',
                fontFamily: 'Inter', fontSize: 16, fontWeight: 600, color: 'white',
              }}>Don't Allow</div>
              <div style={{
                flex: 1, background: 'rgba(255,255,255,0.12)', borderRadius: 12,
                padding: '13px 0', textAlign: 'center',
                fontFamily: 'Inter', fontSize: 16, fontWeight: 600, color: 'white',
                transform: `scale(${allowScale})`,
              }}>Allow</div>
            </div>
          </div>

          {/* Forgot Password */}
          <div style={{ position: 'absolute', bottom: '28%', width: '100%', textAlign: 'center' }}>
            <p style={{ fontFamily: 'Inter', fontSize: 14, color: 'rgba(45,212,191,0.5)', margin: 0 }}>Forgot Password?</p>
          </div>

          {/* Continue */}
          <div style={{ position: 'absolute', bottom: '14%', left: '8%', right: '8%' }}>
            <div style={{
              width: '100%', background: 'linear-gradient(90deg, #2dd4bf, #0f766e)',
              borderRadius: 50, padding: '16px 0', textAlign: 'center',
              fontFamily: 'Inter', fontSize: 19, fontWeight: 700, color: 'white',
            }}>Continue</div>
          </div>

          {/* Social buttons */}
          <div style={{
            position: 'absolute', bottom: '4%', left: 0, right: 0,
            display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 10,
          }}>
            <span style={{ fontFamily: 'Inter', fontSize: 11, color: '#475569', letterSpacing: '0.12em', fontWeight: 700 }}>
              OR CONTINUE WITH
            </span>
            <div style={{ display: 'flex', gap: 16 }}>
              <div style={{ width: 46, height: 46, borderRadius: 23, background: '#1e293b', border: '1px solid #334155' }} />
              <div style={{
                width: 46, height: 46, borderRadius: 23, background: '#e2e8f0', border: '1px solid #cbd5e1',
                display: 'flex', justifyContent: 'center', alignItems: 'center',
              }}>
                <span style={{ fontSize: 22, fontWeight: 700 }}>G</span>
              </div>
            </div>
          </div>
        </PhoneMockup>
      </div>

      {/* ═══ PHASE 2: GREEN ICON ZOOMS OVER DIMMED PHONE ═══ */}
      {frame >= iconZoomStart && frame < 66 && (
        <div style={{
          position: 'absolute',
          display: 'flex', flexDirection: 'column', alignItems: 'center',
          transform: `scale(${iconScale})`,
          opacity: iconOp * iconFadeOut,
          zIndex: 20,
        }}>
          {/* Glow halo */}
          <div style={{
            position: 'absolute',
            width: 220, height: 220, borderRadius: 60,
            background: 'radial-gradient(circle, rgba(34,197,94,0.35) 0%, rgba(34,197,94,0.1) 50%, transparent 70%)',
            transform: `scale(${glowPulse})`,
          }} />

          {/* Icon */}
          <div style={{
            width: 120, height: 120, borderRadius: 30,
            background: 'linear-gradient(135deg, #4ade80, #22c55e)',
            display: 'flex', justifyContent: 'center', alignItems: 'center',
            boxShadow: '0 20px 80px rgba(34,197,94,0.6), 0 0 100px rgba(34,197,94,0.25)',
          }}>
            <svg width="62" height="62" viewBox="0 0 32 32" fill="none">
              <path d="M5 10V7C5 5.9 5.9 5 7 5H10" stroke="white" strokeWidth="2" strokeLinecap="round"/>
              <path d="M22 5H25C26.1 5 27 5.9 27 7V10" stroke="white" strokeWidth="2" strokeLinecap="round"/>
              <path d="M27 22V25C27 26.1 26.1 27 25 27H22" stroke="white" strokeWidth="2" strokeLinecap="round"/>
              <path d="M10 27H7C5.9 27 5 26.1 5 25V22" stroke="white" strokeWidth="2" strokeLinecap="round"/>
              <circle cx="12" cy="13" r="1.3" fill="white"/>
              <circle cx="20" cy="13" r="1.3" fill="white"/>
              <path d="M16 14V18" stroke="white" strokeWidth="1.5" strokeLinecap="round"/>
              <path d="M12 21C12 21 13.5 23 16 23C18.5 23 20 21 20 21" stroke="white" strokeWidth="1.5" strokeLinecap="round"/>
            </svg>
          </div>
        </div>
      )}

      {/* ═══ PHASE 3-5: DARK CARD (Face → Rings → Check) ═══ */}
      {frame >= cardStart && (
        <div style={{
          position: 'absolute',
          display: 'flex', flexDirection: 'column', alignItems: 'center',
          transform: `scale(${cardScale})`,
          opacity: cardOp * cardFinalOp,
          zIndex: 20,
        }}>
          {/* Dark rounded square card */}
          <div style={{
            width: 240, height: 260,
            borderRadius: 36,
            background: 'rgba(58,63,68,0.9)',
            backdropFilter: 'blur(30px)',
            display: 'flex', flexDirection: 'column',
            alignItems: 'center', justifyContent: 'center',
            gap: 20,
            boxShadow: '0 30px 80px rgba(0,0,0,0.6)',
            padding: '30px 20px',
          }}>

            {/* ── Face ID face icon (Phase 3) ── */}
            <div style={{
              position: 'absolute', top: 40,
              opacity: faceIconOp,
            }}>
              <svg width="100" height="100" viewBox="0 0 100 100" fill="none">
                {/* Bracket corners */}
                <path d="M10 30V16C10 12 14 10 18 10H30" stroke="rgba(255,255,255,0.7)" strokeWidth="5" strokeLinecap="round"/>
                <path d="M70 10H82C86 10 90 14 90 18V30" stroke="rgba(255,255,255,0.7)" strokeWidth="5" strokeLinecap="round"/>
                <path d="M90 70V82C90 86 86 90 82 90H70" stroke="rgba(255,255,255,0.7)" strokeWidth="5" strokeLinecap="round"/>
                <path d="M30 90H18C14 90 10 86 10 82V70" stroke="rgba(255,255,255,0.7)" strokeWidth="5" strokeLinecap="round"/>
                {/* Left eye */}
                <path d="M33 38V48" stroke="rgba(255,255,255,0.7)" strokeWidth="4" strokeLinecap="round"/>
                {/* Right eye */}
                <path d="M67 38V48" stroke="rgba(255,255,255,0.7)" strokeWidth="4" strokeLinecap="round"/>
                {/* Nose */}
                <path d="M50 42V58C50 58 50 62 46 64" stroke="rgba(255,255,255,0.7)" strokeWidth="3.5" strokeLinecap="round"/>
                {/* Mouth */}
                <path d="M36 72C36 72 42 80 50 80C58 80 64 72 64 72" stroke="rgba(255,255,255,0.7)" strokeWidth="4" strokeLinecap="round"/>
              </svg>
            </div>

            {/* ── Swirling orbiting rings (Phase 4) ── */}
            {frame >= ringStart && (
              <div style={{
                position: 'absolute', top: 40,
                width: 100, height: 100,
                opacity: ringOp * ringFade,
              }}>
                {/* Ring 1 — main orbit */}
                <div style={{
                  position: 'absolute', inset: 0,
                  display: 'flex', justifyContent: 'center', alignItems: 'center',
                }}>
                  <svg width="100" height="100" viewBox="0 0 100 100" fill="none"
                    style={{ transform: `rotate(${ringAngle1}deg)` }}
                  >
                    <ellipse cx="50" cy="50" rx="42" ry="18"
                      stroke="url(#ring1grad)" strokeWidth="3.5" strokeLinecap="round"
                      strokeDasharray="20 10"
                    />
                    <defs>
                      <linearGradient id="ring1grad" x1="0" y1="0" x2="100" y2="100">
                        <stop offset="0%" stopColor="#a78bfa"/>
                        <stop offset="50%" stopColor="#67e8f9"/>
                        <stop offset="100%" stopColor="#86efac"/>
                      </linearGradient>
                    </defs>
                  </svg>
                </div>

                {/* Ring 2 — perpendicular orbit */}
                <div style={{
                  position: 'absolute', inset: 0,
                  display: 'flex', justifyContent: 'center', alignItems: 'center',
                }}>
                  <svg width="100" height="100" viewBox="0 0 100 100" fill="none"
                    style={{ transform: `rotate(${ringAngle2}deg)` }}
                  >
                    <ellipse cx="50" cy="50" rx="38" ry="22"
                      stroke="url(#ring2grad)" strokeWidth="3" strokeLinecap="round"
                      strokeDasharray="15 12"
                    />
                    <defs>
                      <linearGradient id="ring2grad" x1="0" y1="0" x2="100" y2="100">
                        <stop offset="0%" stopColor="#67e8f9"/>
                        <stop offset="50%" stopColor="#c4b5fd"/>
                        <stop offset="100%" stopColor="#fbcfe8"/>
                      </linearGradient>
                    </defs>
                  </svg>
                </div>

                {/* Ring 3 — tilted orbit */}
                <div style={{
                  position: 'absolute', inset: 0,
                  display: 'flex', justifyContent: 'center', alignItems: 'center',
                }}>
                  <svg width="100" height="100" viewBox="0 0 100 100" fill="none"
                    style={{ transform: `rotate(${ringAngle3}deg)` }}
                  >
                    <ellipse cx="50" cy="50" rx="35" ry="28"
                      stroke="url(#ring3grad)" strokeWidth="2.5" strokeLinecap="round"
                      strokeDasharray="18 14"
                    />
                    <defs>
                      <linearGradient id="ring3grad" x1="0" y1="0" x2="100" y2="100">
                        <stop offset="0%" stopColor="#86efac"/>
                        <stop offset="50%" stopColor="#a78bfa"/>
                        <stop offset="100%" stopColor="#67e8f9"/>
                      </linearGradient>
                    </defs>
                  </svg>
                </div>

                {/* Central glow orb */}
                <div style={{
                  position: 'absolute', top: '50%', left: '50%',
                  transform: 'translate(-50%, -50%)',
                  width: 20, height: 20, borderRadius: 10,
                  background: 'radial-gradient(circle, rgba(167,139,250,0.6) 0%, transparent 70%)',
                  boxShadow: '0 0 30px rgba(167,139,250,0.4), 0 0 60px rgba(103,232,249,0.2)',
                }} />
              </div>
            )}

            {/* ── Checkmark circle (Phase 5) ── */}
            {frame >= checkStart && (
              <div style={{
                position: 'absolute', top: 40,
                width: 100, height: 100,
                display: 'flex', justifyContent: 'center', alignItems: 'center',
                transform: `scale(${checkScale})`,
                opacity: checkOp,
              }}>
                <svg width="100" height="100" viewBox="0 0 100 100" fill="none">
                  {/* Circle outline */}
                  <circle cx="50" cy="50" r="40" stroke="rgba(255,255,255,0.7)" strokeWidth="4"/>
                  {/* Checkmark */}
                  <path
                    d="M30 50L44 64L70 36"
                    stroke="rgba(255,255,255,0.85)"
                    strokeWidth="5"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeDasharray="80"
                    strokeDashoffset={interpolate(checkSpring, [0, 1], [80, 0])}
                  />
                </svg>
              </div>
            )}

            {/* "Face ID" text */}
            <p style={{
              position: 'absolute', bottom: 30,
              fontFamily: 'Inter, sans-serif',
              fontSize: 26, fontWeight: 700,
              color: 'white',
              margin: 0,
            }}>
              Face ID
            </p>
          </div>
        </div>
      )}
    </AbsoluteFill>
  );
};
