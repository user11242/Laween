import { AbsoluteFill, useVideoConfig, useCurrentFrame } from 'remotion';

export const NetworkBackground: React.FC = () => {
  const { width, height } = useVideoConfig();
  const frame = useCurrentFrame();

  return (
    <AbsoluteFill style={{ backgroundColor: '#050714', overflow: 'hidden' }}>
      
      {/* Large radial glow behind everything */}
      <div style={{
        position: 'absolute',
        top: '20%', left: '30%',
        width: 800, height: 800,
        background: 'radial-gradient(circle, rgba(10,50,150,0.15) 0%, rgba(5,7,20,0) 70%)',
        borderRadius: '50%',
        transform: `translate(-50%, -50%) rotate(${frame * 0.1}deg)`,
      }} />

      {/* Subtle Grid Lines */}
      <div style={{
        position: 'absolute',
        width: '100%', height: '100%',
        backgroundImage: `
          linear-gradient(rgba(255,255,255,0.02) 1px, transparent 1px),
          linear-gradient(90deg, rgba(255,255,255,0.02) 1px, transparent 1px)
        `,
        backgroundSize: '100px 100px',
        transform: `translateY(${(frame * 0.5) % 100}px)`,
      }} />

      {/* Abstract overlapping arcs/rings */}
      <div style={{
        position: 'absolute',
        top: '50%', left: '50%',
        width: 1200, height: 1200,
        border: '1px rgba(255,255,255,0.05) solid',
        borderRadius: '50%',
        transform: `translate(-50%, -50%) scale(${1 + (frame * 0.001)})`,
      }} />
      <div style={{
        position: 'absolute',
        top: '50%', left: '50%',
        width: 800, height: 800,
        border: '1px rgba(255,255,255,0.08) solid',
        borderRadius: '50%',
        transform: `translate(-50%, -50%) scale(${1 + (frame * 0.002)})`,
      }} />
    </AbsoluteFill>
  );
};
