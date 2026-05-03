import { AbsoluteFill, useVideoConfig, useCurrentFrame, spring, interpolate, Img, staticFile } from 'remotion';
import React from 'react';

// A small ChatBubble component for the chaotic intro, now with avatars and names
const ChatBubble: React.FC<{
  text: string; name: string; avatarColor: string; delay: number; top: string; left: string; rotation: number; isRight?: boolean;
}> = ({ text, name, avatarColor, delay, top, left, rotation, isRight }) => {
  const { fps } = useVideoConfig();
  const frame = useCurrentFrame();

  const scale = spring({
    frame: frame - delay,
    fps,
    config: { damping: 12, stiffness: 200 }
  });

  // Dissolve/fly away when Laween pin smashes in (around frame 60)
  const flyAwayX = interpolate(frame, [60, 80], [0, isRight ? 600 : -600], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const flyAwayY = interpolate(frame, [60, 80], [0, -300], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const opacity = interpolate(frame, [10, 20], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' }) * 
                  interpolate(frame, [65, 75], [1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  return (
    <div style={{
      position: 'absolute', top, left,
      transform: `scale(${scale}) rotate(${rotation}deg) translate(${flyAwayX}px, ${flyAwayY}px)`,
      opacity,
      backgroundColor: isRight ? '#3b82f6' : '#1e293b',
      color: 'white', padding: '16px 24px', borderRadius: '24px',
      borderBottomLeftRadius: isRight ? '24px' : '4px',
      borderBottomRightRadius: isRight ? '4px' : '24px',
      fontFamily: 'Inter, sans-serif', boxShadow: '0 10px 25px rgba(0,0,0,0.3)',
      zIndex: 10, whiteSpace: 'nowrap', minWidth: '220px'
    }} >
      <div style={{ display: 'flex', alignItems: 'center', marginBottom: 8 }}>
        <div style={{ width: 24, height: 24, borderRadius: '50%', backgroundColor: avatarColor, marginRight: 8, border: '2px solid rgba(255,255,255,0.2)' }} />
        <span style={{ fontSize: 18, fontWeight: '700', color: isRight ? '#bfdbfe' : '#94a3b8' }}>{name}</span>
      </div>
      <div style={{ fontSize: 28, fontWeight: '600' }}>{text}</div>
    </div>
  );
};

export const Scene1Ecosystem: React.FC = () => {
  const { fps } = useVideoConfig();
  const frame = useCurrentFrame();

  // Background shifts from chaotic dark to a typical app backdrop
  const bgRed = interpolate(frame, [50, 70], [20, 10], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' });
  const bgGreen = interpolate(frame, [50, 70], [15, 10], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' });
  const bgBlue = interpolate(frame, [50, 70], [25, 15], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' });

  // Pin Logo Smash
  const smashStart = 60;
  // It drops from top (-1000px) down to center, with a strong spring
  const pinY = interpolate(spring({ frame: frame - smashStart, fps, config: { damping: 10, mass: 1.5, stiffness: 150 } }), [0, 1], [-800, 0]);
  const pinScale = interpolate(spring({ frame: frame - smashStart, fps, config: { damping: 12, mass: 1.5 } }), [0, 1], [0.1, 1]);
  // After it lands, it fades out to reveal the UI
  const pinOpacity = interpolate(frame, [smashStart + 20, smashStart + 35], [1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  // The Outing Session Sheet sliding up
  const sheetStart = smashStart + 15;
  const sheetY = interpolate(spring({ frame: frame - sheetStart, fps, config: { damping: 15, mass: 1.2 } }), [0, 1], [1500, 0]);
  const sheetOpacity = interpolate(frame, [sheetStart, sheetStart + 15], [0, 1], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' });

  return (
    <AbsoluteFill style={{ 
      backgroundColor: `rgb(${bgRed}, ${bgGreen}, ${bgBlue})`,
      overflow: 'hidden'
    }}>
      
      {/* Grouping chaotic elements */}
      <ChatBubble name="Ahmed" avatarColor="#f87171" text="Where are we meeting??" delay={5} top="15%" left="5%" rotation={-10} />
      <ChatBubble name="You" avatarColor="#3b82f6" text="I'm running late!" delay={15} top="35%" left="45%" rotation={12} isRight />
      <ChatBubble name="Sarah" avatarColor="#a78bfa" text="Can we do 8:30 instead?" delay={22} top="60%" left="8%" rotation={-5} />
      <ChatBubble name="You" avatarColor="#3b82f6" text="Send the location 📍" delay={32} top="25%" left="50%" rotation={8} isRight />
      <ChatBubble name="Omar" avatarColor="#fbbf24" text="Who's renting the pitch?" delay={40} top="80%" left="20%" rotation={-14} />

      {/* Screen tint/vignette for chaos */}
      <div style={{
        position: 'absolute', width: '100%', height: '100%',
        boxShadow: `inset 0 0 ${interpolate(frame, [0, 50, 60], [0, 150, 0], { extrapolateRight: 'clamp' })}px rgba(239, 68, 68, 0.25)`
      }} />

      {/* The Pin Logo Smashes In */}
      <AbsoluteFill style={{ justifyContent: 'center', alignItems: 'center', transform: `translateY(${pinY}px) scale(${pinScale})`, opacity: pinOpacity }}>
        <Img src={staticFile('app_pin_logo.png')} style={{ width: 400, height: 400, filter: 'drop-shadow(0 20px 40px rgba(11,200,210,0.5))' }} />
      </AbsoluteFill>

      {/* The UI Sheet Resolution */}
      <div style={{
        position: 'absolute',
        bottom: 0,
        left: 0,
        width: '100%',
        height: '85%',
        background: '#fdfdfd',
        borderTopLeftRadius: '60px',
        borderTopRightRadius: '60px',
        boxShadow: '0 -20px 50px rgba(0,0,0,0.4)',
        transform: `translateY(${sheetY}px)`,
        opacity: sheetOpacity,
        display: 'flex',
        flexDirection: 'column',
        padding: '60px',
        fontFamily: 'Inter, sans-serif'
      }}>
        {/* Top Handle */}
        <div style={{ width: 80, height: 8, background: '#e2e8f0', borderRadius: 4, alignSelf: 'center', marginBottom: 60 }} />

        {/* Header Section */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 50 }}>
          <div>
            <h1 style={{ color: '#273545', fontSize: 62, margin: '0 0 16px 0', fontWeight: '800', letterSpacing: '-0.02em' }}>
              Create Outing
            </h1>
            <p style={{ color: '#98a2b3', fontSize: 32, margin: 0, fontWeight: '500' }}>
              Find the perfect mid-point
            </p>
          </div>
          <div style={{ width: 80, height: 80, borderRadius: '50%', background: '#dff0ed', display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
            <span style={{ fontSize: 34, color: '#1d767f' }}>⚡</span>
          </div>
        </div>

        {/* Calculation Mode */}
        <p style={{ color: '#98a2b3', fontSize: 20, fontWeight: '700', letterSpacing: '0.08em', marginBottom: 20 }}>CALCULATION MODE</p>
        <div style={{ background: '#f4f5f6', top: 0, borderRadius: '40px', padding: 8, display: 'flex', marginBottom: 50 }}>
          <div style={{ flex: 1, textAlign: 'center', padding: '24px 0', color: '#a3a8b4', fontSize: 28, fontWeight: '700', display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
            <span style={{ marginRight: 12 }}>↕</span> KM
          </div>
          <div style={{ flex: 1, background: 'white', borderRadius: '30px', textAlign: 'center', padding: '24px 0', color: '#194b4e', fontSize: 28, fontWeight: '700', boxShadow: '0 4px 15px rgba(0,0,0,0.06)', display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
             <span style={{ marginRight: 12, color: '#194b4e' }}>⏱</span> Time
          </div>
        </div>

        {/* Category */}
        <p style={{ color: '#98a2b3', fontSize: 20, fontWeight: '700', letterSpacing: '0.08em', marginBottom: 20 }}>SELECT CATEGORY</p>
        <div style={{ display: 'flex', gap: '24px', marginBottom: 50 }}>
          <div style={{ flex: 1, background: '#ffffff', border: '3px solid #1d767f', borderRadius: '32px', padding: '36px 0', display: 'flex', flexDirection: 'column', alignItems: 'center', boxShadow: '0 10px 20px rgba(29,118,127,0.1)' }}>
            <div style={{ width: 80, height: 80, borderRadius: '50%', background: '#fff6ed', display: 'flex', justifyContent: 'center', alignItems: 'center', marginBottom: 16 }}>
               <span style={{ color: '#f97316', fontSize: 38 }}>🍽</span>
            </div>
            <span style={{ color: '#273545', fontSize: 24, fontWeight: '700' }}>Restaurant</span>
          </div>
          <div style={{ flex: 1, background: '#f8fafc', border: '3px solid transparent', borderRadius: '32px', padding: '36px 0', display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
            <div style={{ width: 80, height: 80, borderRadius: '50%', background: '#f4ebed', display: 'flex', justifyContent: 'center', alignItems: 'center', marginBottom: 16 }}>
               <span style={{ color: '#7c2d12', fontSize: 38 }}>☕</span>
            </div>
            <span style={{ color: '#475467', fontSize: 24, fontWeight: '600' }}>Cafe</span>
          </div>
          <div style={{ flex: 1, background: '#f8fafc', border: '3px solid transparent', borderRadius: '32px', padding: '36px 0', display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
            <div style={{ width: 80, height: 80, borderRadius: '50%', background: '#eef8ef', display: 'flex', justifyContent: 'center', alignItems: 'center', marginBottom: 16 }}>
               <span style={{ color: '#16a34a', fontSize: 38 }}>🌲</span>
            </div>
            <span style={{ color: '#475467', fontSize: 24, fontWeight: '600' }}>Park</span>
          </div>
        </div>

        {/* Join Time Limit */}
        <p style={{ color: '#98a2b3', fontSize: 20, fontWeight: '700', letterSpacing: '0.08em', marginBottom: 20 }}>JOIN TIME LIMIT</p>
        <div style={{ display: 'flex', gap: '20px', marginBottom: 80 }}>
          <div style={{ flex: 1, background: 'white', border: '2px solid #f2f4f7', borderRadius: '25px', padding: '24px 0', textAlign: 'center', color: '#475467', fontSize: 26, fontWeight: '700' }}>2 min</div>
          <div style={{ flex: 1, background: '#273545', border: '2px solid #273545', borderRadius: '25px', padding: '24px 0', textAlign: 'center', color: 'white', fontSize: 26, fontWeight: '700', boxShadow: '0 10px 20px rgba(39,53,69,0.3)' }}>5 min</div>
          <div style={{ flex: 1, background: 'white', border: '2px solid #f2f4f7', borderRadius: '25px', padding: '24px 0', textAlign: 'center', color: '#475467', fontSize: 26, fontWeight: '700' }}>10 min</div>
        </div>

        {/* Bottom Button */}
        <div style={{ 
          background: 'linear-gradient(90deg, #65b7b0, #1e787c)', 
          borderRadius: '30px', padding: '36px 0', width: '100%', 
          textAlign: 'center', color: 'white', fontSize: 30, fontWeight: '700',
          boxShadow: '0 15px 30px rgba(30,120,124,0.3)'
        }}>
          ✨ Launch Outing Session
        </div>

      </div>
    </AbsoluteFill>
  );
};
