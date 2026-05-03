import { AbsoluteFill, useCurrentFrame, useVideoConfig, spring, interpolate, Img, staticFile } from 'remotion';
import React from 'react';

/*
 * SCENE 1 — OPENING CHAOS → LAWEEN RESOLVES
 * 0:00–0:04 (120 frames @ 30fps)
 *
 * Frames 0-72:  Pure chaos — scattered bubbles enter one by one (staggered).
 *               NO Laween logo. Just messy group coordination from 6 people.
 *               Each sender has a consistent subtle premium color identity.
 *
 * Frames 72-120: Laween pin/logo appears CENTER with glow, pushes chaos outward.
 *                "One chat. One plan." + "One place to meet." fades in below.
 */

/* ── Premium sender palette — HSL-tuned, not raw saturated ── */
const SENDERS = [
  { name: 'Yazan',  color: 'hsl(168, 55%, 48%)', accent: 'rgba(45,212,191,0.15)', msg: 'Where are we meeting??', delay: 0,  x: -220, y: -420, rot: -3.5 },
  { name: 'Sara',   color: 'hsl(262, 60%, 68%)', accent: 'rgba(167,139,250,0.15)', msg: "I'm running late!",      delay: 14, x:  230, y: -260, rot: 2.5 },
  { name: 'Lina',   color: 'hsl(330, 55%, 65%)', accent: 'rgba(244,114,182,0.15)', msg: 'Can we do 8:30?',        delay: 26, x: -180, y: -80,  rot: -2 },
  { name: 'Omar',   color: 'hsl(217, 65%, 62%)', accent: 'rgba(96,165,250,0.15)',  msg: 'Send the location!',     delay: 38, x:  220, y:  100, rot: 3 },
  { name: 'Ahmed',  color: 'hsl(43, 82%, 55%)',  accent: 'rgba(251,191,36,0.15)',  msg: 'Which restaurant??',     delay: 50, x: -200, y:  280, rot: -3 },
  { name: 'Noor',   color: 'hsl(0, 62%, 62%)',   accent: 'rgba(248,113,113,0.15)', msg: "Who's driving?",         delay: 62, x:  190, y:  430, rot: 2 },
];

/* ── Single Chat Bubble ── */
const ChatBubble: React.FC<{
  sender: typeof SENDERS[0]; pushFrame: number;
}> = ({ sender, pushFrame }) => {
  const { fps } = useVideoConfig();
  const frame = useCurrentFrame();

  // Staggered entry — each bubble pops in at its delay with a lively spring
  const entrySpring = spring({ frame: frame - sender.delay, fps, config: { damping: 11, stiffness: 140, mass: 0.9 } });
  const scale = interpolate(entrySpring, [0, 1], [0, 1]);
  const opacity = interpolate(entrySpring, [0, 0.35], [0, 1]);

  // Gentle floating drift — organic, alive
  const floatY = Math.sin((frame - sender.delay) * 0.055 + sender.x * 0.008) * 6;
  const floatX = Math.cos((frame - sender.delay) * 0.04 + sender.y * 0.008) * 4;

  // PUSH OUTWARD when logo appears at pushFrame
  const pushSpring = spring({ frame: frame - pushFrame, fps, config: { damping: 12, stiffness: 70 } });
  const angle = Math.atan2(sender.y, sender.x);
  const pushDist = 800;
  const pushX = interpolate(pushSpring, [0, 1], [0, Math.cos(angle) * pushDist]);
  const pushY = interpolate(pushSpring, [0, 1], [0, Math.sin(angle) * pushDist]);
  const pushOp = interpolate(pushSpring, [0, 0.45], [1, 0]);
  const pushScale = interpolate(pushSpring, [0, 1], [1, 0.15]);

  return (
    <div style={{
      position: 'absolute',
      left: `calc(50% + ${sender.x}px)`,
      top: `calc(50% + ${sender.y}px)`,
      transform: `translate(-50%, -50%) translate(${floatX + pushX}px, ${floatY + pushY}px) rotate(${sender.rot}deg) scale(${scale * pushScale})`,
      opacity: opacity * pushOp,
    }}>
      {/* Sender name — prominent and readable */}
      <p style={{
        fontFamily: 'Outfit, system-ui, sans-serif', fontSize: 19, fontWeight: 800,
        letterSpacing: '0.02em', color: sender.color,
        margin: '0 0 8px 18px', opacity: 0.95,
        textShadow: '0 1px 6px rgba(0,0,0,0.3)',
      }}>{sender.name}</p>

      {/* Bubble — colored left accent, generous padding, like a real chat app */}
      <div style={{
        background: 'rgba(22, 33, 52, 0.92)',
        backdropFilter: 'blur(12px)',
        padding: '20px 30px', borderRadius: 22,
        borderBottomLeftRadius: 6,
        borderLeft: `3.5px solid ${sender.color}`,
        fontFamily: 'Inter, system-ui, sans-serif', fontSize: 26, color: 'white', fontWeight: 500,
        boxShadow: `0 12px 40px rgba(0,0,0,0.5), 0 0 0 1px rgba(255,255,255,0.05), inset 0 1px 0 rgba(255,255,255,0.06)`,
        whiteSpace: 'nowrap',
        letterSpacing: '-0.01em',
      }}>
        {sender.msg}
      </div>
    </div>
  );
};

/* ── Extra scattered chat messages — more voices adding to the confusion ── */
const EXTRA_MESSAGES = [
  { name: 'Sara',  color: 'hsl(262, 60%, 68%)', accent: 'rgba(167,139,250,0.15)', msg: 'Wait, tonight or tomorrow?', delay: 20, x: 280, y: -370, rot: 2 },
  { name: 'Yazan', color: 'hsl(168, 55%, 48%)', accent: 'rgba(45,212,191,0.15)', msg: 'Just share your location',  delay: 46, x: -290, y:  390, rot: -2.5 },
  { name: 'Omar',  color: 'hsl(217, 65%, 62%)', accent: 'rgba(96,165,250,0.15)', msg: 'I can pick up Noor',         delay: 58, x:  300, y:  200, rot: 1.5 },
];

export const Scene1Hook: React.FC = () => {
  const { fps } = useVideoConfig();
  const frame = useCurrentFrame();

  // Logo / transition starts at frame 90 — chaos phase gets 3 full seconds to register
  const pushFrame = 90;

  /* ═══ LOGO — appears at pushFrame, dead center ═══ */
  const logoSpring = spring({ frame: frame - pushFrame, fps, config: { damping: 10, stiffness: 90, mass: 1.1 } });
  const logoScale = interpolate(logoSpring, [0, 1], [0.15, 1]);
  const logoOp = interpolate(frame, [pushFrame, pushFrame + 8], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const logoPulse = frame >= pushFrame ? 0.12 + Math.sin((frame - pushFrame) * 0.1) * 0.06 : 0;

  // Expanding teal ring behind logo
  const ringExpand = interpolate(logoSpring, [0, 1], [0, 1]);
  const ringOp = interpolate(logoSpring, [0.3, 1], [0.4, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  /* ═══ TITLE TEXT — appears after logo settles ═══ */
  const titleDelay = pushFrame + 16;
  const titleSpring = spring({ frame: frame - titleDelay, fps, config: { damping: 14 } });
  const titleOp = interpolate(frame, [titleDelay, titleDelay + 10], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const titleY = interpolate(titleSpring, [0, 1], [50, 0]);

  const subDelay = titleDelay + 12;
  const subSpring = spring({ frame: frame - subDelay, fps, config: { damping: 16 } });
  const subOp = interpolate(frame, [subDelay, subDelay + 10], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const subY = interpolate(subSpring, [0, 1], [30, 0]);

  const exitOp = interpolate(frame, [140, 150], [1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  return (
    <AbsoluteFill style={{ backgroundColor: '#050714', overflow: 'hidden', opacity: exitOp }}>
      {/* Ambient teal glow — soft, premium, grows with logo */}
      <div style={{
        position: 'absolute', width: '100%', height: '100%',
        background: frame < pushFrame
          ? 'radial-gradient(ellipse at 50% 45%, rgba(0,109,119,0.03) 0%, transparent 50%)'
          : `radial-gradient(ellipse at 50% 44%, rgba(0,109,119,${0.03 + logoPulse * 0.3}) 0%, transparent 55%)`,
      }} />

      {/* Subtle grid pattern — adds depth to dark bg */}
      <div style={{
        position: 'absolute', width: '100%', height: '100%', opacity: 0.015,
        backgroundImage: 'linear-gradient(rgba(255,255,255,0.1) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,0.1) 1px, transparent 1px)',
        backgroundSize: '60px 60px',
      }} />

      {/* ═══ CHAOS BUBBLES — staggered entry, pushed outward on logo ═══ */}
      {SENDERS.map((s, i) => (
        <ChatBubble key={i} sender={s} pushFrame={pushFrame} />
      ))}

      {/* ─── Extra scattered chat messages — more confusion ─── */}
      {EXTRA_MESSAGES.map((s, i) => (
        <ChatBubble key={`extra-${i}`} sender={s} pushFrame={pushFrame} />
      ))}

      {/* ═══ EXPANDING RING — appears with logo, expands outward ═══ */}
      {frame >= pushFrame && (
        <div style={{
          position: 'absolute', top: '44%', left: '50%',
          transform: `translate(-50%, -50%) scale(${ringExpand * 4})`,
          width: 200, height: 200, borderRadius: '50%',
          border: '2px solid rgba(0,109,119,0.25)',
          opacity: ringOp,
        }} />
      )}

      {/* ═══ LOGO RESOLVE — appears at pushFrame, dead center, premium ═══ */}
      {frame >= pushFrame && (
        <div style={{
          position: 'absolute', top: '44%', left: '50%',
          transform: `translate(-50%, -50%) scale(${logoScale})`,
          opacity: logoOp, zIndex: 10,
        }}>
          {/* Glow halo */}
          <div style={{
            position: 'absolute', inset: -120,
            background: `radial-gradient(circle, rgba(0,109,119,${logoPulse}) 0%, rgba(0,109,119,${logoPulse * 0.3}) 40%, transparent 65%)`,
            borderRadius: '50%',
          }} />
          <Img src={staticFile('app_pin_logo.png')} style={{
            width: 210, height: 210,
            filter: 'drop-shadow(0 20px 60px rgba(0,109,119,0.5)) drop-shadow(0 4px 12px rgba(0,0,0,0.3))',
          }} />
        </div>
      )}

      {/* ═══ TITLE TEXT — positioned consistently at top:4% + offset from center ═══ */}
      <div style={{
        position: 'absolute', top: '58%', width: '100%',
        display: 'flex', flexDirection: 'column', alignItems: 'center',
        zIndex: 10,
      }}>
        <h1 style={{
          fontFamily: 'Outfit, system-ui, sans-serif', fontSize: 72, fontWeight: 900, color: 'white',
          margin: 0, textAlign: 'center', letterSpacing: '-0.02em',
          textShadow: '0 4px 40px rgba(0,109,119,0.2)',
          opacity: titleOp, transform: `translateY(${titleY}px)`,
        }}>
          One chat. One plan.
        </h1>
        <p style={{
          fontFamily: 'Outfit, system-ui, sans-serif', fontSize: 36, fontWeight: 700,
          color: '#83C5BE', margin: '16px 0 0', textAlign: 'center',
          textShadow: '0 2px 20px rgba(131,197,190,0.15)',
          opacity: subOp, transform: `translateY(${subY}px)`,
        }}>
          One place to meet.
        </p>
      </div>
    </AbsoluteFill>
  );
};
