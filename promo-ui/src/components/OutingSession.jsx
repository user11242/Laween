import React from 'react';
import { MapPin, CheckCircle, Loader } from 'lucide-react';
import '../App.css'; // Assuming we put the pulse/spin animations here

export default function OutingSession() {
  return (
    <div style={{
      width: '100%', height: '100vh', background: '#2a2c32', 
      position: 'relative', display: 'flex', flexDirection: 'column', 
      fontFamily: "'Inter', sans-serif", overflow: 'hidden'
    }}>
        {/* Pseudo Map Background */}
        <div style={{
            position: 'absolute', top: 0, left: 0, width: '100%', height: '60%', 
            background: 'radial-gradient(circle at 50% 50%, #152528, #051417)', overflow: 'hidden'
        }}>
            {/* Grid lines */}
            <div style={{
                position: 'absolute', top: 0, left: 0, width: '100%', height: '100%', 
                backgroundImage: 'linear-gradient(rgba(124,195,206,0.05) 1px, transparent 1px), linear-gradient(90deg, rgba(124,195,206,0.05) 1px, transparent 1px)', 
                backgroundSize: '20px 20px'
            }}></div>
            {/* Pin Point */}
            <div className="pulse-anim" style={{
                position: 'absolute', top: '40%', left: '45%', background: 'rgba(124,195,206,0.2)', 
                width: 40, height: 40, borderRadius: '50%', display: 'flex', 
                alignItems: 'center', justifyContent: 'center'
            }}>
                 <MapPin color="#7cc3ce" size={20} />
            </div>
        </div>
        
        {/* Bottom Sheet UI */}
        <div style={{
            position: 'absolute', bottom: 0, left: 0, width: '100%', height: '48%', 
            background: '#051417', borderTopLeftRadius: 20, borderTopRightRadius: 20, 
            boxShadow: '0 -5px 25px rgba(0,0,0,0.5)', padding: 15, display: 'flex', 
            flexDirection: 'column', borderTop: '1px solid rgba(124,195,206,0.1)'
        }}>
            <div style={{width: 30, height: 4, background: 'rgba(255,255,255,0.2)', borderRadius: 2, margin: '0 auto 10px'}}></div>
            <h4 style={{color: 'white', fontSize: '14px', margin: '0 0 5px 0'}}>Downtown Cafe Match</h4>
            <p style={{color: '#7cc3ce', fontSize: '10px', margin: '0 0 15px 0', fontWeight: 600}}>Everyone is en route</p>
            
            <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center', background: 'rgba(255,255,255,0.05)', border: '1px solid rgba(255,255,255,0.1)', padding: 10, borderRadius: 12, marginBottom: 8}}>
                <div style={{display: 'flex', alignItems: 'center', gap: 8}}>
                    <div style={{width: 28, height: 28, background: '#00697B', borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'white', fontSize: '9px', fontWeight: 'bold'}}>S</div>
                    <div style={{display: 'flex', flexDirection: 'column'}}>
                        <span style={{color: 'white', fontSize: '11px', fontWeight: 600, textAlign: 'left'}}>Sarah</span>
                        <span style={{color: '#aaa', fontSize: '9px', textAlign: 'left'}}>Arriving in 4 min</span>
                    </div>
                </div>
                 <CheckCircle color="#7cc3ce" size={14} />
            </div>
            
            <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center', background: 'rgba(255,255,255,0.02)', border: '1px solid rgba(255,255,255,0.05)', padding: 10, borderRadius: 12}}>
                <div style={{display: 'flex', alignItems: 'center', gap: 8}}>
                    <div style={{width: 28, height: 28, background: '#FBBC04', borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'black', fontSize: '9px', fontWeight: 'bold'}}>J</div>
                    <div style={{display: 'flex', flexDirection: 'column'}}>
                        <span style={{color: 'white', fontSize: '11px', fontWeight: 600, textAlign: 'left'}}>Jason</span>
                        <span style={{color: '#aaa', fontSize: '9px', textAlign: 'left'}}>Arriving in 15 min</span>
                    </div>
                </div>
                 <Loader className="spin-anim" color="#FBBC04" size={14} />
            </div>
        </div>
    </div>
  );
}
