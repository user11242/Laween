import { AbsoluteFill, useCurrentFrame, useVideoConfig, spring, interpolate, staticFile } from 'remotion';
import React from 'react';
import { PhoneMockup } from '../components/PhoneMockup';

function cubicAt(t:number,p0:number,p1:number,p2:number,p3:number){
  const u=1-t; return u*u*u*p0+3*u*u*t*p1+3*u*t*t*p2+t*t*t*p3;
}

const MEMBERS = [
  {letter:'Y',name:'You',  color:'#14b8a6'},
  {letter:'A',name:'Ahmad',color:'#f59e0b'},
  {letter:'S',name:'Sarah',color:'#a78bfa'},
  {letter:'Z',name:'Yazan',color:'#22d3ee'},
];

/*
 * Clean, intentional routing:
 * Each node uses a dynamically computed sigmoidal (S-curve) path
 * that starts horizontally from the pill and ends horizontally at the map dot.
 */
const ROUTES = [
  { ox: 240,  oy: 235 },  // You (upper-left)
  { ox: 1680, oy: 235 },  // Ahmad (upper-right)
  { ox: 220,  oy: 865 },  // Sarah (lower-left)
  { ox: 1700, oy: 865 },  // Yazan (lower-right)
];

const NODE_APPEAR = [15, 30, 45, 60]; // Sequentially staggered
const PERIOD = 88;

// Map circle coordinates to match ROUTES order
const TARGET_CIRCLES = [
  { top: 48, left: 32 }, // You (W)
  { top: 42, left: 18 }, // Ahmad (A)
  { top: 26, left: 62 }, // Sarah (S)
  { top: 20, left: 38 }, // Yazan (Y)
];

export const Scene8VotingHero:React.FC=()=>{
  const {fps}=useVideoConfig(), frame=useCurrentFrame();

  const phoneSpring=spring({frame:frame-3,fps,config:{damping:14}});
  const phoneScale =interpolate(phoneSpring,[0,1],[0.9,1]);
  const phoneOp    =interpolate(frame,[3,15],[0,1],{extrapolateLeft:'clamp',extrapolateRight:'clamp'});
  const mapX=interpolate(frame,[0,270],[0,-25],{extrapolateRight:'clamp'});
  const mapY=interpolate(frame,[0,270],[0,-12],{extrapolateRight:'clamp'});
  const currentCard=frame<90?0:frame<180?1:2;

  let votes=1,hasHeroVoted=false,votePop=1;
  if(currentCard===1){
    const tf=130; votes=frame>=tf?2:1; hasHeroVoted=frame>=tf;
    if(frame>=tf&&frame<tf+8) votePop=interpolate(spring({frame:frame-tf,fps,config:{damping:12}}),[0,1],[0.95,1.05]);
  } else if(currentCard===2){
    const tf=210; votes=frame>=tf?4:3; hasHeroVoted=frame>=tf;
    if(frame>=tf&&frame<tf+8) votePop=interpolate(spring({frame:frame-tf,fps,config:{damping:12}}),[0,1],[0.95,1.05]);
  }

  // Winner moment — fires at frame 210 when Oliva hits 4/4
  const WIN_FRAME = 210;
  const isWinner = frame >= WIN_FRAME;
  const winSpring = spring({ frame: frame - WIN_FRAME, fps, config: { damping: 10, stiffness: 180 } });
  // Large badge scale: bounces in from 0 → 1
  const winBadgeScale = isWinner ? interpolate(winSpring, [0, 1], [0, 1], { extrapolateRight: 'clamp' }) : 0;
  // Ring pulse: a ripple that expands outward once
  const winRingScale = isWinner ? interpolate(winSpring, [0, 1], [0.5, 2.2], { extrapolateRight: 'clamp' }) : 0;
  const winRingOp = isWinner ? interpolate(winSpring, [0, 1], [0.8, 0], { extrapolateRight: 'clamp' }) : 0;
  // Phone zooms in slightly after winner lands
  const winPhoneScale = isWinner ? interpolate(winSpring, [0, 1], [1.0, 1.07], { extrapolateRight: 'clamp' }) : 1.0;

  const places=[
    {name:'The Cap Soul',    price:'$', rating:'4.5',reviews:125,image:'capsoul.png',arrivals:[
      {n:'You',t:'17 min',d:'7.4 km'},{n:'Yazan',t:'16 min',d:'6.5 km'},
      {n:'Sarah',t:'12 min',d:'4.8 km'},{n:'Ahmad',t:'22 min',d:'9.1 km'}]},
    {name:'Farah Restaurant',price:'$$',rating:'4.2',reviews:89, image:'alfarah.png',arrivals:[
      {n:'You',t:'22 min',d:'9.1 km'},{n:'Ahmad',t:'14 min',d:'5.8 km'},
      {n:'Sarah',t:'8 min',d:'3.2 km'},{n:'Yazan',t:'19 min',d:'7.6 km'}]},
    {name:'Oliva',           price:'$', rating:'4.7',reviews:203,image:'oliva_restaurant.jpg',arrivals:[
      {n:'You',t:'13 min',d:'5.2 km'},{n:'Yazan',t:'11 min',d:'4.3 km'},
      {n:'Ahmad',t:'9 min',d:'3.6 km'},{n:'Sarah',t:'18 min',d:'7.8 km'}]},
  ];
  const place=places[currentCard];

  const titleOp  =interpolate(frame,[10,22],[0,1],{extrapolateLeft:'clamp',extrapolateRight:'clamp'});
  const titleFade=interpolate(frame,[258,268],[1,0],{extrapolateLeft:'clamp',extrapolateRight:'clamp'});
  const exitOp   =interpolate(frame,[262,270],[1,0],{extrapolateLeft:'clamp',extrapolateRight:'clamp'});
  const netOp    =interpolate(frame,[22,52],[0,1],{extrapolateLeft:'clamp',extrapolateRight:'clamp'});

  const nodeAnim=ROUTES.map((_,i)=>{
    const af=NODE_APPEAR[i];
    const s=spring({frame:frame-af,fps,config:{damping:14}});
    let pillPulse=1;
    for(let pi=0;pi<2;pi++){
      if(frame>=af+20){const t=((frame-af-20)/PERIOD+pi*0.5)%1; if(t<0.07) pillPulse=1+(1-t/0.07)*0.06;}
    }
    return {
      opacity:interpolate(s,[0,1],[0,1]),
      scale:  interpolate(s,[0,1],[0.65,1]),
      lineDash:interpolate(frame,[af+8,af+60],[1,0],{extrapolateLeft:'clamp',extrapolateRight:'clamp'}),
      lineOp:  interpolate(frame,[af+8,af+32],[0,1],{extrapolateLeft:'clamp',extrapolateRight:'clamp'}),
      pillPulse, startF:af+20,
    };
  });

  return (
    <AbsoluteFill style={{backgroundColor:'#050714',justifyContent:'center',alignItems:'center',opacity:exitOp}}>
      <div style={{position:'absolute',inset:0,pointerEvents:'none',
        background:'radial-gradient(ellipse at 50% 58%, rgba(0,109,119,0.07) 0%, transparent 62%)'}}/>

      {/* ─── NETWORK SVG ─── 1920×1080 viewBox (zIndex: 11 so it draws OVER the phone) */}
      <svg style={{position:'absolute',inset:0,width:'100%',height:'100%',zIndex:11,pointerEvents:'none'}}
           viewBox="0 0 1920 1080">
        <defs>
          {MEMBERS.map((m,i)=>(
            <linearGradient key={i} id={`g${i}`} gradientUnits="userSpaceOnUse"
              x1={ROUTES[i].ox} y1={ROUTES[i].oy} x2={960} y2={620}>
              <stop offset="0%"   stopColor={m.color} stopOpacity="0.65"/>
              <stop offset="100%" stopColor={m.color} stopOpacity="0.08"/>
            </linearGradient>
          ))}
          <filter id="dg" x="-300%" y="-300%" width="700%" height="700%">
            <feGaussianBlur stdDeviation="3" result="b"/>
            <feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge>
          </filter>
          <filter id="ag" x="-200%" y="-200%" width="500%" height="500%">
            <feGaussianBlur stdDeviation="9"/>
          </filter>
        </defs>

        <g opacity={netOp}>
          {ROUTES.map((r,i)=>{
            const m=MEMBERS[i], an=nodeAnim[i];
            
            // Calculate dynamic destination
            const tc = TARGET_CIRCLES[i];
            const x_map = 453.6 * tc.left / 100;
            const y_map = 998.4 * tc.top / 100;
            const x_virtual = x_map - 37.8 + mapX;
            const y_virtual = y_map - 83.2 + mapY;
            const driftX = Math.cos(frame * 0.03) * 2;
            const driftY = Math.sin(frame * 0.04) * 4;
            const dx = 960 + driftX * phoneScale + (x_virtual - 189) * 0.95 * phoneScale;
            const dy = 540 + 80 * phoneScale + driftY * phoneScale + (y_virtual - 416) * 0.95 * phoneScale;
            
            // Clean, sigmoidal control points
            const cp1x = r.ox + (dx - r.ox) * 0.45;
            const cp1y = r.oy;
            const cp2x = dx - (dx - r.ox) * 0.45;
            const cp2y = dy;
            
            const d = `M ${r.ox} ${r.oy} C ${cp1x} ${cp1y} ${cp2x} ${cp2y} ${dx} ${dy}`;
            const particles:[number,number,number][]=[];
            let arrival=false;
            for(let pi=0;pi<2;pi++){
              if(frame<an.startF) continue;
              const t=((frame-an.startF)/PERIOD+pi*0.5)%1;
              const px = cubicAt(t, r.ox, cp1x, cp2x, dx);
              const py = cubicAt(t, r.oy, cp1y, cp2y, dy);
              const op=t<0.07?t/0.07:t>0.86?(1-t)/0.14:1;
              particles.push([px,py,op]);
              if(t>0.82) arrival=true;
            }
            return (
              <g key={i}>
                {/* glow backing */}
                <path d={d} fill="none" stroke={m.color} strokeWidth="12"
                  opacity={an.lineOp*0.07} strokeLinecap="round"/>
                {/* animated draw-in line — thicker, more visible */}
                <path d={d} fill="none" stroke={`url(#g${i})`} strokeWidth="3"
                  opacity={an.lineOp*0.60} pathLength="1"
                  strokeDasharray="1" strokeDashoffset={an.lineDash} strokeLinecap="round"/>
                {/* particles */}
                {particles.map(([px,py,op],pi)=>(
                  <circle key={pi} cx={px} cy={py} r={5}
                    fill={m.color} opacity={op*0.95} filter="url(#dg)"/>
                ))}
                {/* arrival glow at destination */}
                {arrival&&(
                  <circle cx={dx} cy={dy} r={22}
                    fill={m.color} opacity={0.25} filter="url(#ag)"/>
                )}
              </g>
            );
          })}
        </g>
      </svg>

      {/* ─── OUTER USER PILLS ─── */}
      {ROUTES.map((r,i)=>{
        const m=MEMBERS[i], an=nodeAnim[i];
        return (
          <div key={i} style={{
            position:'absolute',
            left:`${r.ox/1920*100}%`, top:`${r.oy/1080*100}%`,
            transform:`translate(-50%,-50%) scale(${an.scale*an.pillPulse})`,
            opacity:an.opacity*netOp, zIndex:12, pointerEvents:'none',
          }}>
            <div style={{display:'flex',alignItems:'center',gap:10,
              background:'rgba(5,8,24,0.74)',border:`1px solid ${m.color}50`,
              borderRadius:28,padding:'8px 16px 8px 8px',
              boxShadow:`0 0 22px ${m.color}20, 0 4px 20px rgba(0,0,0,0.5)`}}>
              <div style={{width:36,height:36,borderRadius:18,background:m.color,flexShrink:0,
                display:'flex',justifyContent:'center',alignItems:'center',
                boxShadow:`0 0 14px ${m.color}65`}}>
                <span style={{fontFamily:'Inter,sans-serif',fontSize:15,fontWeight:800,color:'white'}}>{m.letter}</span>
              </div>
              <div>
                <div style={{fontFamily:'Outfit,sans-serif',fontSize:14,fontWeight:700,color:'white',lineHeight:1.2}}>{m.name}</div>
                <div style={{fontFamily:'Inter,sans-serif',fontSize:10,color:m.color,fontWeight:600,letterSpacing:'0.05em'}}>📍 Sharing location</div>
              </div>
            </div>
          </div>
        );
      })}

      {/* ─── TITLE ─── */}
      <div style={{position:'absolute',top:'4%',width:'100%',textAlign:'center',padding:'0 20px',
        opacity:titleOp*titleFade,zIndex:20}}>
        <h1 style={{fontFamily:'Inter,system-ui,sans-serif',fontSize:58,fontWeight:900,color:'white',margin:0,letterSpacing:'-0.02em',lineHeight:1.15}}>
          Compare places. Compare arrivals.
        </h1>
        <p style={{fontFamily:'Inter,system-ui,sans-serif',fontSize:28,fontWeight:700,color:'#5eead4',margin:'12px 0 0'}}>
          Vote together.
        </p>
      </div>

      {/* ─── HERO PHONE ─── */}
      <div style={{transform:`scale(${phoneScale * winPhoneScale}) translateY(80px)`,opacity:phoneOp,zIndex:10}}>
        <PhoneMockup scale={0.95} drift>
          <div style={{position:'absolute',top:'-10%',left:'-10%',right:'-10%',bottom:'-10%',
            background:'linear-gradient(180deg,#18233b 0%,#141c2f 40%,#0d1421 100%)',
            transform:`translate(${mapX}px,${mapY}px)`}}>
            {[15,28,38,48,58,72,85].map((p,i)=>(
              <div key={`h${i}`} style={{position:'absolute',top:`${p}%`,left:-50,right:-50,
                height:i%2===0?4:2,background:'rgba(45,212,191,0.08)',transform:`rotate(${Math.sin(i)*10}deg)`}}/>
            ))}
            {[10,22,35,48,62,75,88].map((p,i)=>(
              <div key={`v${i}`} style={{position:'absolute',left:`${p}%`,top:-50,bottom:-50,
                width:i%2===0?4:2,background:'rgba(45,212,191,0.06)',transform:`rotate(${Math.cos(i)*10}deg)`}}/>
            ))}

            {/* Discovery Room */}
            <div style={{position:'absolute',top:'15%',right:'12%',
              background:'rgba(15,23,42,0.9)',borderRadius:20,padding:'10px 16px',
              display:'flex',alignItems:'center',gap:8,border:'1px solid rgba(255,255,255,0.10)'}}>
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#14b8a6" strokeWidth="2.5">
                <circle cx="12" cy="12" r="4"/><circle cx="12" cy="12" r="9"/>
              </svg>
              <span style={{fontFamily:'Outfit,sans-serif',fontSize:14,fontWeight:700,color:'white'}}>Discovery Room</span>
            </div>

            {/* In-phone user circles — positions calibrated to match ROUTES destinations */}
            {([
              {letter:'W',top:48,left:32,color:'#14b8a6',big:true },
              {letter:'Y',top:20,left:38,color:'#22d3ee',big:false},
              {letter:'S',top:26,left:62,color:'#a78bfa',big:false},
              {letter:'A',top:42,left:18,color:'#f59e0b',big:false},
            ] as const).map((m,i)=>(
              <div key={i} style={{position:'absolute',top:`${m.top}%`,left:`${m.left}%`,transform:'translate(-50%,-50%)'}}>
                <div style={{width:m.big?62:52,height:m.big?62:52,borderRadius:m.big?31:26,
                  background:m.color,border:`${m.big?4:3}px solid white`,
                  display:'flex',justifyContent:'center',alignItems:'center',
                  boxShadow:`0 8px 24px ${m.color}60`}}>
                  <span style={{fontFamily:'Inter,sans-serif',fontSize:m.big?28:24,fontWeight:800,color:'white'}}>{m.letter}</span>
                </div>
              </div>
            ))}

            {/* Venue pins */}
            {[{top:38,left:54,c:'#f59e0b'},{top:32,left:34,c:'#3b82f6'},{top:36,left:28,c:'#ec4899'}].map((p,i)=>(
              <div key={i} style={{position:'absolute',top:`${p.top}%`,left:`${p.left}%`,transform:'translate(-50%,-100%)'}}>
                <div style={{width:34,height:34,borderRadius:'50% 50% 50% 0',background:p.c,
                  display:'flex',justifyContent:'center',alignItems:'center',transform:'rotate(-45deg)',
                  boxShadow:`0 6px 16px ${p.c}80`,border:'1px solid rgba(255,255,255,0.2)'}}>
                  <div style={{width:10,height:10,borderRadius:5,background:'rgba(0,0,0,0.25)'}}/>
                </div>
              </div>
            ))}
          </div>

          {/* Venue cards */}
          <div style={{position:'absolute',bottom:10,left:0,right:0,display:'flex',gap:16,overflow:'hidden',paddingLeft:16}}>
            <div style={{background:'white',borderRadius:36,overflow:'hidden',minWidth:340,width:340,
              boxShadow:'0 8px 30px rgba(0,0,0,0.2)',display:'flex',flexDirection:'column'}}>
              <div style={{display:'flex'}}>
                <div style={{width:'42%',minHeight:200,overflow:'hidden',background:'#cbd5e1'}}>
                  <img src={staticFile(place.image)} style={{width:'100%',height:'100%',objectFit:'cover',display:'block'}} alt=""/>
                </div>
                <div style={{flex:1,padding:'20px 16px 14px'}}>
                  <div style={{display:'flex',alignItems:'center',justifyContent:'space-between',marginBottom:4}}>
                    <p style={{fontFamily:'Outfit,sans-serif',fontSize:18,fontWeight:800,color:'#2D3748',margin:0}}>{place.name}</p>
                    <span style={{fontFamily:'Outfit,sans-serif',fontSize:16,color:'#006D77',fontWeight:800}}>{place.price}</span>
                  </div>
                  <div style={{display:'flex',alignItems:'center',gap:6,marginBottom:14}}>
                    <span style={{color:'#f59e0b',fontSize:13}}>⭐</span>
                    <span style={{fontFamily:'Inter,sans-serif',fontSize:13,fontWeight:600,color:'#64748b'}}>{place.rating} ({place.reviews})</span>
                  </div>
                  <p style={{fontFamily:'Inter,sans-serif',fontSize:9,fontWeight:900,color:'#94a3b8',letterSpacing:'1.5px',margin:'0 0 6px'}}>ARRIVALS</p>
                  {place.arrivals.map((a,i)=>(
                    <div key={i} style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:2}}>
                      <span style={{fontFamily:'Inter,sans-serif',fontSize:11,color:'#0f172a',fontWeight:600}}>{a.n}</span>
                      <span style={{fontFamily:'Inter,sans-serif',fontSize:11,color:'#006D77',fontWeight:700}}>{a.t} ({a.d})</span>
                    </div>
                  ))}
                </div>
              </div>
              <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',
                padding:'10px 16px',borderTop:'1px solid #f1f5f9',background:'#f8fafc'}}>
                <span style={{fontFamily:'Inter,sans-serif',fontSize:12,fontWeight:700,color:'#006D77',
                  transform:`scale(${votePop})`, display:'inline-block', transformOrigin:'left center',
                  textShadow: isWinner ? '0 0 12px rgba(0,109,119,0.8)' : 'none',
                }}>{votes} / 4 Votes</span>
                <div style={{background:hasHeroVoted?'rgba(0,109,119,0.1)':'#006D77',borderRadius:12,padding:'8px 16px',
                  border:hasHeroVoted?'1px solid #006D77':'1px solid transparent',transform:`scale(${votePop})`,
                  boxShadow: votePop > 1.02 ? '0 0 12px rgba(0,109,119,0.5)' : 'none'}}>
                  <span style={{fontFamily:'Inter,sans-serif',fontSize:11,fontWeight:700,color:hasHeroVoted?'#006D77':'white'}}>
                    {hasHeroVoted?'VOTED':'VOTE'}
                  </span>
                </div>
              </div>
            </div>
            <div style={{background:'white',borderRadius:36,overflow:'hidden',minWidth:340,width:340,
              boxShadow:'0 8px 30px rgba(0,0,0,0.1)',opacity:0.9}}>
              <div style={{display:'flex',height:200}}>
                <div style={{width:'42%',background:'#cbd5e1'}}/>
                <div style={{flex:1,padding:20}}>
                  <div style={{width:'60%',height:20,background:'#e2e8f0',borderRadius:4,marginBottom:10}}/>
                  <div style={{width:'40%',height:14,background:'#e2e8f0',borderRadius:4}}/>
                </div>
              </div>
            </div>
          </div>
        </PhoneMockup>
      </div>

      {/* ─── FULL-SCREEN WINNER TAKEOVER ─────────────────────────────
       *  zIndex 40+50: covers the entire scene including the phone.
       *  Clearly editorial — not part of the app UI.
       *  Dark backdrop fades in first (18 frames), then the hero
       *  card springs in from the centre.
       * ──────────────────────────────────────────────────────────── */}
      {isWinner && (
        <>
          {/* Dark backdrop — fades in quickly, sits over everything */}
          <div style={{
            position: 'absolute', inset: 0, zIndex: 40, pointerEvents: 'none',
            background: 'rgba(3, 5, 18, 0.92)',
            opacity: Math.min(1, interpolate(frame, [WIN_FRAME, WIN_FRAME + 16], [0, 1], { extrapolateRight: 'clamp' })),
          }} />

          {/* Hero content layer */}
          <div style={{
            position: 'absolute', inset: 0, zIndex: 50, pointerEvents: 'none',
            display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 36,
          }}>

            {/* Editorial header — "The group has voted" with flanking lines */}
            <div style={{
              display: 'flex', alignItems: 'center', gap: 28,
              opacity: interpolate(winSpring, [0, 0.5], [0, 1], { extrapolateRight: 'clamp' }),
              transform: `translateY(${interpolate(winSpring, [0, 1], [20, 0])}px)`,
            }}>
              <div style={{ width: 130, height: 1.5, background: 'linear-gradient(to right, transparent, #14b8a6)' }} />
              <span style={{ fontFamily: 'Inter, sans-serif', fontSize: 18, fontWeight: 800,
                color: '#5eead4', letterSpacing: '0.18em', textTransform: 'uppercase', whiteSpace: 'nowrap' }}>
                The group has voted
              </span>
              <div style={{ width: 130, height: 1.5, background: 'linear-gradient(to left, transparent, #14b8a6)' }} />
            </div>

            {/* Hero Oliva card — springs in, 680px wide */}
            <div style={{
              transform: `scale(${interpolate(winSpring, [0, 1], [0.72, 1], { extrapolateRight: 'clamp' })})`,
              opacity: interpolate(winSpring, [0, 0.45], [0, 1], { extrapolateRight: 'clamp' }),
              transformOrigin: 'center center',
            }}>
              <div style={{
                background: 'white', borderRadius: 40, overflow: 'hidden',
                width: 700, display: 'flex',
                boxShadow: '0 0 90px rgba(0,109,119,0.35), 0 30px 80px rgba(0,0,0,0.65)',
              }}>
                {/* Restaurant image — left side */}
                <div style={{ width: 270, flexShrink: 0, overflow: 'hidden' }}>
                  <img src={staticFile('oliva_restaurant.jpg')}
                    style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }} alt="" />
                </div>

                {/* Info — right side */}
                <div style={{ flex: 1, padding: '30px 32px', display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
                  <div>
                    <p style={{ fontFamily: 'Outfit, sans-serif', fontSize: 34, fontWeight: 900,
                      color: '#0f172a', margin: '0 0 8px', lineHeight: 1.05 }}>Oliva</p>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                      <span style={{ fontSize: 15 }}>⭐</span>
                      <span style={{ fontFamily: 'Inter, sans-serif', fontSize: 15, color: '#64748b', fontWeight: 600 }}>
                        4.7 · 203 reviews
                      </span>
                    </div>
                  </div>

                  <div>
                    <p style={{ fontFamily: 'Inter, sans-serif', fontSize: 10, fontWeight: 900,
                      color: '#94a3b8', letterSpacing: '0.15em', margin: '0 0 10px', textTransform: 'uppercase' }}>Arrivals</p>
                    {([
                      {n:'You',   t:'13 min', d:'5.2 km'},
                      {n:'Yazan', t:'11 min', d:'4.3 km'},
                      {n:'Ahmad', t:'9 min',  d:'3.6 km'},
                      {n:'Sarah', t:'18 min', d:'7.8 km'},
                    ] as const).map((a, i) => (
                      <div key={i} style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 7 }}>
                        <span style={{ fontFamily: 'Inter, sans-serif', fontSize: 14, color: '#1e293b', fontWeight: 600 }}>{a.n}</span>
                        <span style={{ fontFamily: 'Inter, sans-serif', fontSize: 14, color: '#006D77', fontWeight: 700 }}>{a.t} ({a.d})</span>
                      </div>
                    ))}
                  </div>

                  {/* 4 / 4 pill — bottom of card */}
                  <div style={{
                    background: 'linear-gradient(135deg, #006D77 0%, #14b8a6 100%)',
                    borderRadius: 20, padding: '14px 22px',
                    display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                    boxShadow: '0 4px 20px rgba(0,109,119,0.4)',
                  }}>
                    <span style={{ fontFamily: 'Inter, sans-serif', fontSize: 14, fontWeight: 800, color: 'rgba(255,255,255,0.85)' }}>
                      All votes in
                    </span>
                    <span style={{ fontFamily: 'Outfit, sans-serif', fontSize: 36, fontWeight: 900, color: 'white', lineHeight: 1 }}>
                      4 / 4
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </>
      )}

      <div style={{position:'absolute',bottom:'6%',display:'flex',gap:6,zIndex:15}}>
        {[0,1,2].map(i=>(
          <div key={i} style={{width:currentCard===i?22:7,height:7,borderRadius:4,
            background:currentCard===i?'#14b8a6':'rgba(255,255,255,0.12)'}}/>
        ))}
      </div>
    </AbsoluteFill>
  );
};
