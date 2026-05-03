import { AbsoluteFill, useCurrentFrame, useVideoConfig, spring, interpolate, Img, staticFile } from 'remotion';
import React from 'react';
import { PhoneMockup } from '../components/PhoneMockup';

/*
 * SCENE 5 — OUTING BEGINS INSIDE THE CHAT (v3 — full cause-and-effect flow)
 *
 * 190 frames total
 *
 * Timeline:
 *   f  0–12 : Phone enters, same Weekend Plans chat visible (all msgs at full opacity)
 *   f 12–18 : Title "Start an outing right from the chat." fades in
 *   f 15–22 : + button press animation (scale down → bounce back)
 *   f 22–35 : Media/options menu slides up from bottom (exact Laween add_media reference)
 *   f 35–70 : Menu fully visible — Camera, Gallery, Location, Start Outing Session
 *   f 65–72 : "Start Outing Session" tap animation (scale press)
 *   f 72–84 : Menu slides back down / dark overlay fades out
 *   f 84–100: "Plan your way." title fades in   
 *   f 88–105: Bottom sheet slides up — Find Midpoint / Specific Place
 *   f 105–130: Find Midpoint highlighted (tap at f110)
 *   f 138–148: exitOp fades out entire scene
 */

const clamp = (v: number, lo = 0, hi = 1) => Math.max(lo, Math.min(hi, v));

import { WeekendChat } from '../components/WeekendChat';

/* ════════════════════════════════════════════════════════════════
 * ADD MEDIA MENU — exact Laween reference (add_media.jpeg)
 * White card, slides up from bottom, 3 icon rows + full-width CTA
 * ════════════════════════════════════════════════════════════════ */
const AddMediaMenu: React.FC<{ sheetY: number; tapScale: number }> = ({ sheetY, tapScale }) => (
  <div style={{
    position: 'absolute', bottom: 0, left: 0, right: 0,
    transform: `translateY(${sheetY}px)`,
    zIndex: 30,
  }}>
    {/* White rounded card */}
    <div style={{
      background: 'white',
      borderTopLeftRadius: 28, borderTopRightRadius: 28,
      paddingTop: 14, paddingBottom: 30, paddingLeft: 20, paddingRight: 20,
      boxShadow: '0 -12px 48px rgba(0,0,0,0.18)',
    }}>
      {/* Drag handle */}
      <div style={{ width: 40, height: 4, borderRadius: 2, background: '#e2e8f0', margin: '0 auto 18px' }} />

      {/* Camera row */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 16, paddingTop: 4, paddingBottom: 4, marginBottom: 4 }}>
        <div style={{ width: 52, height: 52, borderRadius: 26, background: 'rgba(0,109,119,0.12)', display: 'flex', justifyContent: 'center', alignItems: 'center', flexShrink: 0 }}>
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#006D77" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z" /><circle cx="12" cy="13" r="4" />
          </svg>
        </div>
        <span style={{ fontFamily: 'Outfit,system-ui,sans-serif', fontSize: 18, fontWeight: 600, color: '#2D3748', flex: 1 }}>Camera</span>
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#cbd5e1" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><path d="M9 18l6-6-6-6" /></svg>
      </div>

      {/* Divider */}
      <div style={{ height: 1, background: '#f1f5f9', marginBottom: 4 }} />

      {/* Gallery row */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 16, paddingTop: 4, paddingBottom: 4, marginBottom: 4 }}>
        <div style={{ width: 52, height: 52, borderRadius: 26, background: 'rgba(99,102,241,0.12)', display: 'flex', justifyContent: 'center', alignItems: 'center', flexShrink: 0 }}>
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#6366f1" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <rect x="3" y="3" width="18" height="18" rx="2" /><circle cx="8.5" cy="8.5" r="1.5" /><polyline points="21 15 16 10 5 21" />
          </svg>
        </div>
        <span style={{ fontFamily: 'Outfit,system-ui,sans-serif', fontSize: 18, fontWeight: 600, color: '#2D3748', flex: 1 }}>Gallery</span>
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#cbd5e1" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><path d="M9 18l6-6-6-6" /></svg>
      </div>

      {/* Divider */}
      <div style={{ height: 1, background: '#f1f5f9', marginBottom: 4 }} />

      {/* Location row */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 16, paddingTop: 4, paddingBottom: 4, marginBottom: 20 }}>
        <div style={{ width: 52, height: 52, borderRadius: 26, background: 'rgba(245,158,11,0.12)', display: 'flex', justifyContent: 'center', alignItems: 'center', flexShrink: 0 }}>
          <svg width="24" height="24" viewBox="0 0 24 24" fill="#f59e0b">
            <path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z" />
          </svg>
        </div>
        <span style={{ fontFamily: 'Outfit,system-ui,sans-serif', fontSize: 18, fontWeight: 600, color: '#2D3748', flex: 1 }}>Location</span>
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#cbd5e1" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><path d="M9 18l6-6-6-6" /></svg>
      </div>

      {/* Start Outing Session — full-width teal gradient button */}
      <div style={{
        background: 'linear-gradient(135deg, #83C5BE, #006D77)',
        borderRadius: 20,
        padding: '18px 24px',
        display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 12,
        boxShadow: '0 8px 24px rgba(0,109,119,0.35)',
        transform: `scale(${tapScale})`,
        cursor: 'pointer',
      }}>
        <svg width="20" height="20" viewBox="0 0 24 24" fill="white">
          <path d="M13 2L3 14h9l-1 8 10-12h-9l1-8z" />
        </svg>
        <span style={{ fontFamily: 'Outfit,system-ui,sans-serif', fontSize: 18, fontWeight: 800, color: 'white', letterSpacing: '-0.01em' }}>Start Outing Session</span>
      </div>
    </div>
  </div>
);

/* ════════════════════════════════════════════════════════════════
 * MAIN SCENE 5 — 190 frames
 * ════════════════════════════════════════════════════════════════ */
export const Scene5OutingBegins: React.FC = () => {
  const { fps } = useVideoConfig();
  const frame = useCurrentFrame();

  // ── Constants ──────────────────────────────────────────────
  const PLUS_PRESS   = 15;   // + button starts pressing
  const MENU_ENTER   = 22;   // menu starts sliding up
  const MENU_FULL    = 36;   // menu fully open
  const OUTING_TAP   = 65;   // Start Outing Session tap starts
  const MENU_EXIT    = 74;   // menu starts sliding out
  const MENU_GONE    = 88;   // menu fully gone
  const SHEET_ENTER  = 88;   // bottom sheet slides in
  const TOGGLE_BTN   = 118;  // toggle from Specific → Find Midpoint
  const FADE_OUT     = 198;  // scene fadeout start (extended from 190 to 210 total)
  const SCENE_END    = 210;

  // ── Locked Phone Position (Matches Scene2 exactly) ──
  const phoneY = 0;
  const floatY = 0;

  // ── Title crossfade ───────────────────────────────────────
  const prevTitleFade = clamp(interpolate(frame, [0, 8], [1, 0]));
  const titleOp   = clamp(interpolate(frame, [3, 14], [0, 1]));
  const title2Op  = clamp(interpolate(frame, [SHEET_ENTER + 2, SHEET_ENTER + 14], [0, 1]));
  const title2Fade = clamp(interpolate(frame, [FADE_OUT - 10, FADE_OUT], [1, 0]));

  // ── Exit ────────────────────────────────────────────────────
  const exitOp = clamp(interpolate(frame, [FADE_OUT, SCENE_END], [1, 0]));

  // ── + button press animation ────────────────────────────────
  // Presses down at PLUS_PRESS, bounces back by PLUS_PRESS+8
  const plusScale = frame < PLUS_PRESS ? 1
    : frame < PLUS_PRESS + 4  ? interpolate(frame, [PLUS_PRESS, PLUS_PRESS + 4], [1, 0.8])
    : frame < PLUS_PRESS + 8  ? interpolate(frame, [PLUS_PRESS + 4, PLUS_PRESS + 8], [0.8, 1.06])
    : frame < PLUS_PRESS + 11 ? interpolate(frame, [PLUS_PRESS + 8, PLUS_PRESS + 11], [1.06, 1.0])
    : 1.0;

  // ── + button glow flash ─────────────────────────────────────
  const plusGlow = clamp(interpolate(frame, [PLUS_PRESS + 2, PLUS_PRESS + 8, PLUS_PRESS + 16], [0, 1, 0]));

  // ── Chat shifts up when menu is open ───────────────────────
  const chatShift = clamp(interpolate(frame, [MENU_ENTER, MENU_FULL], [0, 28])) -
                    clamp(interpolate(frame, [MENU_EXIT, MENU_GONE], [0, 28]));

  // ── Menu slide-up ───────────────────────────────────────────
  const menuSpring = spring({ frame: frame - MENU_ENTER, fps, config: { damping: 14, stiffness: 160 } });
  const menuProgress = frame < MENU_ENTER ? 0
    : frame < MENU_EXIT ? Math.min(1, menuSpring)
    : clamp(interpolate(frame, [MENU_EXIT, MENU_GONE], [1, 0]));
  const menuSheetY = interpolate(menuProgress, [0, 1], [420, 0]);

  // Dark scrim behind menu
  const scrimOp = menuProgress * 0.45;

  // ── "Start Outing Session" tap ──────────────────────────────
  const outingTapScale = frame >= OUTING_TAP && frame < OUTING_TAP + 5
    ? interpolate(frame, [OUTING_TAP, OUTING_TAP + 2, OUTING_TAP + 5], [1, 0.93, 1], { extrapolateRight: 'clamp' })
    : 1;

  // ── Bottom sheet (Find Midpoint / Specific Place) ───────────
  const sheetSpring = spring({ frame: frame - SHEET_ENTER, fps, config: { damping: 14 } });
  const sheetY = frame < SHEET_ENTER ? 480 : interpolate(sheetSpring, [0, 1], [480, 0]);
  const sheetScrimOp = clamp(interpolate(frame, [SHEET_ENTER, SHEET_ENTER + 12], [0, 0.5])) *
                       clamp(interpolate(frame, [FADE_OUT - 10, FADE_OUT], [1, 0]));

  const isFirst = frame >= TOGGLE_BTN;
  const tapFirst  = (frame >= TOGGLE_BTN && frame < TOGGLE_BTN + 5)
    ? interpolate(frame, [TOGGLE_BTN, TOGGLE_BTN + 2, TOGGLE_BTN + 5], [1, 0.94, 1], { extrapolateRight: 'clamp' }) : 1;

  return (
    <AbsoluteFill style={{ backgroundColor: '#050714', overflow: 'hidden', opacity: exitOp }}>
      <div style={{ position: 'absolute', inset: 0, background: 'radial-gradient(ellipse at 50% 45%, rgba(0,109,119,0.07) 0%, transparent 55%)' }} />

      {/* ═══ TITLE 0: Fade out previous Scene 2 title ═══ */}
      <div style={{
        position: 'absolute', top: '5%', width: '100%', textAlign: 'center',
        padding: '0 48px',
        opacity: prevTitleFade,
        zIndex: 20,
      }}>
        <h1 style={{ fontFamily: 'Outfit,system-ui,sans-serif', fontSize: 64, fontWeight: 900, color: 'white', margin: 0, lineHeight: 1.15, letterSpacing: '-0.02em' }}>
          Everything your meetup needs
        </h1>
        <p style={{ fontFamily: 'Outfit,system-ui,sans-serif', fontSize: 30, color: '#83C5BE', fontWeight: 600, margin: '14px 0 0', letterSpacing: '-0.01em' }}>
          in one app.
        </p>
      </div>

      {/* ═══ TITLE 1: "Start an outing right from the chat." ═══ */}
      <div style={{
        position: 'absolute', top: '5%', width: '100%', textAlign: 'center',
        opacity: titleOp * clamp(interpolate(frame, [SHEET_ENTER - 8, SHEET_ENTER], [1, 0])),
        zIndex: 20,
      }}>
        <h1 style={{ fontFamily: 'Outfit,system-ui,sans-serif', fontSize: 64, fontWeight: 900, color: 'white', margin: 0, lineHeight: 1.15, letterSpacing: '-0.02em' }}>
          Start an outing from the chat.
        </h1>
        <p style={{ fontFamily: 'Outfit,system-ui,sans-serif', fontSize: 30, color: '#83C5BE', fontWeight: 600, margin: '14px 0 0' }}>
          One tap. Everyone's in.
        </p>
      </div>

      {/* ═══ TITLE 2: "Plan your way." ═══ */}
      <div style={{
        position: 'absolute', top: '5%', width: '100%', textAlign: 'center',
        opacity: title2Op * title2Fade, zIndex: 20,
      }}>
        <h1 style={{ fontFamily: 'Outfit,system-ui,sans-serif', fontSize: 64, fontWeight: 900, color: 'white', margin: 0, letterSpacing: '-0.02em', lineHeight: 1.15 }}>
          Plan your way.
        </h1>
        <p style={{ fontFamily: 'Outfit,system-ui,sans-serif', fontSize: 30, color: '#83C5BE', fontWeight: 600, margin: '14px 0 0' }}>
          Fair decisions, for the whole group.
        </p>
      </div>

      {/* ═══ PHONE — locked to exact Scene2 steady-state position, never fades ═══ */}
      <div style={{
        position: 'absolute', top: '50%', left: '50%',
        transform: 'translate(-50%,-50%) translateY(80px)',
      }}>
        <PhoneMockup scale={0.95} drift={false}>
          {/* Chat — shifts up when menu open */}
          <WeekendChat chatShift={chatShift} />

          {/* + button overlay for press animation */}
          <div style={{
            position: 'absolute',
            bottom: 28, left: 14,
            width: 38, height: 38, borderRadius: 19,
            backgroundColor: plusGlow > 0.01 ? `rgba(0,109,119,${0.18 * plusGlow})` : 'transparent',
            transform: `scale(${plusScale})`,
            zIndex: 25, pointerEvents: 'none',
            boxShadow: plusGlow > 0.01 ? `0 0 ${12 * plusGlow}px rgba(0,109,119,${0.55 * plusGlow})` : 'none',
          }} />

          {/* Dark scrim behind menu */}
          {scrimOp > 0.01 && (
            <div style={{ position: 'absolute', inset: 0, backgroundColor: 'rgba(0,0,0,0.45)', opacity: scrimOp / 0.45, zIndex: 28, pointerEvents: 'none' }} />
          )}

          {/* Add media / options menu */}
          {frame >= MENU_ENTER - 2 && frame < MENU_GONE + 4 && (
            <AddMediaMenu sheetY={menuSheetY} tapScale={outingTapScale} />
          )}

          {/* Bottom sheet — Find Midpoint / Specific Place (after menu gone) */}
          {frame >= SHEET_ENTER && (
            <>
              {/* Dark scrim */}
              <div style={{ position: 'absolute', inset: 0, backgroundColor: 'rgba(0,0,0,0.5)', opacity: sheetScrimOp / 0.5, zIndex: 28, pointerEvents: 'none' }} />
              <div style={{
                position: 'absolute', bottom: 0, left: 0, right: 0,
                backgroundColor: 'white',
                borderTopLeftRadius: 36, borderTopRightRadius: 36,
                padding: '36px 24px 44px',
                transform: `translateY(${sheetY}px)`,
                zIndex: 30, display: 'flex', flexDirection: 'column', alignItems: 'center',
              }}>
                <h2 style={{ fontFamily: 'Outfit,system-ui,sans-serif', fontSize: 24, fontWeight: 800, color: '#2D3748', margin: '0 0 8px' }}>Start Outing</h2>
                <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 14, color: 'grey', margin: '0 0 32px' }}>How would you like to plan today?</p>

                {/* Find Midpoint */}
                <div style={{
                  width: '100%', padding: '20px', borderRadius: 20,
                  display: 'flex', alignItems: 'center', gap: 20,
                  backgroundColor: isFirst ? 'rgba(0,109,119,0.1)' : 'white',
                  border: `1px solid ${isFirst ? 'rgba(0,109,119,0.2)' : 'rgba(0,109,119,0.2)'}`,
                  marginBottom: 16, transform: `scale(${tapFirst})`,
                  boxShadow: isFirst ? '0 4px 16px rgba(0,109,119,0.14)' : 'none',
                }}>
                  <div style={{ width: 48, height: 48, borderRadius: 24, backgroundColor: 'rgba(0,109,119,0.2)', display: 'flex', justifyContent: 'center', alignItems: 'center', flexShrink: 0 }}>
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="#006D77">
                      <path d="M12 2L13.5 8.5L20 10L13.5 11.5L12 18L10.5 11.5L4 10L10.5 8.5L12 2Z" />
                      <path d="M18 14L18.75 16.25L21 17L18.75 17.75L18 20L17.25 17.75L15 17L17.25 16.25L18 14Z" opacity="0.7" />
                    </svg>
                  </div>
                  <div style={{ flex: 1 }}>
                    <h3 style={{ fontFamily: 'Outfit,system-ui,sans-serif', fontSize: 18, fontWeight: 800, color: '#2D3748', margin: 0 }}>Find Midpoint</h3>
                    <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 13, color: '#64748b', margin: '2px 0 0' }}>The fairest spot for everyone</p>
                  </div>
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#006D77" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><path d="M9 18l6-6-6-6" /></svg>
                </div>

                {/* Specific Place */}
                <div style={{
                  width: '100%', padding: '20px', borderRadius: 20,
                  display: 'flex', alignItems: 'center', gap: 20,
                  backgroundColor: 'white', border: '1px solid rgba(245,158,11,0.2)',
                }}>
                  <div style={{ width: 48, height: 48, borderRadius: 24, backgroundColor: 'rgba(245,158,11,0.2)', display: 'flex', justifyContent: 'center', alignItems: 'center', flexShrink: 0 }}>
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="#f59e0b">
                      <path d="M12 2C8.13 2 5 5.13 5 9C5 14.25 12 22 12 22C12 22 19 14.25 19 9C19 5.13 15.87 2 12 2ZM12 11.5C10.62 11.5 9.5 10.38 9.5 9C9.5 7.62 10.62 6.5 12 6.5C13.38 6.5 14.5 7.62 14.5 9C14.5 10.38 13.38 11.5 12 11.5Z" />
                    </svg>
                  </div>
                  <div style={{ flex: 1 }}>
                    <h3 style={{ fontFamily: 'Outfit,system-ui,sans-serif', fontSize: 18, fontWeight: 800, color: '#2D3748', margin: 0 }}>Specific Place</h3>
                    <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 13, color: '#64748b', margin: '2px 0 0' }}>I know where we're going</p>
                  </div>
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#f59e0b" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><path d="M9 18l6-6-6-6" /></svg>
                </div>
              </div>
            </>
          )}

        </PhoneMockup>
      </div>
    </AbsoluteFill>
  );
};
