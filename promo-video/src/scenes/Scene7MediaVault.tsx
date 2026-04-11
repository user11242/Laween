import { AbsoluteFill, useCurrentFrame, useVideoConfig, spring, interpolate } from 'remotion';
import React from 'react';

export const Scene7MediaVault: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  
  const iconScale = spring({ frame: frame - 10, fps, config: { damping: 12 } });
  const photo1Pop = spring({ frame: frame - 30, fps, config: { damping: 10 } });
  const photo2Pop = spring({ frame: frame - 45, fps, config: { damping: 10 } });
  
  return (
    <AbsoluteFill style={{ justifyContent: 'center', alignItems: 'center' }}>
      
      <div style={{ position: 'relative', width: 400, height: 400, display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
        
        {/* Vault Icon container */}
        <div style={{ 
          width: 200, height: 200, 
          backgroundColor: 'rgba(15, 23, 42, 0.8)', 
          borderRadius: 40, 
          zIndex: 10, 
          display: 'flex', justifyContent: 'center', alignItems: 'center', 
          border: '1px solid rgba(255,255,255,0.1)',
          boxShadow: '0 30px 60px rgba(0,0,0,0.8)',
          transform: `scale(${iconScale})`
        }}>
          {/* Internal glowing circle ring like the passport outline inspo */}
          <div style={{
            width: 120, height: 120,
            borderRadius: 60,
            border: '4px dashed #0ea5e9',
            display: 'flex', justifyContent: 'center', alignItems: 'center',
            boxShadow: '0 0 20px rgba(14, 165, 233, 0.4)',
          }}>
            <span style={{ fontSize: 50 }}>📸</span>
          </div>
        </div>
        
        {/* Stylized photos drawn into the vault */}
        {frame > 30 && (
          <div style={{ 
            position: 'absolute', width: 140, height: 180, backgroundColor: '#f1f5f9', 
            borderRadius: 16, border: '8px solid white', zIndex: 1, boxShadow: '0 20px 40px rgba(0,0,0,0.5)',
            transform: `scale(${photo1Pop}) translate(-140px, -120px) rotate(-15deg)`, 
          }} />
        )}
        
        {frame > 45 && (
          <div style={{ 
            position: 'absolute', width: 140, height: 180, backgroundColor: '#cbd5e1', 
            borderRadius: 16, border: '8px solid white', zIndex: 2, boxShadow: '0 20px 40px rgba(0,0,0,0.5)',
            transform: `scale(${photo2Pop}) translate(140px, -140px) rotate(20deg)`, 
          }} />
        )}

      </div>

      <h2 style={{ 
        fontFamily: 'Inter, sans-serif', fontSize: 60, fontWeight: 800, color: 'white', 
        marginTop: 60, textAlign: 'center',
        opacity: interpolate(frame, [20, 50], [0, 1])
      }}>
        The night ends.<br/>
        <span style={{ color: '#0ea5e9' }}>The memories stay.</span>
      </h2>
    </AbsoluteFill>
  );
};
