import { AbsoluteFill, interpolate, useCurrentFrame, useVideoConfig, spring } from 'remotion';
import React from 'react';
import { PhoneMockup } from '../components/PhoneMockup';

/*
 *  Scene 6 — LIVE ACTIVITY / DYNAMIC ISLAND
 *  Pixel-perfect recreation of live_tracker_notification.jpeg.
 *  Shows a lock screen with the Laween live activity widget at the bottom,
 *  featuring destination name, ETA times, progress bars for each participant.
 */
export const Scene6DynamicIsland: React.FC = () => {
  const { fps } = useVideoConfig();
  const frame = useCurrentFrame();

  // ── Title ──
  const titleSpring = spring({ frame: frame - 3, fps, config: { damping: 14 } });
  const titleY = interpolate(titleSpring, [0, 1], [50, 0]);
  const titleOp = interpolate(frame, [3, 14], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  // ── Phone entry ──
  const phoneStart = 8;
  const phoneSpring = spring({ frame: frame - phoneStart, fps, config: { damping: 13, mass: 1 } });
  const phoneY = interpolate(phoneSpring, [0, 1], [400, 0]);
  const phoneOp = interpolate(frame, [phoneStart, phoneStart + 12], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const floatY = Math.sin(frame * 0.06) * 4;

  // ── Widget slide up from bottom ──
  const widgetStart = 25;
  const widgetSpring = spring({ frame: frame - widgetStart, fps, config: { damping: 14 } });
  const widgetY = interpolate(widgetSpring, [0, 1], [200, 0]);
  const widgetOp = interpolate(widgetSpring, [0, 0.3], [0, 1]);

  // ── Progress bar animation ──
  const barProgress1 = interpolate(frame, [widgetStart + 10, widgetStart + 60], [0.3, 0.7], {
    extrapolateLeft: 'clamp', extrapolateRight: 'clamp',
  });
  const barProgress2 = interpolate(frame, [widgetStart + 10, widgetStart + 60], [0.4, 0.8], {
    extrapolateLeft: 'clamp', extrapolateRight: 'clamp',
  });

  // ── ETA countdown ──
  const eta1 = frame > widgetStart + 40 ? '10' : '13';
  const eta2 = frame > widgetStart + 40 ? '8' : '11';
  const dist1 = frame > widgetStart + 40 ? '5.8' : '7.4';
  const dist2 = frame > widgetStart + 40 ? '4.9' : '6.5';

  // ── Scene exit ──
  const exitStart = 78;
  const exitSpring = spring({ frame: frame - exitStart, fps, config: { damping: 12 } });
  const exitY = interpolate(exitSpring, [0, 1], [0, -800]);
  const exitOp = interpolate(exitSpring, [0, 0.5], [1, 0]);

  return (
    <AbsoluteFill style={{
      backgroundColor: '#050714',
      justifyContent: 'center',
      alignItems: 'center',
      transform: `translateY(${exitY}px)`,
      opacity: exitOp,
    }}>

      {/* Ambient glow */}
      <div style={{
        position: 'absolute', width: '100%', height: '100%',
        background: 'radial-gradient(ellipse at 50% 60%, rgba(20,184,166,0.12) 0%, transparent 60%)',
      }} />

      {/* Title */}
      <div style={{
        position: 'absolute', top: '6%',
        display: 'flex', flexDirection: 'column', alignItems: 'center',
        transform: `translateY(${titleY}px)`, opacity: titleOp,
      }}>
        <h1 style={{
          fontFamily: 'Inter, sans-serif', fontSize: 78, fontWeight: 900, color: 'white',
          margin: 0, letterSpacing: '-0.03em',
          textShadow: '0 8px 40px rgba(20,184,166,0.45)',
        }}>
          Always in the Loop
        </h1>
        <p style={{
          fontFamily: 'Inter, sans-serif', fontSize: 26, color: '#5eead4', fontWeight: 600,
          margin: '14px 0 0 0', letterSpacing: '0.02em',
          opacity: interpolate(frame, [10, 22], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' }),
        }}>
          Live ETA right from your lock screen
        </p>
      </div>

      {/* Phone */}
      <div style={{
        transform: `translateY(${phoneY + floatY}px)`,
        opacity: phoneOp,
        marginTop: 40,
      }}>
        <PhoneMockup>
          {/* Lock screen background — dark gradient simulating a wallpaper */}
          <div style={{
            position: 'absolute', inset: 0,
            background: 'linear-gradient(180deg, #1a1a2e 0%, #16213e 40%, #0f3460 100%)',
          }}>
            {/* Lock screen time */}
            <div style={{
              position: 'absolute', top: 70, width: '100%', textAlign: 'center',
            }}>
              <p style={{ fontFamily: 'Inter', fontSize: 16, color: 'rgba(255,255,255,0.7)', margin: '0 0 4px', fontWeight: 500 }}>
                Sun 12 Apr
              </p>
              <h2 style={{
                fontFamily: 'Inter', fontSize: 80, fontWeight: 200,
                color: 'rgba(255,255,255,0.9)', margin: 0, letterSpacing: '0.02em',
              }}>
                4:29
              </h2>
            </div>
          </div>

          {/* ── Laween Live Activity Widget (matches live_tracker_notification.jpeg) ── */}
          <div style={{
            position: 'absolute', bottom: 80, left: 12, right: 12,
            background: 'linear-gradient(135deg, #1a9b94, #0d8480)',
            borderRadius: 22,
            padding: '18px 18px 20px',
            transform: `translateY(${widgetY}px)`,
            opacity: widgetOp,
            boxShadow: '0 20px 50px rgba(0,0,0,0.5), 0 0 0 1px rgba(255,255,255,0.1)',
          }}>
            {/* Header row: App Icon + Restaurant name + ETA */}
            <div style={{ display: 'flex', alignItems: 'center', marginBottom: 14 }}>
              {/* App icon */}
              <div style={{
                width: 42, height: 42, borderRadius: 10,
                background: 'white',
                display: 'flex', justifyContent: 'center', alignItems: 'center',
                marginRight: 12,
                boxShadow: '0 4px 12px rgba(0,0,0,0.2)',
              }}>
                <span style={{ fontSize: 24 }}>📍</span>
              </div>
              <div style={{ flex: 1 }}>
                <p style={{ fontFamily: 'Inter', fontSize: 17, fontWeight: 800, color: 'white', margin: 0 }}>
                  The Cap soul Restaurant a...
                </p>
                <p style={{ fontFamily: 'Inter', fontSize: 14, fontWeight: 600, color: 'rgba(255,255,255,0.7)', margin: '2px 0 0' }}>
                  Arriving in {eta1} min
                </p>
              </div>
            </div>

            {/* ── Participant 1: You ── */}
            <div style={{ marginBottom: 10 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 6 }}>
                <span style={{ fontFamily: 'Inter', fontSize: 15, fontWeight: 700, color: 'white' }}>You</span>
                <span style={{ fontFamily: 'Inter', fontSize: 13, fontWeight: 600, color: 'rgba(255,255,255,0.75)' }}>
                  {eta1}m · {dist1} km
                </span>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <div style={{
                  width: 26, height: 26, borderRadius: 13,
                  background: 'rgba(255,255,255,0.2)',
                  display: 'flex', justifyContent: 'center', alignItems: 'center',
                  fontFamily: 'Inter', fontSize: 12, fontWeight: 800, color: 'white',
                }}>U</div>
                <div style={{ flex: 1, height: 8, background: 'rgba(255,255,255,0.15)', borderRadius: 4, overflow: 'hidden' }}>
                  <div style={{
                    width: `${barProgress1 * 100}%`, height: '100%',
                    background: 'linear-gradient(90deg, rgba(255,255,255,0.5), rgba(255,255,255,0.8))',
                    borderRadius: 4,
                  }} />
                </div>
              </div>
            </div>

            {/* ── Participant 2: Yazan Qattous ── */}
            <div>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 6 }}>
                <span style={{ fontFamily: 'Inter', fontSize: 15, fontWeight: 700, color: 'white' }}>Yazan Qattous</span>
                <span style={{ fontFamily: 'Inter', fontSize: 13, fontWeight: 600, color: 'rgba(255,255,255,0.75)' }}>
                  {eta2}m · {dist2} km
                </span>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <div style={{
                  width: 26, height: 26, borderRadius: 13,
                  background: 'rgba(255,255,255,0.2)',
                  display: 'flex', justifyContent: 'center', alignItems: 'center',
                  fontFamily: 'Inter', fontSize: 12, fontWeight: 800, color: 'white',
                }}>Y</div>
                <div style={{ flex: 1, height: 8, background: 'rgba(255,255,255,0.15)', borderRadius: 4, overflow: 'hidden' }}>
                  <div style={{
                    width: `${barProgress2 * 100}%`, height: '100%',
                    background: 'linear-gradient(90deg, rgba(255,255,255,0.5), rgba(255,255,255,0.8))',
                    borderRadius: 4,
                  }} />
                </div>
              </div>
            </div>
          </div>

          {/* Lock screen bottom buttons (flashlight & camera) */}
          <div style={{
            position: 'absolute', bottom: 20, left: 0, right: 0,
            display: 'flex', justifyContent: 'space-between', padding: '0 30px',
          }}>
            <div style={{ width: 48, height: 48, borderRadius: 24, background: 'rgba(255,255,255,0.15)', backdropFilter: 'blur(10px)' }} />
            <div style={{ width: 48, height: 48, borderRadius: 24, background: 'rgba(255,255,255,0.15)', backdropFilter: 'blur(10px)' }} />
          </div>
        </PhoneMockup>
      </div>
    </AbsoluteFill>
  );
};
