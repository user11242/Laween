import React from 'react';
import { User, BellRing, Star, ChevronRight } from 'lucide-react';

export default function Ecosystem() {
  return (
    <div style={{
        width: '100%', height: '100vh', background: '#051417', 
        display: 'flex', flexDirection: 'column', padding: '40px 15px 15px', 
        fontFamily: "'Inter', sans-serif"
    }}>
        {/* Profile Header */}
        <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', marginBottom: 25}}>
            <div style={{
                width: 64, height: 64, borderRadius: '50%', background: 'linear-gradient(135deg, #7cc3ce, #00697B)', 
                marginBottom: 10, display: 'flex', alignItems: 'center', justifyContent: 'center', 
                border: '2px solid rgba(255,255,255,0.1)', boxShadow: '0 5px 15px rgba(124,195,206,0.2)'
            }}>
                <User color="white" size={32} />
            </div>
            <h4 style={{color: 'white', fontSize: '16px', margin: 0, fontWeight: 700}}>Alex Rivers</h4>
            <p style={{color: '#7cc3ce', fontSize: '10px', margin: '2px 0 0 0', fontWeight: 600}}>Pro Member</p>
        </div>
        
        {/* Actionable Notifications / Favorites */}
        <h5 style={{
            color: 'rgba(255,255,255,0.5)', fontSize: '9px', textTransform: 'uppercase', 
            letterSpacing: 1, margin: '0 0 8px 5px', textAlign: 'left'
        }}>
            Recent Alerts
        </h5>
        
        <div style={{display: 'flex', flexDirection: 'column', gap: 10}}>
            <div style={{
                background: 'rgba(255,255,255,0.05)', border: '1px solid rgba(124,195,206,0.3)', 
                borderRadius: 14, padding: 12
            }}>
                <div style={{display: 'flex', justifyContent: 'space-between', marginBottom: 8}}>
                    <span style={{
                        color: 'white', fontSize: '10px', fontWeight: 600, display: 'flex', alignItems: 'center', gap: 4
                    }}>
                        <BellRing color="#7cc3ce" size={12} /> Incoming Prompt
                    </span>
                    <span style={{color: '#aaa', fontSize: '8px'}}>2m ago</span>
                </div>
                <p style={{
                    color: 'rgba(255,255,255,0.8)', fontSize: '10px', margin: '0 0 10px 0', 
                    textAlign: 'left', lineHeight: 1.4
                }}>
                    Sarah wants to know if you're free for coffee at Downtown Cafe.
                </p>
                <div style={{display: 'flex', gap: 8}}>
                    <div style={{background: '#7cc3ce', color: '#051417', padding: '6px 12px', borderRadius: 8, fontSize: '9px', fontWeight: 800}}>Reply Yes</div>
                    <div style={{background: 'rgba(255,255,255,0.1)', color: 'white', padding: '6px 12px', borderRadius: 8, fontSize: '9px', fontWeight: 600}}>Busy</div>
                </div>
            </div>
            
            <div style={{
                background: 'rgba(255,255,255,0.02)', border: '1px solid rgba(255,255,255,0.05)', 
                borderRadius: 14, padding: 12, display: 'flex', alignItems: 'center', gap: 12
            }}>
                <div style={{width: 32, height: 32, background: 'rgba(124,195,206,0.1)', borderRadius: 8, display: 'flex', alignItems: 'center', justifyContent: 'center'}}>
                    <Star color="#7cc3ce" size={16} />
                </div>
                <div style={{display: 'flex', flexDirection: 'column', textAlign: 'left'}}>
                    <span style={{color: 'white', fontSize: '10px', fontWeight: 600}}>Saved Locations</span>
                    <span style={{color: '#888', fontSize: '8px'}}>Manage your favorite spots</span>
                </div>
                <ChevronRight color="#555" size={16} style={{marginLeft: 'auto'}} />
            </div>
        </div>
    </div>
  );
}
