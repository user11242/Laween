import { AbsoluteFill, useCurrentFrame, spring, useVideoConfig, interpolate } from 'remotion';
import React from 'react';

export const Scene6DynamicIsland: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  
  const width = spring({ frame: frame - 20, fps, config: { damping: 14 }, from: 200, to: 650 });
  const height = spring({ frame: frame - 25, fps, config: { damping: 13 }, from: 60, to: 220 });
  
  const contentPop = spring({ frame: frame - 40, fps, config: { damping: 14 } });
  
  return (
    <AbsoluteFill style={{ justifyContent: 'flex-start', alignItems: 'center', paddingTop: 100 }}>
      
      {/* Dynamic Island Expand */}
      <div style={{
        backgroundColor: 'black',
        borderRadius: height / 2 < 60 ? height / 2 : 60,
        width,
        height,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        flexDirection: 'column',
        overflow: 'hidden',
        boxShadow: '0 10px 40px rgba(0,0,0,0.8)'
      }}>
        {frame > 30 && (
          <div style={{ 
            width: '85%', 
            display: 'flex', 
            flexDirection: 'column', 
            opacity: interpolate(frame, [30, 45], [0, 1]),
            transform: `scale(${contentPop})`
          }}>
             <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 20, alignItems: 'center' }}>
               <div style={{ display: 'flex', alignItems: 'center' }}>
                 <div style={{ width: 60, height: 60, borderRadius: 30, backgroundColor: '#34d399', marginRight: 15 }} />
                 <div>
                   <p style={{ margin: 0, color: 'rgba(255,255,255,0.6)', fontFamily: 'Inter', fontSize: 20 }}>Live Tracking</p>
                   <h3 style={{ margin: 0, color: 'white', fontFamily: 'Inter', fontSize: 32, fontWeight: 700 }}>Arriving Soon</h3>
                 </div>
               </div>
               <span style={{ color: '#0ea5e9', fontFamily: 'Inter', fontSize: 38, fontWeight: 800 }}>5 min</span>
             </div>

             {/* Glowing Progress Track */}
             <div style={{ width: '100%', height: 12, backgroundColor: '#1e293b', borderRadius: 6, position: 'relative', overflow: 'hidden' }}>
               <div style={{ 
                 position: 'absolute', top: 0, left: 0, height: '100%',
                 width: `${interpolate(frame, [40, 110], [10, 85], { extrapolateRight: 'clamp' })}%`,
                 background: 'linear-gradient(90deg, #0ea5e9, #34d399)', 
                 borderRadius: 6 
               }} />
             </div>
          </div>
        )}
      </div>

      <div style={{ 
        position: 'absolute', bottom: 150, 
        textAlign: 'center',
        opacity: interpolate(frame, [30, 60], [0, 1]) 
      }}>
        <h2 style={{ fontFamily: 'Inter, sans-serif', fontWeight: 800, fontSize: 65, color: 'white', margin: 0 }}>
          Glance and Go.
        </h2>
        <p style={{ fontFamily: 'Inter, sans-serif', fontSize: 32, color: '#94a3b8', margin: '20px 0 0 0' }}>
          Smart ETA tracking right from your homescreen.
        </p>
      </div>

    </AbsoluteFill>
  );
};
