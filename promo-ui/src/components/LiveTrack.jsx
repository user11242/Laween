import React from 'react';
import { Navigation } from 'lucide-react';

export default function LiveTrack() {
  return (
    <div style={{
      width: '100%', height: '100vh', background: 'linear-gradient(180deg, #0a1f24, #051417)', 
      position: 'relative', fontFamily: "'Inter', sans-serif", overflow: 'hidden'
    }}>
      {/* Dynamic Island Replica */}
      <div style={{
        position: 'absolute', top: 12, left: '50%', transform: 'translateX(-50%)', 
        background: '#000', borderRadius: 20, width: 140, height: 32, display: 'flex', 
        alignItems: 'center', justifyContent: 'space-between', padding: '0 12px', 
        boxShadow: '0 5px 15px rgba(0,0,0,0.6)', zIndex: 20
      }}>
        <div style={{display: 'flex', alignItems: 'center', gap: 6}}>
            <div style={{width: 14, height: 14, background: '#7cc3ce', borderRadius: '50%', border: '1px solid #111'}}></div>
            <span style={{color: '#7cc3ce', fontSize: '10px', fontWeight: 700}}>Sarah</span>
        </div>
        <div style={{display: 'flex', alignItems: 'center', gap: 4}}>
            <span style={{color: '#fff', fontSize: '9px', fontWeight: 800}}>4 min</span>
            <Navigation color="#fff" size={10} strokeWidth={3} />
        </div>
      </div>
      
      {/* Lock screen time */}
      <div style={{
        marginTop: 60, textAlign: 'center', color: 'rgba(255,255,255,0.9)', 
        fontWeight: 300, fontSize: '4rem', letterSpacing: 1
      }}>
        09:41
      </div>
      
      {/* Lock screen widget */}
      <div style={{
        marginTop: 15, background: 'rgba(0,0,0,0.4)', backdropFilter: 'blur(10px)', 
        WebkitBackdropFilter: 'blur(10px)', borderRadius: 16, padding: 12, 
        border: '1px solid rgba(255,255,255,0.1)', width: '85%', margin: '0 auto'
      }}>
        <div style={{display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 8}}>
            <span style={{color: '#7cc3ce', fontSize: '10px', fontWeight: 700}}>LAWEEN Â· LIVE</span>
            <span style={{color: '#aaa', fontSize: '9px'}}>Updated Just Now</span>
        </div>
        <div style={{display: 'flex', flexDirection: 'column', gap: 10}}>
            <div style={{display: 'flex', alignItems: 'center', gap: 8}}>
                <div style={{width: 24, height: 24, background: '#00697B', borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'white', fontSize: '10px', fontWeight: 'bold'}}>S</div>
                <div style={{flex: 1, background: 'rgba(255,255,255,0.1)', height: 4, borderRadius: 2, overflow: 'hidden'}}>
                  <div style={{width: '80%', background: '#7cc3ce', height: '100%'}}></div>
                </div>
                <span style={{color: 'white', fontSize: '10px', fontWeight: 'bold'}}>1.2km</span>
            </div>
            <div style={{display: 'flex', alignItems: 'center', gap: 8}}>
                <div style={{width: 24, height: 24, background: '#FBBC04', borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'black', fontSize: '10px', fontWeight: 'bold'}}>J</div>
                <div style={{flex: 1, background: 'rgba(255,255,255,0.1)', height: 4, borderRadius: 2, overflow: 'hidden'}}>
                  <div style={{width: '30%', background: '#FBBC04', height: '100%'}}></div>
                </div>
                <span style={{color: 'white', fontSize: '10px', fontWeight: 'bold'}}>4.5km</span>
            </div>
        </div>
      </div>
    </div>
  );
}
