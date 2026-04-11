import { AbsoluteFill, useVideoConfig, useCurrentFrame, spring, interpolate, Img, staticFile } from 'remotion';
import React from 'react';

export const Scene1Ecosystem: React.FC = () => {
  const { fps } = useVideoConfig();
  const frame = useCurrentFrame();

  // Typography animations
  const textOpacity = interpolate(frame, [10, 30], [0, 1], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' });
  const textScale = spring({ frame: frame - 10, fps, config: { damping: 100 } });

  // Strikethrough line animation
  const strikeStart = 50;
  const strikeProgress = spring({ frame: frame - strikeStart, fps, config: { damping: 14 } });

  // Negative word falling away and turning grey
  const negativeWordY = spring({ frame: frame - 80, fps, config: { damping: 15 } }) * 50;
  const negativeOpacity = interpolate(frame, [80, 100], [1, 0], { extrapolateRight: 'clamp' });

  // Positive word arriving
  const positiveStart = 90;
  const positiveY = interpolate(spring({ frame: frame - positiveStart, fps, config: { damping: 12 } }), [0, 1], [50, 0]);
  const positiveOpacity = interpolate(frame, [positiveStart, positiveStart + 15], [0, 1], { extrapolateRight: 'clamp' });

  return (
    <AbsoluteFill style={{ justifyContent: 'center', alignItems: 'center' }}>
      
      {/* Container for the text */}
      <div style={{
        display: 'flex', flexDirection: 'column', alignItems: 'center',
        opacity: textOpacity,
        transform: `scale(${0.9 + (textScale * 0.1)})`
      }}>
        
        <h1 style={{ 
          fontFamily: 'Inter, sans-serif', fontWeight: 700, fontSize: 80, 
          color: 'white', margin: 0, letterSpacing: '-0.02em', zIndex: 2 
        }}>
          Planning is
        </h1>
        
        <div style={{ position: 'relative', marginTop: 10 }}>
          
          {/* The Negative Word */}
          <h1 style={{ 
            fontFamily: 'Inter, sans-serif', fontWeight: 800, fontSize: 90, 
            color: '#3b82f6', margin: 0, letterSpacing: '-0.03em',
            transform: `translateY(${negativeWordY}px)`,
            opacity: negativeOpacity
          }}>
            chaotic.
          </h1>
          
          {/* Strikethrough Line (Red) */}
          <div style={{
            position: 'absolute',
            top: '50%', left: '-5%',
            width: `${strikeProgress * 110}%`,
            height: 12, // Thick red line
            backgroundColor: '#ef4444',
            transform: 'translateY(-50%)',
            borderRadius: 6,
            boxShadow: '0 4px 20px rgba(239, 68, 68, 0.4)',
            zIndex: 3
          }} />

          {/* The Replacing Positive Word (Laween aesthetic) */}
          <h1 style={{ 
            fontFamily: 'Inter, sans-serif', fontWeight: 800, fontSize: 90, 
            color: '#0ea5e9', margin: 0, letterSpacing: '-0.03em',
            position: 'absolute',
            top: 0, left: 0,
            width: '100%', textAlign: 'center',
            transform: `translateY(${positiveY}px)`,
            opacity: positiveOpacity,
            textShadow: '0 0 40px rgba(14, 165, 233, 0.6)'
          }}>
            effortless.
          </h1>

        </div>
      </div>

    </AbsoluteFill>
  );
};
