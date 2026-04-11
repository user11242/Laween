import { AbsoluteFill, useCurrentFrame, spring, useVideoConfig } from 'remotion';

export const Scene3JoinGroup: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const pop = spring({ frame, fps, config: { damping: 12 } });

  return (
    <AbsoluteFill style={{ justifyContent: 'center', alignItems: 'center' }}>
      <h2 style={{ fontSize: 60, color: 'white' }}>Scan or Type.</h2>
      <div style={{
        marginTop: 50,
        width: 400,
        height: 200,
        backgroundColor: '#1E293B',
        borderRadius: 20,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-around',
        transform: `scale(${pop})`
      }}>
         <div style={{width: 100, height: 100, backgroundColor: 'white', borderRadius: 8}}></div>
         <h1 style={{color: '#4facfe', letterSpacing: 10}}>89X2</h1>
      </div>
      <p style={{ marginTop: 20, fontSize: 30, opacity: 0.7 }}>You're in the group in seconds.</p>
    </AbsoluteFill>
  );
};
