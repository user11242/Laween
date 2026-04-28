import { Img, staticFile, interpolate, Easing } from 'remotion';
import React from 'react';

export const SplashAppUI: React.FC<{ localFrame: number }> = ({ localFrame }) => {
  // Orb 1: 120 frames (4s), EaseInOutSine
  const orb1Progress = (Math.sin((localFrame / 120) * Math.PI - Math.PI / 2) + 1) / 2;
  const orb1X = orb1Progress * 50;
  const orb1Y = orb1Progress * 50;

  // Orb 2: 150 frames (5s), EaseInOut
  const orb2Progress = (Math.sin((localFrame / 150) * Math.PI - Math.PI / 2) + 1) / 2;
  const orb2X = orb2Progress * -80;
  const orb2Y = orb2Progress * -40;

  // Logo Animation
  // Elastic out scale 0->1 over 36 frames
  const logoScale = interpolate(localFrame, [0, 36], [0, 1], {
    easing: Easing.elastic(1.5),
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  // Rotate easeOutBack 0.5 turn -> 0 over 30 frames
  const logoRotate = interpolate(localFrame, [0, 30], [0.5, 0], {
    easing: Easing.bezier(0.175, 0.885, 0.32, 1.275), // similar to easeOutBack
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  // Float slideY over 4 seconds (120 frames), between 0 and -4.2px, starts after shimmer (frame 87)
  const floatProgress = localFrame >= 87 
    ? (Math.sin(((localFrame - 87) / 60 - 0.5) * Math.PI) + 1) / 2 
    : 0;
  const logoFloat = floatProgress * -4.2;

  // Logo Shimmer (starts at frame 42, duration 45)
  const logoShimmerPos = interpolate(localFrame, [42, 87], [-100, 200], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  // "Laween" Title
  const titleOp = interpolate(localFrame, [24, 48], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const titleY = interpolate(localFrame, [24, 48], [10, 0], {
    easing: Easing.bezier(0.165, 0.84, 0.44, 1), // easeOutQuart
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  
  // Title Shimmer (starts at frame 51, duration 36)
  const titleShimmerPos = interpolate(localFrame, [51, 87], [-100, 200], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  // Subtitle "Where do we go next?"
  const subOp = interpolate(localFrame, [48, 78], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const subBlur = interpolate(localFrame, [48, 78], [10, 0], {
    easing: Easing.ease,
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  return (
    <div style={{
      position: 'absolute', inset: 0,
      background: 'linear-gradient(to bottom left, #83C5BE, #006D77)',
      overflow: 'hidden',
      display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center'
    }}>
      
      {/* Orb 1 */}
      <div style={{
        position: 'absolute', top: -100, left: -50,
        width: 300, height: 300,
        borderRadius: '50%',
        backgroundColor: 'rgba(238, 229, 147, 0.15)',
        boxShadow: '0 0 40px 10px rgba(238, 229, 147, 0.15)',
        transform: `translate(${orb1X}px, ${orb1Y}px)`
      }} />

      {/* Orb 2 */}
      <div style={{
        position: 'absolute', bottom: -50, right: -100,
        width: 400, height: 400,
        borderRadius: '50%',
        backgroundColor: 'rgba(255, 255, 255, 0.1)',
        boxShadow: '0 0 50px 10px rgba(255, 255, 255, 0.1)',
        transform: `translate(${orb2X}px, ${orb2Y}px)`
      }} />

      {/* Foreground Container */}
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', zIndex: 10 }}>
        
        {/* Logo */}
        <div style={{
          position: 'relative', width: 140, height: 140,
          transform: `scale(${logoScale}) rotate(${logoRotate}turn) translateY(${logoFloat}px)`
        }}>
          <Img src={staticFile('app_pin_logo.png')} style={{ width: '100%', height: '100%', objectFit: 'contain' }} />
          
          {/* Logo Shimmer */}
          {localFrame >= 42 && localFrame <= 87 && (
            <div style={{
              position: 'absolute', inset: 0,
              background: 'linear-gradient(110deg, transparent 0%, rgba(255,255,255,0.8) 50%, transparent 100%)',
              backgroundSize: '200% 100%',
              backgroundPosition: `${logoShimmerPos}% 0`,
              maskImage: `url(${staticFile('app_pin_logo.png')})`,
              WebkitMaskImage: `url(${staticFile('app_pin_logo.png')})`,
              maskSize: 'contain',
              WebkitMaskSize: 'contain',
              maskRepeat: 'no-repeat',
              WebkitMaskRepeat: 'no-repeat',
              maskPosition: 'center',
              WebkitMaskPosition: 'center',
            }} />
          )}
        </div>

        <div style={{ height: 32 }} />

        {/* Title */}
        <div style={{ position: 'relative', transform: `translateY(${titleY}px)`, opacity: titleOp }}>
          <h1 style={{
            fontFamily: '"Outfit", system-ui, sans-serif',
            fontSize: 48, fontWeight: 900,
            color: 'white', letterSpacing: '3px',
            lineHeight: 1.0, margin: 0, textAlign: 'center'
          }}>
            Laween
          </h1>
          
          {/* Title Shimmer overlay */}
          {localFrame >= 51 && localFrame <= 87 && (
            <h1 style={{
              fontFamily: '"Outfit", system-ui, sans-serif',
              fontSize: 48, fontWeight: 900,
              letterSpacing: '3px',
              lineHeight: 1.0, margin: 0, textAlign: 'center',
              position: 'absolute', top: 0, left: 0, right: 0,
              color: 'transparent',
              backgroundImage: 'linear-gradient(110deg, transparent 0%, #EEE593 50%, transparent 100%)',
              backgroundClip: 'text',
              WebkitBackgroundClip: 'text',
              backgroundSize: '200% 100%',
              backgroundPosition: `${titleShimmerPos}% 0`
            }}>
              Laween
            </h1>
          )}
        </div>

        <div style={{ height: 8 }} />

        {/* Subtitle */}
        <p style={{
          fontFamily: '"Inter", system-ui, sans-serif',
          fontSize: 18, fontWeight: 300,
          color: 'rgba(255,255,255,0.9)',
          letterSpacing: '1px',
          margin: 0, textAlign: 'center',
          opacity: subOp,
          filter: `blur(${subBlur}px)`
        }}>
          Where do we go next?
        </p>

      </div>
    </div>
  );
};
