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

/* ════════════════════════════════════════════════════════════════
 * WEEKEND PLANS CHAT (fully visible — continuation from Scene2)
 * No entry animations — all messages already sent
 * chatShift: when menu is open the chat slides up slightly
 * ════════════════════════════════════════════════════════════════ */
const WeekendChat: React.FC<{ chatShift: number }> = ({ chatShift }) => (
  <div style={{ position: 'absolute', inset: 0, backgroundColor: '#f6f7f9', display: 'flex', flexDirection: 'column', transform: `translateY(${-chatShift}px)` }}>
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

    {/* Messages — all fully visible, no entry animations */}
    <div style={{ flex: 1, padding: '12px 14px 8px', display: 'flex', flexDirection: 'column', gap: 10, overflow: 'hidden' }}>
      {/* Ahmed */}
      <div style={{ display: 'flex', alignItems: 'flex-end', gap: 8 }}>
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
      {/* User */}
      <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
        <div style={{ background: '#0d7975', borderRadius: '16px 16px 4px 16px', padding: '9px 13px', boxShadow: '0 2px 8px rgba(13,121,117,0.2)', maxWidth: 210 }}>
          <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 15, color: 'white', margin: 0, lineHeight: 1.4 }}>I'm down! Where should we meet? 🙌</p>
        </div>
      </div>
      {/* Sarah */}
      <div style={{ display: 'flex', alignItems: 'flex-end', gap: 8 }}>
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
      {/* Ahmed photo — matches Scene2Ecosystem exactly */}
      <div style={{ display: 'flex', alignItems: 'flex-end', gap: 8 }}>
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
      {/* Location card — matches Scene2Ecosystem exactly */}
      <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
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
      {/* + button — scale animated externally via chatShift context */}
      <div id="scene5-plus-btn" style={{ width: 38, height: 38, borderRadius: 19, backgroundColor: '#f1f5f9', display: 'flex', justifyContent: 'center', alignItems: 'center', flexShrink: 0 }}>
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#64748b" strokeWidth="2.5" strokeLinecap="round"><line x1="12" y1="5" x2="12" y2="19" /><line x1="5" y1="12" x2="19" y2="12" /></svg>
      </div>
      <div style={{ flex: 1, height: 38, borderRadius: 19, border: '1.5px solid #e2e8f0', display: 'flex', alignItems: 'center', paddingLeft: 14, background: '#fafafa' }}>
        <span style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 14, color: '#94a3b8' }}>Type a message...</span>
      </div>
      <div style={{ width: 38, height: 38, borderRadius: 19, backgroundColor: '#0d7975', display: 'flex', justifyContent: 'center', alignItems: 'center', flexShrink: 0 }}>
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" style={{ transform: 'rotate(45deg)', marginLeft: -2 }}>
          <line x1="22" y1="2" x2="11" y2="13" /><polygon points="22 2 15 22 11 13 2 9 22 2" />
        </svg>
      </div>
    </div>
  </div>
);

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
      <div style={{ display: 'flex', alignItems: 'center', gap: 16, paddingVertical: 4, marginBottom: 4 }}>
        <div style={{ width: 52, height: 52, borderRadius: 26, background: 'rgba(13,121,117,0.12)', display: 'flex', justifyContent: 'center', alignItems: 'center', flexShrink: 0 }}>
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#0d7975" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z" /><circle cx="12" cy="13" r="4" />
          </svg>
        </div>
        <span style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 18, fontWeight: 600, color: '#1e293b', flex: 1 }}>Camera</span>
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#cbd5e1" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><path d="M9 18l6-6-6-6" /></svg>
      </div>

      {/* Divider */}
      <div style={{ height: 1, background: '#f1f5f9', marginBottom: 4 }} />

      {/* Gallery row */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 16, paddingVertical: 4, marginBottom: 4 }}>
        <div style={{ width: 52, height: 52, borderRadius: 26, background: 'rgba(99,102,241,0.12)', display: 'flex', justifyContent: 'center', alignItems: 'center', flexShrink: 0 }}>
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#6366f1" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <rect x="3" y="3" width="18" height="18" rx="2" /><circle cx="8.5" cy="8.5" r="1.5" /><polyline points="21 15 16 10 5 21" />
          </svg>
        </div>
        <span style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 18, fontWeight: 600, color: '#1e293b', flex: 1 }}>Gallery</span>
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#cbd5e1" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><path d="M9 18l6-6-6-6" /></svg>
      </div>

      {/* Divider */}
      <div style={{ height: 1, background: '#f1f5f9', marginBottom: 4 }} />

      {/* Location row */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 16, paddingVertical: 4, marginBottom: 20 }}>
        <div style={{ width: 52, height: 52, borderRadius: 26, background: 'rgba(245,158,11,0.12)', display: 'flex', justifyContent: 'center', alignItems: 'center', flexShrink: 0 }}>
          <svg width="24" height="24" viewBox="0 0 24 24" fill="#f59e0b">
            <path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z" />
          </svg>
        </div>
        <span style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 18, fontWeight: 600, color: '#1e293b', flex: 1 }}>Location</span>
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#cbd5e1" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><path d="M9 18l6-6-6-6" /></svg>
      </div>

      {/* Start Outing Session — full-width teal gradient button */}
      <div style={{
        background: 'linear-gradient(135deg, #0e8a86, #0d7975)',
        borderRadius: 18,
        padding: '18px 24px',
        display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 12,
        boxShadow: '0 8px 24px rgba(13,121,117,0.35)',
        transform: `scale(${tapScale})`,
        cursor: 'pointer',
      }}>
        <svg width="22" height="22" viewBox="0 0 24 24" fill="white">
          <path d="M13 2L3 14h9l-1 8 10-12h-9l1-8z" />
        </svg>
        <span style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 19, fontWeight: 800, color: 'white', letterSpacing: '-0.01em' }}>Start Outing Session</span>
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
      <div style={{ position: 'absolute', inset: 0, background: 'radial-gradient(ellipse at 50% 45%, rgba(20,184,166,0.07) 0%, transparent 55%)' }} />

      {/* ═══ TITLE 0: Fade out previous Scene 2 title ═══ */}
      <div style={{
        position: 'absolute', top: '5%', width: '100%', textAlign: 'center',
        padding: '0 48px',
        opacity: prevTitleFade,
        zIndex: 20,
      }}>
        <h1 style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 64, fontWeight: 900, color: 'white', margin: 0, lineHeight: 1.15, letterSpacing: '-0.02em' }}>
          Everything your meetup needs
        </h1>
        <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 30, color: '#5eead4', fontWeight: 600, margin: '14px 0 0', letterSpacing: '-0.01em' }}>
          in one app.
        </p>
      </div>

      {/* ═══ TITLE 1: "Start an outing right from the chat." ═══ */}
      <div style={{
        position: 'absolute', top: '5%', width: '100%', textAlign: 'center',
        opacity: titleOp * clamp(interpolate(frame, [SHEET_ENTER - 8, SHEET_ENTER], [1, 0])),
        zIndex: 20,
      }}>
        <h1 style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 64, fontWeight: 900, color: 'white', margin: 0, lineHeight: 1.15, letterSpacing: '-0.02em' }}>
          Start an outing right from chat.
        </h1>
        <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 30, color: '#5eead4', fontWeight: 600, margin: '14px 0 0' }}>
          One tap. Everyone's in.
        </p>
      </div>

      {/* ═══ TITLE 2: "Plan your way." ═══ */}
      <div style={{
        position: 'absolute', top: '5%', width: '100%', textAlign: 'center',
        opacity: title2Op * title2Fade, zIndex: 20,
      }}>
        <h1 style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 64, fontWeight: 900, color: 'white', margin: 0, letterSpacing: '-0.02em', lineHeight: 1.15 }}>
          Plan your way.
        </h1>
        <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 30, color: '#5eead4', fontWeight: 600, margin: '14px 0 0' }}>
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
            backgroundColor: plusGlow > 0.01 ? `rgba(13,121,117,${0.18 * plusGlow})` : 'transparent',
            transform: `scale(${plusScale})`,
            zIndex: 25, pointerEvents: 'none',
            boxShadow: plusGlow > 0.01 ? `0 0 ${12 * plusGlow}px rgba(13,121,117,${0.55 * plusGlow})` : 'none',
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
                <h2 style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 26, fontWeight: 800, color: '#2e374d', margin: '0 0 6px' }}>Start Outing</h2>
                <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 15, color: '#94a3b8', margin: '0 0 28px' }}>How would you like to plan today?</p>

                {/* Find Midpoint */}
                <div style={{
                  width: '100%', padding: '18px', borderRadius: 20,
                  display: 'flex', alignItems: 'center', gap: 16,
                  backgroundColor: isFirst ? '#f1f8f8' : '#fafafa',
                  border: `2px solid ${isFirst ? 'rgba(13,121,117,0.25)' : 'rgba(0,0,0,0.05)'}`,
                  marginBottom: 14, transform: `scale(${tapFirst})`,
                  boxShadow: isFirst ? '0 4px 16px rgba(13,121,117,0.14)' : 'none',
                }}>
                  <div style={{ width: 52, height: 52, borderRadius: 26, backgroundColor: '#cbece9', display: 'flex', justifyContent: 'center', alignItems: 'center', flexShrink: 0 }}>
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="#0d7975">
                      <path d="M12 2L13.5 8.5L20 10L13.5 11.5L12 18L10.5 11.5L4 10L10.5 8.5L12 2Z" />
                      <path d="M18 14L18.75 16.25L21 17L18.75 17.75L18 20L17.25 17.75L15 17L17.25 16.25L18 14Z" opacity="0.7" />
                    </svg>
                  </div>
                  <div style={{ flex: 1 }}>
                    <h3 style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 18, fontWeight: 800, color: '#1e293b', margin: 0 }}>Find Midpoint</h3>
                    <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 13, color: '#64748b', margin: '2px 0 0' }}>The fairest spot for everyone</p>
                  </div>
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#0d7975" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><path d="M9 18l6-6-6-6" /></svg>
                </div>

                {/* Specific Place */}
                <div style={{
                  width: '100%', padding: '18px', borderRadius: 20,
                  display: 'flex', alignItems: 'center', gap: 16,
                  backgroundColor: '#fff9f0', border: '2px solid rgba(245,158,11,0.12)',
                }}>
                  <div style={{ width: 52, height: 52, borderRadius: 26, backgroundColor: '#fde6cd', display: 'flex', justifyContent: 'center', alignItems: 'center', flexShrink: 0 }}>
                    <svg width="22" height="22" viewBox="0 0 24 24" fill="#d97706">
                      <path d="M12 2C8.13 2 5 5.13 5 9C5 14.25 12 22 12 22C12 22 19 14.25 19 9C19 5.13 15.87 2 12 2ZM12 11.5C10.62 11.5 9.5 10.38 9.5 9C9.5 7.62 10.62 6.5 12 6.5C13.38 6.5 14.5 7.62 14.5 9C14.5 10.38 13.38 11.5 12 11.5Z" />
                    </svg>
                  </div>
                  <div style={{ flex: 1 }}>
                    <h3 style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 18, fontWeight: 800, color: '#1e293b', margin: 0 }}>Specific Place</h3>
                    <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 13, color: '#64748b', margin: '2px 0 0' }}>I know where we're going</p>
                  </div>
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#f59e0b" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><path d="M9 18l6-6-6-6" /></svg>
                </div>
              </div>
            </>
          )}

        </PhoneMockup>
      </div>
    </AbsoluteFill>
  );
};
