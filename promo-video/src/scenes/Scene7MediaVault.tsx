import { AbsoluteFill, interpolate, useCurrentFrame, useVideoConfig, spring, Img, staticFile } from 'remotion';
import React from 'react';
import { PhoneMockup } from '../components/PhoneMockup';

/*
 *  Scene 7 — MEDIA VAULT + BRAND CLOSE
 *  Phase 1: Shows add_media.jpeg (Camera/Gallery/Location/Start Outing Session)
 *           inside a floating phone mockup.
 *  Phase 2: Cinematic brand close — Logo, Wordmark, Tagline.
 */
export const Scene7MediaVault: React.FC = () => {
  const { fps } = useVideoConfig();
  const frame = useCurrentFrame();

  // ══════════ PHASE 1: MEDIA VAULT ══════════
  const titleSpring = spring({ frame: frame - 3, fps, config: { damping: 14 } });
  const titleY = interpolate(titleSpring, [0, 1], [50, 0]);
  const titleOp = interpolate(frame, [3, 14], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const titleFadeOut = interpolate(frame, [80, 95], [1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  // Phone entry
  const phoneStart = 10;
  const phoneSpring = spring({ frame: frame - phoneStart, fps, config: { damping: 14 } });
  const phoneY = interpolate(phoneSpring, [0, 1], [600, 0]);
  const phoneOp = interpolate(frame, [phoneStart, phoneStart + 12], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const floatY = Math.sin(frame * 0.06) * 4;

  // Phase 1 → Phase 2 transition
  const transStart = 95;
  const transSpring = spring({ frame: frame - transStart, fps, config: { damping: 14 } });
  const phase1Scale = interpolate(transSpring, [0, 1], [1, 1.5]);
  const phase1Blur = interpolate(transSpring, [0, 1], [0, 25]);
  const phase1Op = interpolate(transSpring, [0, 0.8], [1, 0]);

  // ══════════ PHASE 2: BRAND CLOSE ══════════
  const brandStart = 115;

  // Logo
  const logoSpring = spring({ frame: frame - brandStart, fps, config: { damping: 12 } });
  const logoScale = interpolate(logoSpring, [0, 1], [0.5, 1]);
  const logoOp = interpolate(frame, [brandStart, brandStart + 15], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  // Wordmark
  const wordStart = brandStart + 12;
  const wordSpring = spring({ frame: frame - wordStart, fps, config: { damping: 14 } });
  const wordY = interpolate(wordSpring, [0, 1], [30, 0]);
  const wordOp = interpolate(frame, [wordStart, wordStart + 15], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  // Tagline
  const tagStart = wordStart + 10;
  const tagSpring = spring({ frame: frame - tagStart, fps, config: { damping: 16 } });
  const tagY = interpolate(tagSpring, [0, 1], [20, 0]);
  const tagOp = interpolate(frame, [tagStart, tagStart + 15], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  // Subtle glow pulse behind logo
  const glowScale = 1 + Math.sin(frame * 0.04) * 0.05;

  return (
    <AbsoluteFill style={{ backgroundColor: '#050714' }}>

      {/* ═══ PHASE 1 ═══ */}
      <AbsoluteFill style={{
        justifyContent: 'center',
        alignItems: 'center',
        transform: `scale(${phase1Scale})`,
        filter: `blur(${phase1Blur}px)`,
        opacity: phase1Op,
        pointerEvents: 'none',
      }}>
        {/* Glow */}
        <div style={{
          position: 'absolute', width: '120%', height: '120%',
          background: 'radial-gradient(ellipse at 50% 40%, rgba(16,185,129,0.12) 0%, transparent 55%)',
        }} />

        {/* Title */}
        <div style={{
          position: 'absolute', top: '8%',
          display: 'flex', flexDirection: 'column', alignItems: 'center',
          transform: `translateY(${titleY}px)`, opacity: titleOp * titleFadeOut,
        }}>
          <h1 style={{
            fontFamily: 'Inter, sans-serif', fontSize: 78, fontWeight: 900, color: 'white',
            margin: 0, letterSpacing: '-0.03em',
            textShadow: '0 8px 40px rgba(16,185,129,0.45)',
          }}>
            Share Everything
          </h1>
          <p style={{
            fontFamily: 'Inter, sans-serif', fontSize: 26, color: '#6ee7b7', fontWeight: 600,
            margin: '14px 0 0 0', letterSpacing: '0.02em',
            opacity: interpolate(frame, [10, 22], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' }),
          }}>
            Photos · Location · Outing Sessions
          </p>
        </div>

        {/* Phone with add_media screenshot */}
        <div style={{
          transform: `translateY(${phoneY + floatY}px)`,
          opacity: phoneOp,
          marginTop: 60,
        }}>
          <PhoneMockup>
            <Img
              src={staticFile('add_media.jpeg')}
              style={{ width: '100%', height: '100%', objectFit: 'cover', objectPosition: 'top' }}
            />
          </PhoneMockup>
        </div>
      </AbsoluteFill>

      {/* ═══ PHASE 2: BRAND CLOSE ═══ */}
      <AbsoluteFill style={{
        justifyContent: 'center',
        alignItems: 'center',
        opacity: frame > brandStart - 15 ? 1 : 0,
        pointerEvents: 'none',
      }}>
        {/* Multiple ambient glow layers */}
        <div style={{
          position: 'absolute', width: '100%', height: '100%',
          background: 'radial-gradient(circle at center, rgba(20,184,166,0.12) 0%, transparent 50%)',
          transform: `scale(${glowScale})`,
        }} />
        <div style={{
          position: 'absolute', width: '100%', height: '100%',
          background: 'radial-gradient(circle at center, rgba(14,165,233,0.08) 0%, transparent 40%)',
        }} />

        <div style={{
          display: 'flex', flexDirection: 'column', alignItems: 'center',
          zIndex: 10,
        }}>
          {/* Logo */}
          <Img
            src={staticFile('app_pin_logo.png')}
            style={{
              width: 160, height: 160, objectFit: 'contain',
              transform: `scale(${logoScale})`,
              opacity: logoOp,
              filter: 'drop-shadow(0 20px 50px rgba(20,184,166,0.5))',
            }}
          />

          {/* Wordmark */}
          <h1 style={{
            fontFamily: 'Inter, sans-serif', fontSize: 72, fontWeight: 900,
            color: 'white', margin: '24px 0 0 0',
            transform: `translateY(${wordY}px)`,
            opacity: wordOp,
            letterSpacing: '-0.04em',
            textShadow: '0 4px 30px rgba(255,255,255,0.15)',
          }}>
            Laween
          </h1>

          {/* Tagline */}
          <p style={{
            fontFamily: 'Inter, sans-serif', fontSize: 28, color: '#94a3b8',
            fontWeight: 500, margin: '14px 0 0 0',
            transform: `translateY(${tagY}px)`,
            opacity: tagOp,
            letterSpacing: '0.06em',
          }}>
            Your world, connected.
          </p>
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
