import { AbsoluteFill, useCurrentFrame, useVideoConfig, spring, interpolate } from 'remotion';
import React from 'react';

export const Scene5LiveMap: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  
  // Animate map drawing
  const pathDraw = spring({ frame: frame - 10, fps, config: { damping: 100 }, durationInFrames: 60 });
  const mapOpacity = interpolate(frame, [0, 20], [0, 1], { extrapolateRight: 'clamp' });

  // Pinned dot following the path (bezier curve approximation)
  // For Remotion, we simulate travel along a curve with interpolation
  const progress = interpolate(frame, [30, 150], [0, 1], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' });
  const x = interpolate(progress, [0, 0.5, 1], [-200, 50, 300]);
  const y = interpolate(progress, [0, 0.5, 1], [-400, -50, 400]);

  // Context Pin popup
  const pinPop = spring({ frame: frame - 60, fps, config: { damping: 12 } });

  return (
    <AbsoluteFill style={{ justifyContent: 'center', alignItems: 'center', opacity: mapOpacity }}>
      
      {/* Background glowing gradients */}
      <div style={{ position: 'absolute', width: '100%', height: '100%', background: 'radial-gradient(circle at center, rgba(14, 165, 233, 0.1) 0%, transparent 60%)' }} />

      <h2 style={{ 
        position: 'absolute', top: 120, left: 80, 
        fontFamily: 'Inter, sans-serif', fontSize: 36, color: '#0ea5e9', 
        letterSpacing: 4, textTransform: 'uppercase', margin: 0, fontWeight: 700 
      }}>
        Laween is Always Aware
      </h2>
      <h1 style={{ 
        position: 'absolute', top: 160, left: 80, maxWidth: 800,
        fontFamily: 'Inter, sans-serif', fontSize: 75, color: 'white', 
        lineHeight: 1, margin: 0, fontWeight: 900, letterSpacing: -2 
      }}>
        SHE KNOWS YOUR EXACT LOCATION.
      </h1>

      {/* SVG Glowing Path */}
      <svg width="1080" height="1920" style={{ position: 'absolute', top: 0, left: 0, zIndex: 1 }}>
        <path 
          d="M 340 -100 Q 600 300, 590 910 T 840 1600" 
          fill="none" 
          stroke="#0ea5e9" 
          strokeWidth="15" 
          strokeLinecap="round"
          strokeDasharray="2000"
          strokeDashoffset={2000 - (2000 * pathDraw)}
          style={{ filter: 'drop-shadow(0 0 30px #0ea5e9)' }}
        />
      </svg>

      {/* Moving User Pin Container */}
      <div style={{
        position: 'absolute',
        top: '50%', left: '50%',
        transform: `translate(${x}px, ${y}px)`,
        zIndex: 10
      }}>
        
        {/* The Dot */}
        <div style={{
          width: 40, height: 40, backgroundColor: 'white', borderRadius: 20,
          border: '10px solid #0ea5e9',
          boxShadow: '0 0 40px #0ea5e9',
          transform: 'translate(-50%, -50%)'
        }}>
          {/* Subtle pulse */}
          <div style={{ position: 'absolute', top: -10, left: -10, width: 40, height: 40, borderRadius: 20, border: '4px solid #0ea5e9', opacity: 0.5, transform: `scale(${1 + (frame % 30) / 10})` }} />
        </div>

        {/* The Context Popout Card */}
        {frame > 60 && (
          <div style={{
            position: 'absolute',
            top: -20, left: 50,
            width: 380,
            padding: '20px',
            backgroundColor: 'rgba(15, 23, 42, 0.85)',
            backdropFilter: 'blur(10px)',
            border: '1px solid rgba(255,255,255,0.1)',
            borderRadius: 24,
            boxShadow: '0 20px 40px rgba(0,0,0,0.5)',
            transform: `scale(${pinPop})`,
            transformOrigin: 'left center',
          }}>
            <div style={{ display: 'flex', alignItems: 'center', marginBottom: 5 }}>
              <div style={{ width: 12, height: 12, backgroundColor: '#0ea5e9', borderRadius: 6, marginRight: 10 }} />
              <p style={{ margin: 0, color: '#0ea5e9', fontFamily: 'Inter, sans-serif', fontSize: 18, fontWeight: 700, letterSpacing: 2, textTransform: 'uppercase' }}>
                Context Ready
              </p>
            </div>
            <h3 style={{ margin: 0, color: 'white', fontFamily: 'Inter, sans-serif', fontSize: 36, fontWeight: 700 }}>
              Group Outing
            </h3>
            <div style={{ width: `${progress * 100}%`, height: 4, backgroundColor: '#0ea5e9', marginTop: 15, borderRadius: 2 }} />
          </div>
        )}

      </div>
    </AbsoluteFill>
  );
};
