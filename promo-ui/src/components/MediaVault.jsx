import React from 'react';
import { MoreHorizontal, Image as ImageIcon, Film, Camera, Upload } from 'lucide-react';

export default function MediaVault() {
  return (
    <div style={{
        width: '100%', height: '100vh', background: '#051417', 
        display: 'flex', flexDirection: 'column', fontFamily: "'Inter', sans-serif"
    }}>
        <div style={{
            padding: '40px 15px 15px', background: 'linear-gradient(180deg, rgba(124,195,206,0.1) 0%, transparent 100%)', 
            display: 'flex', flexDirection: 'column'
        }}>
            <h4 style={{
                color: 'white', fontSize: '14px', margin: '0 0 4px 0', 
                display: 'flex', alignItems: 'center', justifyContent: 'space-between'
            }}>
                Shared Vault <MoreHorizontal color="#7cc3ce" size={18} />
            </h4>
            <p style={{color: '#7cc3ce', fontSize: '10px', margin: 0, textAlign: 'left'}}>
                Downtown Cafe Â· 12 items
            </p>
        </div>
        
        {/* Image Grid Array */}
        <div style={{
            padding: '0 15px', display: 'grid', gridTemplateColumns: '1fr 1fr', 
            gap: 8, overflow: 'hidden'
        }}>
            <div style={{background: 'linear-gradient(45deg, #1A2930, #2E454D)', height: 90, borderRadius: 10, display: 'flex', alignItems: 'center', justifyContent: 'center'}}>
                <ImageIcon color="rgba(255,255,255,0.2)" size={24} />
            </div>
            <div style={{background: 'linear-gradient(135deg, #2E454D, #1A2930)', height: 120, borderRadius: 10, display: 'flex', alignItems: 'center', justifyContent: 'center'}}>
                 <Film color="rgba(255,255,255,0.2)" size={24} />
            </div>
            <div style={{background: 'linear-gradient(45deg, #0d1e21, #1a2a30)', height: 100, borderRadius: 10, marginTop: -30, display: 'flex', alignItems: 'center', justifyContent: 'center'}}>
                <ImageIcon color="rgba(255,255,255,0.2)" size={20} />
            </div>
            <div style={{background: 'linear-gradient(220deg, #1A2930, #00697B)', height: 90, borderRadius: 10, display: 'flex', alignItems: 'center', justifyContent: 'center'}}>
                <Camera color="rgba(255,255,255,0.2)" size={24} />
            </div>
            <div style={{background: 'linear-gradient(90deg, #1A2930, #2E454D)', height: 90, borderRadius: 10, display: 'flex', alignItems: 'center', justifyContent: 'center'}}>
                <ImageIcon color="rgba(255,255,255,0.2)" size={24} />
            </div>
        </div>
        
        <div style={{
            position: 'absolute', bottom: 25, left: '50%', transform: 'translateX(-50%)', 
            background: '#7cc3ce', color: '#051417', padding: '12px 24px', borderRadius: 30, 
            display: 'flex', alignItems: 'center', gap: 8, fontWeight: 800, fontSize: '10px', 
            boxShadow: '0 10px 20px rgba(124,195,206,0.3)', whiteSpace: 'nowrap'
        }}>
            <Upload size={16} strokeWidth={3} /> Upload Media
        </div>
    </div>
  );
}
