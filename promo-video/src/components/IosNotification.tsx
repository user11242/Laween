import React from 'react';
import { Img, staticFile } from 'remotion';

export interface IosNotificationProps {
  title: string;
  subtitle: string;
}

export const IosNotification: React.FC<IosNotificationProps> = ({ title, subtitle }) => {
  return (
    <div style={{
      width: '100%',
      // Realistic iOS lock-screen/banner notification style:
      background: 'rgba(28, 28, 30, 0.65)',
      backdropFilter: 'blur(25px)',
      WebkitBackdropFilter: 'blur(25px)',
      borderRadius: 24,
      boxShadow: '0 8px 32px rgba(0, 0, 0, 0.25), inset 0 0.5px 0.5px rgba(255, 255, 255, 0.15)',
      padding: '12px 14px 14px 14px',
      display: 'flex',
      flexDirection: 'column',
      gap: 6,
    }}>
      {/* ── HEADER ── */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          {/* App Icon: Small square with rounded corners */}
          <div style={{
             width: 18, height: 18, 
             background: 'linear-gradient(135deg, #13c4aa 0%, #0d9e87 100%)',
             borderRadius: 4.5,
             display: 'flex', justifyContent: 'center', alignItems: 'center',
          }}>
            <span style={{ fontFamily: 'Inter, system-ui, sans-serif', color: 'white', fontSize: 11, fontWeight: 900, lineHeight: 1 }}>W</span>
          </div>
          {/* App/Sender Name */}
          <span style={{ 
            fontFamily: 'system-ui, -apple-system, sans-serif', 
            color: 'rgba(255, 255, 255, 0.6)', 
            fontSize: 13, 
            fontWeight: 400,
            textTransform: 'uppercase', 
            letterSpacing: '0.4px',
          }}>
            LAWEEN
          </span>
        </div>
        {/* Timestamp */}
        <span style={{ 
          fontFamily: 'system-ui, -apple-system, sans-serif', 
          color: 'rgba(255, 255, 255, 0.45)', 
          fontSize: 12,
        }}>
          now
        </span>
      </div>

      {/* ── CONTENT ── */}
      <div style={{ display: 'flex', flexDirection: 'column', paddingLeft: 2 }}>
        <p style={{ 
          fontFamily: 'system-ui, -apple-system, sans-serif', 
          color: 'white', 
          fontSize: 15, 
          fontWeight: 600, 
          margin: 0,
          letterSpacing: '-0.01em',
        }}>
          {title}
        </p>
        {subtitle.split('\n').map((line, i) => (
          <p key={i} style={{ 
            fontFamily: 'system-ui, -apple-system, sans-serif', 
            color: i === 0 ? 'rgba(255, 255, 255, 0.92)' : 'rgba(255,255,255,0.55)', 
            fontSize: i === 0 ? 14.5 : 13, 
            margin: i === 0 ? '2px 0 0' : '1px 0 0',
            fontWeight: 400,
            letterSpacing: '-0.01em',
            lineHeight: 1.3,
          }}>
            {line}
          </p>
        ))}
      </div>
    </div>
  );
};
