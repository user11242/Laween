import { Audio, staticFile, Sequence } from 'remotion';
import React from 'react';

/**
 * SoundLayer — Laween Promo Video · Premium Ad Mix
 *
 * Sound philosophy: music does the emotional work.
 * SFX are nearly invisible — only 4 categories:
 *   1. Ambient bed         (always, barely felt)
 *   2. Notifications       (only when phones light up)
 *   3. Signature chimes    (FaceID, timer, winner confirmed)
 *   4. Laween sting        (brand sound — end card only)
 *
 * 12 cues total.
 *
 *  AUDIO_ENABLED = false → silent, zero errors
 *  AUDIO_ENABLED = true  → full design active
 */
export const AUDIO_ENABLED = true;

// ─────────────────────────────────────────────────────────────────────────────
// Scene offsets (30 fps) — derived from Composition.tsx
//
// Durations: s1=270 s2=150 s3=210 s4=220 s5=210 s5bOpt=120 s6=210
//            s6b=240 s7=180 s8=270 s9=180 s10=210 s11=150 s12=120 s13=180
// ─────────────────────────────────────────────────────────────────────────────
const t1    = 0;
const t2    = t1 + 270;                         // 270  — FaceID
const t3    = t2 + 150;                         // 420  — Join Group
const t4    = t3 + 210;                         // 630  — Ecosystem Chat
const t5    = t4 + 220;                         // 850  — Outing Begins
const t5bOpt= t5 + 198;                         // 1048 — Options (overlap)
const t6    = t5bOpt + 120;                     // 1168 — Configure
const t6b   = t6 + 210;                         // 1378 — Responses (300 frames)
const t7    = t6b + 300;                        // 1678 — Waiting Room
const t8    = t7 + 180;                         // 1858 — Voting (270 frames)
const t9    = t8 + 270;                         // 2128 — Winner (180 frames)
const t10   = t9 + 180;                         // 2308 — Live Tracking
const t11   = t10 + 210;                        // 2518 — Lock Screen
const t12   = t11 + 150;                        // 2668 — Montage
const t13   = t12 + 120;                        // 2788 — End Card (180 frames)
const TOTAL = t13 + 180;                        // 2968

// ─────────────────────────────────────────────────────────────────────────────
// Sound map
// ─────────────────────────────────────────────────────────────────────────────
const SFX = {
  ambient:      'sounds/mine/ambient_5.mp3',      // emotional music bed
  chime:        'sounds/mine/warm_chime.wav',     // Cmaj7 — calm confirmation
  notif:        'sounds/mine/iphone_notif.wav',   // C6→G6 — clean iOS chime
  voteWin:      'sounds/mine/vote_win.mp3',       // winner peak
  laweenSting:  'sounds/mine/laween_sting.wav',   // brand sting — sweep→bell
  voiceover:    'sounds/voice_over.mp3',          // the spoken voiceover
};

// ─────────────────────────────────────────────────────────────────────────────
// Helper
// ─────────────────────────────────────────────────────────────────────────────
const Cue: React.FC<{
  at: number;
  src: string;
  volume?: number;
  durationFrames?: number;
}> = ({ at, src, volume = 0.10, durationFrames = 60 }) => (
  <Sequence from={at} durationInFrames={durationFrames}>
    <Audio src={staticFile(src)} volume={volume} />
  </Sequence>
);

// ─────────────────────────────────────────────────────────────────────────────
// Active sound layer
// ─────────────────────────────────────────────────────────────────────────────
const ActiveSoundLayer: React.FC = () => (
  <>
    {/* ── AMBIENT BED ─────────────────────────────────────────
     *  Lowered to 0.018 so voiceover sits clearly on top.
     * ───────────────────────────────────────────────────────── */}
    <Sequence from={0} durationInFrames={TOTAL}>
      <Audio
        src={staticFile(SFX.ambient)}
        volume={(f) => {
          if (f < 90)         return (f / 90) * 0.018;
          if (f > TOTAL - 60) return ((TOTAL - f) / 60) * 0.018;
          return 0.018;
        }}
      />
    </Sequence>

    {/* ── VOICEOVER ───────────────────────────────────────────
     *  Plays the audio continuously from start to finish.
     *  We do not slice the audio, because the generated MP3's
     *  natural pacing won't match hardcoded frame offsets.
     * ───────────────────────────────────────────────────────── */}
    <Sequence from={0} durationInFrames={TOTAL}>
      <Audio src={staticFile(SFX.voiceover)} volume={0.88} />
    </Sequence>

    {/* ── S2 — FACE ID VERIFIED  (t2=270) ─────────────────────
     *  First signature sound. Sets the tone: calm, trustworthy.
     * ───────────────────────────────────────────────────────── */}
    <Cue at={t2 + 100} src={SFX.chime}   volume={0.14} durationFrames={90} />

    {/* ── S6b — OUTING NOTIFICATIONS  (t6b=1378) ──────────────
     *  Three phones get the call. Staggered ~1s apart.
     *  Descending volume = one flowing moment, not 3 events.
     * ───────────────────────────────────────────────────────── */}
    <Cue at={t6b + 15} src={SFX.notif}   volume={0.14} durationFrames={60} />
    <Cue at={t6b + 50} src={SFX.notif}   volume={0.11} durationFrames={60} />
    <Cue at={t6b + 82} src={SFX.notif}   volume={0.09} durationFrames={60} />

    {/* ── S7 — TIMER COMPLETE  (t7=1618) ──────────────────────
     *  Everyone's in. One clean chime. Nothing else.
     * ───────────────────────────────────────────────────────── */}
    <Cue at={t7 + 150} src={SFX.chime}   volume={0.14} durationFrames={90} />

    {/* ── S8 — VOTE CLIMAX: 4/4  (t8=1858) ──────────────────────
     *  Fires exactly at frame 210 of S8 — the moment Oliva hits
     *  4/4 and the big winner badge bursts in. Intentional timing.
     * ───────────────────────────────────────────────────────── */}
    <Cue at={t8 + 210} src={SFX.voteWin}  volume={0.17} durationFrames={90} />

    {/* ── S9 — WINNER SETTLES  (t9=2128) ─────────────────────
     *  One quiet chime as the winner card breathes in.
     * ───────────────────────────────────────────────────────── */}
    <Cue at={t9 + 12}  src={SFX.chime}    volume={0.11} durationFrames={90} />

    {/* ── S10 — ARRIVALS  (t10=2248) ──────────────────────────
     *  Friends arriving at Oliva. Two soft notifications.
     * ───────────────────────────────────────────────────────── */}
    <Cue at={t10 + 45}  src={SFX.notif}  volume={0.11} durationFrames={60} />
    <Cue at={t10 + 104} src={SFX.notif}  volume={0.10} durationFrames={60} />

    {/* ── S11 — LOCK SCREEN  (t11=2458) ───────────────────────
     *  One notification on the lock screen. Unhurried.
     * ───────────────────────────────────────────────────────── */}
    <Cue at={t11 + 10}  src={SFX.notif}  volume={0.10} durationFrames={60} />

    {/* ── S13 — END CARD  (t13=2728) ──────────────────────────
     *  The Laween brand sting: a soft sine sweep that resolves
     *  into a warm D5/A5 bell tone. Designed specifically for
     *  this brand — airy, slightly magical, not generic.
     *  Then the ambient fades to silence. Done.
     * ───────────────────────────────────────────────────────── */}
    <Cue at={t13 + 18}  src={SFX.laweenSting} volume={0.16} durationFrames={120} />
  </>
);

export const SoundLayer: React.FC = () => {
  if (!AUDIO_ENABLED) return null;
  return <ActiveSoundLayer />;
};
