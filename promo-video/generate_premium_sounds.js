/**
 * generate_premium_sounds.js
 * Synthesizes a set of soft, musical UI sounds for the Laween promo video.
 * Outputs to public/sounds/mine/ alongside the user's real assets.
 *
 * Philosophy:
 *  - Every sound is musical (pitched, not noisy)
 *  - Fast attack, smooth exponential decay
 *  - No harsh transients
 *  - Each file is padded to ≥1s to prevent Remotion Studio waveform crashes
 */

const fs = require('fs');
const path = require('path');
const SR = 44100;

function writeWav(filename, samples) {
  const len = Math.max(SR, samples.length); // always ≥ 1 second
  const buf = Buffer.alloc(44 + len * 2);
  buf.write('RIFF', 0);
  buf.writeUInt32LE(36 + len * 2, 4);
  buf.write('WAVE', 8);
  buf.write('fmt ', 12);
  buf.writeUInt32LE(16, 16);
  buf.writeUInt16LE(1, 20);   // PCM
  buf.writeUInt16LE(1, 22);   // mono
  buf.writeUInt32LE(SR, 24);
  buf.writeUInt32LE(SR * 2, 28);
  buf.writeUInt16LE(2, 32);
  buf.writeUInt16LE(16, 34);
  buf.write('data', 36);
  buf.writeUInt32LE(len * 2, 40);
  for (let i = 0; i < len; i++) {
    const s = i < samples.length ? Math.max(-1, Math.min(1, samples[i])) : 0;
    buf.writeInt16LE(Math.round(s * 32767), 44 + i * 2);
  }
  const out = path.join(__dirname, 'public', 'sounds', 'mine', filename);
  fs.writeFileSync(out, buf);
  console.log(`✓ ${filename}`);
}

// ─────────────────────────────────────────────────────────
// 1. soft_pop.wav
//    A gentle musical "bloop" — triangle wave at 560 Hz,
//    5ms attack, exponential decay over ~120ms.
//    Used for: message bubbles, card appearances, friend joins.
// ─────────────────────────────────────────────────────────
{
  const dur = 0.14;
  const freq = 560;
  const s = new Float32Array(Math.round(SR * dur));
  for (let i = 0; i < s.length; i++) {
    const t = i / SR;
    // Triangle wave (softer harmonics than sine, less buzzy than square)
    const phase = (freq * t) % 1;
    const tri = phase < 0.5 ? (4 * phase - 1) : (3 - 4 * phase);
    const attack = Math.min(1, t / 0.005);         // 5ms attack
    const decay  = Math.exp(-t * 16);              // ~120ms decay
    s[i] = tri * 0.38 * attack * decay;
  }
  writeWav('soft_pop.wav', s);
}

// ─────────────────────────────────────────────────────────
// 2. airy_swoosh.wav
//    A whisper of air — low-pass filtered white noise
//    shaped with a half-sine envelope over 200ms.
//    Used for: bottom sheet slides, scene transitions.
// ─────────────────────────────────────────────────────────
{
  const dur = 0.22;
  const s = new Float32Array(Math.round(SR * dur));
  let lp = 0;
  for (let i = 0; i < s.length; i++) {
    const t = i / SR;
    const noise = Math.random() * 2 - 1;
    // Simple one-pole low-pass filter (α ≈ 0.12)
    lp = 0.12 * noise + 0.88 * lp;
    // Half-sine envelope: rises then falls
    const env = Math.sin(Math.PI * (t / dur));
    s[i] = lp * 0.55 * env;
  }
  writeWav('airy_swoosh.wav', s);
}

// ─────────────────────────────────────────────────────────
// 3. warm_chime.wav
//    A Cmaj7 chord in pure sines — C5 E5 G5 B5.
//    Gentle 15ms attack, slow 2.2s decay.
//    Used for: Face ID verified, launch confirmed, timer done.
// ─────────────────────────────────────────────────────────
{
  const dur = 2.0;
  const freqs = [523.25, 659.25, 783.99, 987.77]; // C5 E5 G5 B5
  const amps  = [0.38,   0.28,   0.22,   0.14];
  const s = new Float32Array(Math.round(SR * dur));
  for (let i = 0; i < s.length; i++) {
    const t = i / SR;
    const attack = Math.min(1, t / 0.015);         // 15ms attack
    const decay  = Math.exp(-t * 2.2);             // 2.2s decay constant
    let sample = 0;
    freqs.forEach((f, idx) => {
      sample += Math.sin(2 * Math.PI * f * t) * amps[idx];
    });
    s[i] = sample * attack * decay * 0.30;
  }
  writeWav('warm_chime.wav', s);
}

// ─────────────────────────────────────────────────────────
// 4. soft_click.wav
//    A barely-there toggle click — very short noise burst
//    + a 180Hz body thump, 20ms total.
//    Used for: KM/Time toggles, card selection toggles.
// ─────────────────────────────────────────────────────────
{
  const dur = 0.022;
  const s = new Float32Array(Math.round(SR * dur));
  for (let i = 0; i < s.length; i++) {
    const t = i / SR;
    const env   = Math.exp(-t * 220);
    const thump = Math.sin(2 * Math.PI * 180 * t) * 0.65;
    const noise = (Math.random() * 2 - 1) * 0.25;
    s[i] = (thump + noise) * env * 0.42;
  }
  writeWav('soft_click.wav', s);
}

// ─────────────────────────────────────────────────────────
// 5. soft_tap.wav
//    A clean button tap — sine wave at 320Hz, 30ms,
//    slightly slower decay than click, more "press" feel.
//    Used for: button taps, card taps, FAB press.
// ─────────────────────────────────────────────────────────
{
  const dur = 0.035;
  const s = new Float32Array(Math.round(SR * dur));
  for (let i = 0; i < s.length; i++) {
    const t = i / SR;
    const env  = Math.exp(-t * 120);
    const body = Math.sin(2 * Math.PI * 320 * t);
    const snap = (Math.random() * 2 - 1) * Math.exp(-t * 600) * 0.2;
    s[i] = (body * 0.7 + snap) * env * 0.40;
  }
  writeWav('soft_tap.wav', s);
}

// ─────────────────────────────────────────────────────────
// 6. soft_notification.wav
//    Two ascending musical tones (D5 → F#5),
//    gentle and iOS-like, 350ms each, overlapping slightly.
//    Used for: notification drop-ins.
// ─────────────────────────────────────────────────────────
{
  const dur = 0.65;
  const s = new Float32Array(Math.round(SR * dur));
  for (let i = 0; i < s.length; i++) {
    const t = i / SR;
    // First tone: D5 = 587Hz, starts at 0
    const env1 = Math.exp(-Math.max(0, t) * 9);
    const t1   = Math.sin(2 * Math.PI * 587 * t) * env1 * (t < 0.35 ? 1 : 0);
    // Second tone: F#5 = 740Hz, starts at 0.25s with slight overlap
    const env2 = t > 0.25 ? Math.exp(-(t - 0.25) * 9) : 0;
    const t2   = Math.sin(2 * Math.PI * 740 * t) * env2;
    s[i] = (t1 + t2) * 0.30;
  }
  writeWav('soft_notification.wav', s);
}

console.log('\nAll premium sounds generated in public/sounds/mine/');
