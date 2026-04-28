/*
 * SCENE 4b — MULTI-POV CONNECTIVITY
 * 16:9 exclusive scene: 4 phones side-by-side showing simultaneous actions,
 * merging into one phone to transition to the group chat ecosystem.
 */
import { AbsoluteFill, useCurrentFrame, useVideoConfig, spring, interpolate, Img, staticFile } from 'remotion';
import React from 'react';
import { PhoneMockup } from '../components/PhoneMockup';

const MOCK_ACTIONS = [
  { label: 'Message', accent: '#a78bfa', name: 'Sarah', icon: 'M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z' },
  { label: 'Location', accent: '#3b82f6', name: 'Omar',   icon: 'M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z' },
  { label: 'Join',     accent: '#f59e0b', name: 'Ahmad',  icon: 'M16 21v-2a4 4 0 0 0-4-4H5c-2.2 0-4 1.8-4 4v2 M8.5 7a4 4 0 1 0 0-8 4 4 0 0 0 0 8z M20 8v6 M23 11h-6' },
  { label: 'Start',    accent: '#14b8a6', name: 'You',    icon: 'M12 2v20 M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6' },
];

export const Scene4bMultiPOV: React.FC = () => {
  const { fps } = useVideoConfig();
  const frame = useCurrentFrame();

  const titleOp = interpolate(frame, [10, 20], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const titleFade = interpolate(frame, [150, 160], [1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  // Merge animation kicks in at frame 130
  const mergeSpring = spring({ frame: frame - 130, fps, config: { damping: 14 } });
  const mergeProg = interpolate(mergeSpring, [0, 1], [0, 1]);

  return (
    <AbsoluteFill style={{ backgroundColor: '#050714', justifyContent: 'center', alignItems: 'center' }}>
      <div style={{ position: 'absolute', width: '100%', height: '100%',
        background: 'radial-gradient(ellipse at 50% 50%, rgba(20,184,166,0.06) 0%, transparent 55%)' }} />

      <div style={{
        position: 'absolute', top: '5%', width: '100%', textAlign: 'center',
        opacity: titleOp * titleFade, zIndex: 20,
      }}>
        <h1 style={{ fontFamily: 'Inter, system-ui, sans-serif', fontSize: 64, fontWeight: 900, color: 'white', margin: 0, letterSpacing: '-0.02em', lineHeight: 1.15 }}>
          One group. One flow.
        </h1>
        <p style={{ fontFamily: 'Inter, system-ui, sans-serif', fontSize: 30, fontWeight: 600, color: '#5eead4', margin: '14px 0 0' }}>
          Planning, sharing, and moving together.
        </p>
      </div>

      <div style={{ position: 'absolute', top: '50%', left: '50%', transform: `translate(-50%, -50%) translateY(80px)`, width: 1920, height: 1080 }}>
        {MOCK_ACTIONS.map((action, i) => {
          // Calculate horizontal spread
          // Total width allowed: ~1600. Centers at: -600, -200, 200, 600
          const startX = -600 + (i * 400);
          
          // Animate into place initially
          const inSpring = spring({ frame: frame - (10 + i * 5), fps, config: { damping: 16 } });
          const popScale = interpolate(inSpring, [0, 1], [0.6, 0.72]);
          const inOp = interpolate(inSpring, [0, 1], [0, 1]);

          // Animate merge to center (hero phone)
          const curX = interpolate(mergeProg, [0, 1], [startX, 0]);
          const curOp = mergeProg > 0 && i !== 3 ? interpolate(mergeProg, [0, 0.5], [1, 0]) : inOp;
          const curScale = mergeProg > 0 && i === 3 ? interpolate(mergeProg, [0, 1], [0.72, 0.95]) : popScale;
          const zInd = i === 3 ? 10 : 5 - i;

          return (
            <div key={i} style={{
              position: 'absolute', top: '50%', left: '50%',
              transform: `translate(-50%, -50%) translateX(${curX}px) scale(${curScale})`,
              opacity: curOp, zIndex: zInd,
            }}>
              <PhoneMockup scale={1.0} drift={false}>
                {/* Simulated minimal screen for each POV */}
                <div style={{
                  width: '100%', height: '100%', background: '#0a0d14',
                  display: 'flex', flexDirection: 'column',
                  alignItems: 'center', justifyContent: 'center', gap: 24,
                }}>
                  <div style={{
                    width: 72, height: 72, borderRadius: 24,
                    background: `${action.accent}15`, border: `1px solid ${action.accent}40`,
                    display: 'flex', justifyContent: 'center', alignItems: 'center',
                    boxShadow: `0 8px 32px ${action.accent}30`
                  }}>
                    <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke={action.accent} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                      <path d={action.icon} />
                    </svg>
                  </div>
                  <div style={{ textAlign: 'center' }}>
                    <p style={{ fontFamily: 'Inter, system-ui, sans-serif', fontSize: 18, color: action.accent, fontWeight: 700, margin: '0 0 6px', letterSpacing: '0.1em', textTransform: 'uppercase' }}>
                      {action.name}'s POV
                    </p>
                    <p style={{ fontFamily: 'Inter, system-ui, sans-serif', fontSize: 40, color: 'white', fontWeight: 800, margin: 0, letterSpacing: '-0.02em' }}>
                      {action.label}
                    </p>
                  </div>
                </div>
              </PhoneMockup>
            </div>
          );
        })}
      </div>
    </AbsoluteFill>
  );
};
