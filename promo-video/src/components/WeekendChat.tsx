// Copied from Scene5OutingBegins.tsx to reuse locally
import React from 'react';
import { Img, staticFile } from 'remotion';

export const WeekendChat: React.FC<{ chatShift: number }> = ({ chatShift }) => (
  <div style={{ position: 'absolute', inset: 0, backgroundColor: '#f6f7f9', display: 'flex', flexDirection: 'column', transform: `translateY(${-chatShift}px)` }}>
    {/* Header */}
    <div style={{ backgroundColor: 'white', padding: '46px 16px 14px', display: 'flex', alignItems: 'center', gap: 12, boxShadow: '0 1px 4px rgba(0,0,0,0.04)', zIndex: 10, flexShrink: 0 }}>
      <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#1e293b" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" style={{ flexShrink: 0 }}><path d="M15 18l-6-6 6-6" /></svg>
      <div style={{ width: 42, height: 42, borderRadius: 21, background: '#f59e0b', display: 'flex', justifyContent: 'center', alignItems: 'center', flexShrink: 0 }}>
        <span style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 18, fontWeight: 800, color: 'white' }}>W</span>
      </div>
      <div style={{ flex: 1 }}>
        <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 17, fontWeight: 700, color: '#1e293b', margin: 0 }}>Weekend Plans 🎉</p>
        <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 13, color: '#94a3b8', margin: '1px 0 0' }}>4 members</p>
      </div>
      <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#0d7975" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
        <circle cx="18" cy="5" r="3" /><circle cx="6" cy="12" r="3" /><circle cx="18" cy="19" r="3" />
        <line x1="8.59" y1="13.51" x2="15.42" y2="17.49" /><line x1="15.41" y1="6.51" x2="8.59" y2="10.49" />
      </svg>
      <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#0d7975" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" style={{ marginLeft: 4 }}>
        <circle cx="12" cy="12" r="10" /><line x1="12" y1="16" x2="12" y2="12" /><line x1="12" y1="8" x2="12.01" y2="8" />
      </svg>
    </div>

    {/* Messages — all fully visible, no entry animations */}
    <div style={{ flex: 1, padding: '12px 14px 8px', display: 'flex', flexDirection: 'column', gap: 10, overflow: 'hidden' }}>
      {/* Ahmed */}
      <div style={{ display: 'flex', alignItems: 'flex-end', gap: 8 }}>
        <div style={{ width: 28, height: 28, borderRadius: 14, background: '#f59e0b', display: 'flex', justifyContent: 'center', alignItems: 'center', flexShrink: 0 }}>
          <span style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 12, fontWeight: 800, color: 'white' }}>A</span>
        </div>
        <div>
          <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 11, color: '#94a3b8', margin: '0 0 3px 4px', fontWeight: 500 }}>Ahmed</p>
          <div style={{ background: 'white', borderRadius: '16px 16px 16px 4px', padding: '9px 13px', boxShadow: '0 2px 8px rgba(0,0,0,0.06)' }}>
            <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 15, color: '#1e293b', margin: 0, lineHeight: 1.4 }}>Let's plan for tonight! 🎉</p>
          </div>
        </div>
      </div>
      {/* User */}
      <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
        <div style={{ background: '#0d7975', borderRadius: '16px 16px 4px 16px', padding: '9px 13px', boxShadow: '0 2px 8px rgba(13,121,117,0.2)', maxWidth: 210 }}>
          <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 15, color: 'white', margin: 0, lineHeight: 1.4 }}>I'm down! Where should we meet? 🙌</p>
        </div>
      </div>
      {/* Sarah */}
      <div style={{ display: 'flex', alignItems: 'flex-end', gap: 8 }}>
        <div style={{ width: 28, height: 28, borderRadius: 14, background: '#a78bfa', display: 'flex', justifyContent: 'center', alignItems: 'center', flexShrink: 0 }}>
          <span style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 12, fontWeight: 800, color: 'white' }}>S</span>
        </div>
        <div>
          <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 11, color: '#94a3b8', margin: '0 0 3px 4px', fontWeight: 500 }}>Sarah</p>
          <div style={{ background: 'white', borderRadius: '16px 16px 16px 4px', padding: '9px 13px', boxShadow: '0 2px 8px rgba(0,0,0,0.06)' }}>
            <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 15, color: '#1e293b', margin: 0, lineHeight: 1.4 }}>Restaurant or a cafe? 🍕</p>
          </div>
        </div>
      </div>
      {/* Ahmed photo — matches Scene2Ecosystem exactly */}
      <div style={{ display: 'flex', alignItems: 'flex-end', gap: 8 }}>
        <div style={{ width: 28, height: 28, borderRadius: 14, background: '#f59e0b', display: 'flex', justifyContent: 'center', alignItems: 'center', flexShrink: 0 }}>
          <span style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 12, fontWeight: 800, color: 'white' }}>A</span>
        </div>
        <div>
          <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 11, color: '#94a3b8', margin: '0 0 3px 4px', fontWeight: 500 }}>Ahmed</p>
          <div style={{ borderRadius: '16px 16px 16px 4px', overflow: 'hidden', boxShadow: '0 3px 12px rgba(0,0,0,0.12)', width: 186 }}>
            <Img src={staticFile('shared_image.jpg')} style={{ width: '100%', height: 124, objectFit: 'cover', display: 'block' }} alt="" />
            <div style={{ background: 'white', padding: '6px 10px 8px' }}>
              <span style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 12, color: '#64748b' }}>What about this place? ☕</span>
            </div>
          </div>
        </div>
      </div>
      {/* Location card — matches Scene2Ecosystem exactly */}
      <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
        <div style={{ background: '#0d7975', borderRadius: 14, overflow: 'hidden', boxShadow: '0 4px 14px rgba(13,121,117,0.25)', width: 188 }}>
          <div style={{ height: 76, background: 'linear-gradient(135deg,#0a5c5a,#0d7975,#14b8a6)', display: 'flex', justifyContent: 'center', alignItems: 'center', position: 'relative' }}>
            <div style={{ position: 'absolute', inset: 0, opacity: 0.12 }}>
              {[25, 50, 75].map(p => <div key={p} style={{ position: 'absolute', top: `${p}%`, left: 0, right: 0, height: 1, background: 'white' }} />)}
              {[33, 66].map(p => <div key={p} style={{ position: 'absolute', left: `${p}%`, top: 0, bottom: 0, width: 1, background: 'white' }} />)}
            </div>
            <div style={{ width: 30, height: 30, borderRadius: 15, background: 'white', display: 'flex', justifyContent: 'center', alignItems: 'center', boxShadow: '0 3px 10px rgba(0,0,0,0.2)', zIndex: 1 }}>
              <svg width="15" height="15" viewBox="0 0 24 24" fill="#0d7975"><path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7z" /></svg>
            </div>
          </div>
          <div style={{ padding: '9px 12px 11px' }}>
            <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 13, fontWeight: 700, color: 'white', margin: '0 0 2px' }}>📍 Current Location Sent</p>
            <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 11, color: 'rgba(255,255,255,0.6)', margin: 0 }}>4 friends · Tap to open</p>
          </div>
        </div>
      </div>
    </div>

    {/* Input bar */}
    <div style={{ padding: '10px 14px 28px', backgroundColor: 'white', display: 'flex', alignItems: 'center', gap: 10, boxShadow: '0 -1px 8px rgba(0,0,0,0.04)', flexShrink: 0 }}>
      {/* + button — scale animated externally via chatShift context */}
      <div id="scene5-plus-btn" style={{ width: 38, height: 38, borderRadius: 19, backgroundColor: '#f1f5f9', display: 'flex', justifyContent: 'center', alignItems: 'center', flexShrink: 0 }}>
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#64748b" strokeWidth="2.5" strokeLinecap="round"><line x1="12" y1="5" x2="12" y2="19" /><line x1="5" y1="12" x2="19" y2="12" /></svg>
      </div>
      <div style={{ flex: 1, height: 38, borderRadius: 19, border: '1.5px solid #e2e8f0', display: 'flex', alignItems: 'center', paddingLeft: 14, background: '#fafafa' }}>
        <span style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 14, color: '#94a3b8' }}>Type a message...</span>
      </div>
      <div style={{ width: 38, height: 38, borderRadius: 19, backgroundColor: '#0d7975', display: 'flex', justifyContent: 'center', alignItems: 'center', flexShrink: 0 }}>
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" style={{ transform: 'rotate(45deg)', marginLeft: -2 }}>
          <line x1="22" y1="2" x2="11" y2="13" /><polygon points="22 2 15 22 11 13 2 9 22 2" />
        </svg>
      </div>
    </div>
  </div>
);