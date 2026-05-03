# Sound Design Assets — Laween Promo Video

## Activation

1. Place all `.mp3` files listed below into this `public/sounds/` directory.
2. Open `src/components/SoundLayer.tsx`.
3. Change line 17 from:
   ```ts
   export const AUDIO_ENABLED = false;
   ```
   to:
   ```ts
   export const AUDIO_ENABLED = true;
   ```
4. The full sound design activates immediately.

---

## Required Files (exact filenames)

| Filename | Description | Recommended Duration |
|---|---|---|
| `ambient_track.mp3` | Background music bed — soft, optimistic, light electronic | 3–5 min |
| `ui_pop.mp3` | Message pop, card appear, button tap, friend joined | 60–100ms |
| `swoosh_soft.mp3` | Transition whoosh, bottom sheet slide-up, scene movement | 100–200ms |
| `scan_pulse.mp3` | Biometric / Face ID scan loop | 400–800ms |
| `confirm_chime.mp3` | Verified, launch confirmed, selection chime | 200–400ms |
| `notification.mp3` | iOS-style notification drop-in | 150–250ms |
| `vote_win.mp3` | Elegant winner reveal / Oliva 4/4 chime | 500–800ms |
| `map_pulse.mp3` | Location pin pulse, tracking movement, arrival | 150–250ms |

> **Note:** If `map_pulse.mp3` is unavailable, you can rename a copy of `ui_pop.mp3` or `swoosh_soft.mp3` to `map_pulse.mp3`.

---

## Volume Mix (pre-set in SoundLayer.tsx)

| Category | Volume Range |
|---|---|
| Background music | 0.05–0.10 |
| UI pops / taps | 0.10–0.16 |
| Swooshes | 0.08–0.15 |
| Notifications | 0.15–0.20 |
| Confirm chimes | 0.16–0.22 |
| Winner / vote chime | 0.22–0.30 |

---

## Recommended Free Sources

- **Mixkit.co** — `mixkit.co/free-sound-effects/` (no attribution required)
- **Freesound.org** — Filters: UI sounds, chime, notification, whoosh
- **ZapSplat.com** — High-quality UI / app sounds (free with account)
- **Pixabay.com** — Free music + SFX, no attribution required

---

## Safety

The video renders normally **with or without** audio files.
When `AUDIO_ENABLED = false`, zero `<Audio>` elements are rendered — no warnings, no missing-file errors.
