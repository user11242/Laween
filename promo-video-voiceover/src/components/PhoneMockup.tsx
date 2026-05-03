import React from 'react';
import { useCurrentFrame } from 'remotion';

/**
 * Premium iPhone 15 Pro mockup.
 * 
 * KEY FIX: Children are rendered at a fixed virtual resolution (378×832)
 * then CSS-scaled to fill the phone. This means all pixel values in scene
 * components (font sizes, paddings, widths) look correct at ANY phone scale.
 */
export const PhoneMockup: React.FC<{
  children: React.ReactNode;
  style?: React.CSSProperties;
  screenStyle?: React.CSSProperties;
  scale?: number;
  drift?: boolean;
  parallax?: boolean;
}> = ({ children, style, screenStyle, scale = 1, drift = false, parallax = false }) => {
  const frame = useCurrentFrame();
  const w = 390;
  const h = 844;
  const bezel = 6;
  const screenW = w - bezel * 2;  // 378
  const screenH = h - bezel * 2;  // 832

  // Subtle drift (floating)
  const driftY = drift ? Math.sin(frame * 0.04) * 4 : 0;
  const driftX = drift ? Math.cos(frame * 0.03) * 2 : 0;

  // Subtle parallax tilt
  const tiltX = parallax ? Math.sin(frame * 0.02) * 1.5 : 0;
  const tiltY = parallax ? Math.cos(frame * 0.025) * 1 : 0;

  return (
    <div style={{
      width: w * scale,
      height: h * scale,
      position: 'relative',
      transformStyle: 'preserve-3d',
      transform: `translate(${driftX}px, ${driftY}px) perspective(1200px) rotateX(${tiltX}deg) rotateY(${tiltY}deg)`,
      ...style
    }}>
      {/* Outer Chassis */}
      <div style={{
        position: 'absolute',
        inset: 0,
        borderRadius: 54 * scale,
        background: 'linear-gradient(160deg, #3a3a3f 0%, #28282d 15%, #1c1c21 40%, #111115 70%, #0a0a0e 100%)',
        boxShadow: [
          `0 ${40 * scale}px ${80 * scale}px rgba(0,0,0,0.7)`,
          `0 ${80 * scale}px ${160 * scale}px rgba(0,0,0,0.5)`,
          `0 ${4 * scale}px ${12 * scale}px rgba(0,0,0,0.6)`,
          `inset 0 ${1.5 * scale}px 0 rgba(255,255,255,0.18)`,
          `inset -${1 * scale}px 0 0 rgba(255,255,255,0.08)`,
          `inset 0 -${0.5 * scale}px 0 rgba(255,255,255,0.04)`,
        ].join(', '),
      }} />

      {/* Inner bezel ring */}
      <div style={{
        position: 'absolute',
        top: 3 * scale, left: 3 * scale, right: 3 * scale, bottom: 3 * scale,
        borderRadius: 51 * scale,
        border: `${0.5 * scale}px solid rgba(255,255,255,0.06)`,
        boxShadow: `inset 0 0 ${4 * scale}px rgba(0,0,0,0.3)`,
      }} />

      {/* Inner Screen — clip area */}
      <div style={{
        position: 'absolute',
        top: bezel * scale,
        left: bezel * scale,
        width: screenW * scale,
        height: screenH * scale,
        borderRadius: 48 * scale,
        overflow: 'hidden',
        backgroundColor: '#000',
        ...screenStyle,
      }}>
        {/* 
         * VIRTUAL VIEWPORT: children render at fixed 378×832,
         * then get CSS-scaled to fill the actual screen area.
         * This keeps all font sizes / paddings / layouts proportional.
         */}
        <div style={{
          width: screenW,
          height: screenH,
          transform: `scale(${scale})`,
          transformOrigin: 'top left',
          position: 'relative',
        }}>
          {children}
        </div>

        {/* Screen reflection */}
        <div style={{
          position: 'absolute', inset: 0, zIndex: 50,
          background: `linear-gradient(135deg, 
            rgba(255,255,255,0.03) 0%, 
            transparent 30%, 
            transparent 70%, 
            rgba(255,255,255,0.015) 100%)`,
          pointerEvents: 'none',
        }} />
      </div>

      {/* Dynamic Island */}
      <div style={{
        position: 'absolute',
        top: 14 * scale, left: '50%', transform: 'translateX(-50%)',
        width: 126 * scale, height: 36 * scale,
        backgroundColor: '#000', borderRadius: 18 * scale, zIndex: 60,
        boxShadow: `0 ${1 * scale}px ${4 * scale}px rgba(0,0,0,0.8), inset 0 ${0.5 * scale}px 0 rgba(255,255,255,0.05)`,
      }} />

      {/* Side Buttons */}
      <div style={{
        position: 'absolute', left: -2.5 * scale, top: 140 * scale,
        width: 3 * scale, height: 30 * scale,
        background: 'linear-gradient(to bottom, #38383c, #1d1d20, #2a2a2e)',
        borderTopLeftRadius: 2 * scale, borderBottomLeftRadius: 2 * scale,
        boxShadow: `-${1 * scale}px 0 ${3 * scale}px rgba(0,0,0,0.3)`,
      }} />
      <div style={{
        position: 'absolute', left: -2.5 * scale, top: 195 * scale,
        width: 3 * scale, height: 54 * scale,
        background: 'linear-gradient(to bottom, #38383c, #1d1d20, #2a2a2e)',
        borderTopLeftRadius: 2 * scale, borderBottomLeftRadius: 2 * scale,
        boxShadow: `-${1 * scale}px 0 ${3 * scale}px rgba(0,0,0,0.3)`,
      }} />
      <div style={{
        position: 'absolute', left: -2.5 * scale, top: 265 * scale,
        width: 3 * scale, height: 54 * scale,
        background: 'linear-gradient(to bottom, #38383c, #1d1d20, #2a2a2e)',
        borderTopLeftRadius: 2 * scale, borderBottomLeftRadius: 2 * scale,
        boxShadow: `-${1 * scale}px 0 ${3 * scale}px rgba(0,0,0,0.3)`,
      }} />
      <div style={{
        position: 'absolute', right: -2.5 * scale, top: 228 * scale,
        width: 3 * scale, height: 78 * scale,
        background: 'linear-gradient(to bottom, #38383c, #1d1d20, #2a2a2e)',
        borderTopRightRadius: 2 * scale, borderBottomRightRadius: 2 * scale,
        boxShadow: `${1 * scale}px 0 ${3 * scale}px rgba(0,0,0,0.3)`,
      }} />

      {/* Bottom home indicator */}
      <div style={{
        position: 'absolute', bottom: 14 * scale, left: '50%',
        transform: 'translateX(-50%)',
        width: 134 * scale, height: 5 * scale,
        backgroundColor: 'rgba(255,255,255,0.25)',
        borderRadius: 3 * scale, zIndex: 60,
      }} />
    </div>
  );
};
