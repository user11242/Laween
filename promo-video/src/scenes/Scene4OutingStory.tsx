import { AbsoluteFill, useCurrentFrame, useVideoConfig, spring, interpolate } from 'remotion';
import React from 'react';

export const Scene4OutingStory: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Animations for first card
  const card1Start = 10;
  const card1Scale = spring({ frame: frame - card1Start, fps, config: { damping: 14 } });
  const card1Opacity = interpolate(frame, [card1Start, card1Start + 10], [0, 1], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' });

  // Animations for second card
  const card2Start = 50;
  const card2Scale = spring({ frame: frame - card2Start, fps, config: { damping: 14 } });
  const card2Opacity = interpolate(frame, [card2Start, card2Start + 10], [0, 1], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' });

  return (
    <AbsoluteFill style={{ justifyContent: 'center', alignItems: 'center' }}>
      
      <h2 style={{ 
        fontFamily: 'Inter, sans-serif', fontSize: 60, fontWeight: 800, color: 'white', 
        marginBottom: 80, textShadow: '0 4px 20px rgba(0,0,0,0.5)', zIndex: 10
      }}>
        No more <span style={{ color: '#0ea5e9' }}>"Where are you?"</span>
      </h2>
      
      {/* Container simulating a phone screen view or hovering widgets */}
      <div style={{ position: 'relative', width: '100%', display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
        
        {/* Card 1: Elevated Glassmorphic Design */}
        <div style={{
          width: '80%', maxWidth: 800,
          padding: '40px', 
          backgroundColor: 'rgba(15, 23, 42, 0.7)', // Deep Slate translucent
          border: '1px solid rgba(255, 255, 255, 0.08)',
          borderRadius: 32,
          backdropFilter: 'blur(20px)',
          transform: `scale(${0.9 + (card1Scale * 0.1)}) translateY(${interpolate(frame, [card1Start, card1Start+20], [20, 0])}px)`, 
          opacity: card1Opacity, 
          marginBottom: 40,
          boxShadow: '0 30px 60px rgba(0,0,0,0.6), inset 0 1px 0 rgba(255,255,255,0.1)',
          display: 'flex', flexDirection: 'row', alignItems: 'center'
        }}>
          <div style={{ width: 80, height: 80, borderRadius: 40, backgroundColor: '#34d399', marginRight: 30, boxShadow: '0 0 30px rgba(52, 211, 153, 0.5)' }} />
          <div>
            <p style={{ margin: 0, fontSize: 24, color: 'rgba(255,255,255,0.5)', fontFamily: 'Inter, sans-serif', fontWeight: 600, letterSpacing: 2, textTransform: 'uppercase' }}>
              Original Message
            </p>
            <h3 style={{ margin: '10px 0 0 0', color: 'white', fontSize: 44, fontFamily: 'Inter, sans-serif' }}>
              Sarah <span style={{ color: '#0ea5e9' }}>has arrived!</span>
            </h3>
          </div>
        </div>

        {/* Card 2: Glowing neon border accent */}
        <div style={{
          width: '80%', maxWidth: 800,
          padding: '40px', 
          backgroundColor: 'rgba(15, 23, 42, 0.9)', 
          border: '2px solid #0ea5e9', // Glowing Blue Border like "Language Detected"
          borderRadius: 32,
          transform: `scale(${0.9 + (card2Scale * 0.1)}) translateY(${interpolate(frame, [card2Start, card2Start+20], [20, 0])}px)`, 
          opacity: card2Opacity,
          boxShadow: '0 0 40px rgba(14, 165, 233, 0.4), 0 30px 60px rgba(0,0,0,0.6), inset 0 1px 0 rgba(255,255,255,0.1)',
          display: 'flex', flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between'
        }}>
          <div>
            <p style={{ margin: 0, fontSize: 24, color: '#0ea5e9', fontFamily: 'Inter, sans-serif', fontWeight: 600, letterSpacing: 2, textTransform: 'uppercase' }}>
              Automatic Update
            </p>
            <h3 style={{ margin: '10px 0 0 0', color: 'white', fontSize: 48, fontFamily: 'Inter, sans-serif' }}>
              Ahmed is <span style={{ color: '#0ea5e9' }}>5 mins away.</span>
            </h3>
          </div>
          <div style={{ fontSize: 50, color: 'white' }}>ETA</div>
        </div>

      </div>

    </AbsoluteFill>
  );
};
