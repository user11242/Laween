// Copied from Scene5OutingBegins.tsx to reuse locally
import React from 'react';
import { Img, staticFile } from 'remotion';

export const WeekendChat: React.FC<{ chatShift?: number; children?: React.ReactNode }> = ({ chatShift = 0, children }) => (
  <div style={{ position: 'absolute', inset: 0, backgroundColor: '#F5F6F8', display: 'flex', flexDirection: 'column' }}>
    {/* Header - Fidelity Matched */}
    <div style={{ backgroundColor: 'white', padding: '46px 16px 14px', display: 'flex', alignItems: 'center', gap: 12, boxShadow: '0 1px 4px rgba(0,0,0,0.04)', zIndex: 10, flexShrink: 0 }}>
      <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#1e293b" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" style={{ flexShrink: 0 }}><path d="M15 18l-6-6 6-6" /></svg>
      <div style={{ width: 42, height: 42, borderRadius: 21, background: '#f59e0b', display: 'flex', justifyContent: 'center', alignItems: 'center', flexShrink: 0 }}>
        <span style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 18, fontWeight: 800, color: 'white' }}>W</span>
      </div>
      <div style={{ flex: 1 }}>
        <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 17, fontWeight: 800, color: '#1e293b', margin: 0 }}>Weekend Plans 🎉</p>
        <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 13, color: '#94a3b8', margin: '1px 0 0' }}>4 members</p>
      </div>
      <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#006D77" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
        <circle cx="18" cy="5" r="3" /><circle cx="6" cy="12" r="3" /><circle cx="18" cy="19" r="3" />
        <line x1="8.59" y1="13.51" x2="15.42" y2="17.49" /><line x1="15.41" y1="6.51" x2="8.59" y2="10.49" />
      </svg>
      <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#006D77" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" style={{ marginLeft: 8 }}>
        <circle cx="12" cy="12" r="10" /><line x1="12" y1="16" x2="12" y2="12" /><line x1="12" y1="8" x2="12.01" y2="8" />
      </svg>
    </div>

    {/* Messages Area - fully visible, scrolled up by 200px to show the latest message */}
    <div style={{ flex: 1, padding: '16px 14px 8px', overflow: 'hidden' }}>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 12, transform: `translateY(${-200 - chatShift}px)` }}>
      
      {/* Date Pill */}
      <div style={{ display: 'flex', justifyContent: 'center', marginBottom: 4 }}>
        <div style={{ background: 'white', padding: '4px 12px', borderRadius: 12, boxShadow: '0 1px 2px rgba(0,0,0,0.02)' }}>
          <span style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 12, color: '#64748b', fontWeight: 600 }}>Yesterday</span>
        </div>
      </div>

      {/* Ahmed base */}
      <div style={{ display: 'flex', alignItems: 'flex-end', gap: 8 }}>
        <div style={{ width: 28, height: 28, borderRadius: 14, background: '#f59e0b', display: 'flex', justifyContent: 'center', alignItems: 'center', flexShrink: 0, marginBottom: 2 }}>
          <span style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 12, fontWeight: 800, color: 'white' }}>A</span>
        </div>
        <div style={{ background: 'white', borderRadius: '4px 16px 16px 16px', padding: '8px 12px', boxShadow: '0 1px 2px rgba(0,0,0,0.03)', maxWidth: '80%' }}>
          <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 12, color: '#006D77', margin: '0 0 2px 0', fontWeight: 700 }}>Ahmed</p>
          <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 15, color: '#1e293b', margin: 0, lineHeight: 1.4 }}>Let's plan for tonight! 🎉</p>
          <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 11, color: '#94a3b8', margin: '4px 0 0 0' }}>03:57 AM</p>
        </div>
      </div>

      {/* User reply */}
      <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
        <div style={{ background: 'linear-gradient(135deg, #83C5BE, #006D77)', borderRadius: '16px 4px 16px 16px', padding: '8px 12px', boxShadow: '0 2px 6px rgba(0,109,119,0.15)', maxWidth: '80%' }}>
          <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 15, color: 'white', margin: 0, lineHeight: 1.4 }}>I'm down! Where should we meet? 👀</p>
          <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 11, color: 'rgba(255,255,255,0.75)', margin: '4px 0 0 0', textAlign: 'right' }}>03:58 AM <span style={{color: '#83C5BE', letterSpacing: '-0.25em', paddingRight: 4}}>✔✔</span></p>
        </div>
      </div>

      {/* Sarah */}
      <div style={{ display: 'flex', alignItems: 'flex-end', gap: 8 }}>
        <div style={{ width: 28, height: 28, borderRadius: 14, background: '#a78bfa', display: 'flex', justifyContent: 'center', alignItems: 'center', flexShrink: 0, marginBottom: 2 }}>
          <span style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 12, fontWeight: 800, color: 'white' }}>S</span>
        </div>
        <div style={{ background: 'white', borderRadius: '4px 16px 16px 16px', padding: '8px 12px', boxShadow: '0 1px 2px rgba(0,0,0,0.03)', maxWidth: '80%' }}>
          <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 12, color: '#006D77', margin: '0 0 2px 0', fontWeight: 700 }}>Sarah</p>
          <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 15, color: '#1e293b', margin: 0, lineHeight: 1.4 }}>Restaurant or a cafe? 🍕</p>
          <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 11, color: '#94a3b8', margin: '4px 0 0 0' }}>04:19 AM</p>
        </div>
      </div>

      {/* CHAT EVENT 1: Photo */}
      <div style={{ display: 'flex', alignItems: 'flex-end', gap: 8 }}>
        <div style={{ width: 28, height: 28, borderRadius: 14, background: '#f59e0b', display: 'flex', justifyContent: 'center', alignItems: 'center', flexShrink: 0, marginBottom: 2 }}>
          <span style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 12, fontWeight: 800, color: 'white' }}>A</span>
        </div>
        <div style={{ background: 'white', borderRadius: '4px 16px 16px 16px', padding: '4px', boxShadow: '0 1px 2px rgba(0,0,0,0.03)', maxWidth: '80%' }}>
          <img src={staticFile('shared_image.jpg')} style={{ width: 200, height: 130, objectFit: 'cover', borderRadius: '4px 12px 4px 4px', display: 'block' }} alt="" />
          <div style={{ padding: '6px 8px' }}>
            <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 15, color: '#1e293b', margin: 0, lineHeight: 1.4 }}>What about this place? 🧋</p>
            <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 11, color: '#94a3b8', margin: '4px 0 0 0' }}>12:20 PM</p>
          </div>
        </div>
      </div>

      {/* NEW CHAT EVENT: Context */}
      <div style={{ display: 'flex', alignItems: 'flex-end', gap: 8 }}>
        <div style={{ width: 28, height: 28, borderRadius: 14, background: '#a78bfa', display: 'flex', justifyContent: 'center', alignItems: 'center', flexShrink: 0, marginBottom: 2 }}>
          <span style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 12, fontWeight: 800, color: 'white' }}>S</span>
        </div>
        <div style={{ background: 'white', borderRadius: '4px 16px 16px 16px', padding: '8px 12px', boxShadow: '0 1px 2px rgba(0,0,0,0.03)', maxWidth: '80%' }}>
          <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 12, color: '#006D77', margin: '0 0 2px 0', fontWeight: 700 }}>Sarah</p>
          <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 15, color: '#1e293b', margin: 0, lineHeight: 1.4 }}>I'll send my location.</p>
          <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 11, color: '#94a3b8', margin: '4px 0 0 0' }}>12:22 PM</p>
        </div>
      </div>

      {/* CHAT EVENT 2: Location card */}
      <div style={{ display: 'flex', alignItems: 'flex-end', gap: 8 }}>
        <div style={{ width: 28, height: 28, borderRadius: 14, background: '#a78bfa', display: 'flex', justifyContent: 'center', alignItems: 'center', flexShrink: 0, marginBottom: 2 }}>
          <span style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 12, fontWeight: 800, color: 'white' }}>S</span>
        </div>
        <div style={{ background: 'white', borderRadius: '4px 16px 16px 16px', overflow: 'hidden', boxShadow: '0 1px 3px rgba(0,0,0,0.04)', width: 220 }}>
          <div style={{ height: 80, background: 'linear-gradient(135deg, #a78bfa, #8b5cf6)', display: 'flex', justifyContent: 'center', alignItems: 'center', position: 'relative' }}>
            <div style={{ position: 'absolute', inset: 0, opacity: 0.15 }}>
              {[25, 50, 75].map(p => <div key={p} style={{ position: 'absolute', top: `${p}%`, left: 0, right: 0, height: 1, background: 'white' }} />)}
              {[33, 66].map(p => <div key={p} style={{ position: 'absolute', left: `${p}%`, top: 0, bottom: 0, width: 1, background: 'white' }} />)}
            </div>
            <div style={{ width: 34, height: 34, borderRadius: 17, background: 'white', display: 'flex', justifyContent: 'center', alignItems: 'center', boxShadow: '0 4px 12px rgba(0,0,0,0.15)', zIndex: 1 }}>
              <svg width="18" height="18" viewBox="0 0 24 24" fill="#8b5cf6"><path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7z" /></svg>
            </div>
          </div>
          <div style={{ padding: '10px 12px' }}>
            <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 12, color: '#8b5cf6', margin: '0 0 2px 0', fontWeight: 700 }}>Sarah</p>
            <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 14, fontWeight: 700, color: '#1e293b', margin: '0 0 2px' }}>Current Location</p>
            <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 12, color: '#64748b', margin: 0 }}>Tap to open</p>
            <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 11, color: '#94a3b8', margin: '6px 0 0 0' }}>12:25 PM</p>
          </div>
        </div>
      </div>

      {/* Typing Message Sent */}
      <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
        <div style={{ background: 'linear-gradient(135deg, #83C5BE, #006D77)', borderRadius: '16px 4px 16px 16px', padding: '8px 12px', boxShadow: '0 2px 6px rgba(0,109,119,0.15)', maxWidth: '80%' }}>
          <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 15, color: 'white', margin: 0, lineHeight: 1.4 }}>Let's start an outing session.</p>
          <p style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 11, color: 'rgba(255,255,255,0.75)', margin: '4px 0 0 0', textAlign: 'right' }}>12:27 PM <span style={{color: '#83C5BE', letterSpacing: '-0.25em', paddingRight: 4}}>✔✔</span></p>
        </div>
      </div>

      {children}
     </div>
    </div>

    {/* Input bar - High Fidelity Floating Pill */}
    <div style={{ padding: '8px 16px 24px', backgroundColor: 'transparent', flexShrink: 0 }}>
      <div style={{ display: 'flex', alignItems: 'center', backgroundColor: 'white', borderRadius: 30, padding: '6px 6px 6px 12px', boxShadow: '0 4px 16px rgba(0,0,0,0.06)' }}>
        {/* Plus button — id='scene5-plus-btn' is used in Scene5 for the glow animation overlay */}
        <div id="scene5-plus-btn" style={{ width: 32, height: 32, borderRadius: 16, backgroundColor: '#e0f2f1', display: 'flex', justifyContent: 'center', alignItems: 'center', flexShrink: 0 }}>
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#006D77" strokeWidth="2.5" strokeLinecap="round"><line x1="12" y1="5" x2="12" y2="19" /><line x1="5" y1="12" x2="19" y2="12" /></svg>
        </div>
        
        {/* Text Input Area */}
        <div style={{ flex: 1, paddingLeft: 12, display: 'flex', alignItems: 'center' }}>
          <span style={{ fontFamily: 'Inter,system-ui,sans-serif', fontSize: 15, color: '#94a3b8' }}>Type a message...</span>
        </div>
        
        {/* Action Button (Mic) */}
        <div style={{ 
          width: 36, height: 36, borderRadius: 18, backgroundColor: '#006D77', 
          display: 'flex', justifyContent: 'center', alignItems: 'center', flexShrink: 0, 
          boxShadow: '0 2px 8px rgba(0,109,119,0.25)',
        }}>
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
            <path d="M12 1a3 3 0 0 0-3 3v8a3 3 0 0 0 6 0V4a3 3 0 0 0-3-3z" /><path d="M19 10v2a7 7 0 0 1-14 0v-2" /><line x1="12" y1="19" x2="12" y2="23" /><line x1="8" y1="23" x2="16" y2="23" />
          </svg>
        </div>
      </div>
    </div>
  </div>
);