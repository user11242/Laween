import { AbsoluteFill, interpolate, useCurrentFrame } from 'remotion';

export const Scene2Security: React.FC = () => {
  const frame = useCurrentFrame();
  const y = interpolate(frame, [0, 20], [100, 0], { extrapolateRight: 'clamp' });

  return (
    <AbsoluteFill style={{ justifyContent: 'center', alignItems: 'center', transform: `translateY(${y}px)` }}>
      <h2 style={{ fontSize: 60, color: '#4facfe' }}>Seamlessly Secure</h2>
      <div style={{
        marginTop: 40,
        width: 150, height: 150,
        border: '4px solid #4facfe',
        borderRadius: 40,
        display: 'flex', justifyContent: 'center', alignItems: 'center'
      }}>
        <span style={{ fontSize: 80, filter: 'drop-shadow(0 0 10px #4facfe)' }}>👤</span>
      </div>
    </AbsoluteFill>
  );
};
