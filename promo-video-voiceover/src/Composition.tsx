import { AbsoluteFill, Sequence } from 'remotion';
import { Scene1MultiPOV } from './scenes/Scene1MultiPOV';
import { Scene3Security } from './scenes/Scene3Security';
import { Scene2Ecosystem } from './scenes/Scene2Ecosystem';
import { Scene4SocialConnection } from './scenes/Scene4SocialConnection';
import { Scene5OutingBegins } from './scenes/Scene5OutingBegins';
import { Scene5bOutingOptions } from './scenes/Scene5bOutingOptions';
import { Scene6ConfigureOuting } from './scenes/Scene6ConfigureOuting';
import { Scene5bResponses } from './scenes/Scene5bResponses';
import { Scene7WaitingRoom } from './scenes/Scene7WaitingRoom';
import { Scene8VotingHero } from './scenes/Scene8VotingHero';
import { Scene9Winner } from './scenes/Scene9Winner';
import { Scene10LiveTracking } from './scenes/Scene10LiveTracking';
import { Scene11LockScreen } from './scenes/Scene11LockScreen';
import { Scene12Montage } from './scenes/Scene12Montage';
import { Scene13EndCard } from './scenes/Scene13EndCard';
import { NetworkBackground } from './components/NetworkBackground';
import { SoundLayer } from './components/SoundLayer';

export const MainComposition = () => {
  // 30 fps
  const s1  = 270;  // MultiPOV Chaos
  const s2  = 150;  // Security / FaceID
  const s3  = 210;  // Join Group Methods
  const s4  = 220;  // Ecosystem Chat Group
  const s5  = 210;  // Outing Begins
  const s5bOpt= 120;// Outing Options
  const s6  = 210;  // Configure Outing
  const s6b = 300;  // Responses & Notifications (extended — type_search needs post-APP_OPEN typing room)
  const s7  = 180;  // Waiting Room
  const s8  = 270;  // Discovery + Voting (HERO)
  const s9  = 180;  // Winner (was 150 — extended to breathe)
  const s10 = 210;  // Live Tracking
  const s11 = 150;  // Lock Screen
  const s12 = 120;  // Montage
  const s13 = 180;  // End Card (was 150 — extended for sting to resolve)

  // Cumulative offsets
  const t1  = 0;
  const t2  = t1 + s1;
  const t3  = t2 + s2;
  const t4  = t3 + s3;
  const t5  = t4 + s4;
  const t5bOpt = t5 + 198; // Overlap for match-and-zoom
  const t6  = t5bOpt + s5bOpt;
  const t6b = t6 + s6;
  const t7  = t6b + s6b;
  const t8  = t7 + s7;
  const t9  = t8 + s8;
  const t10 = t9 + s9;
  const t11 = t10 + s10;
  const t12 = t11 + s11;
  const t13 = t12 + s12;

  return (
    <AbsoluteFill style={{ backgroundColor: '#050714', color: 'white' }}>
      <NetworkBackground />
      <SoundLayer />

      <Sequence from={t1}  durationInFrames={s1} ><Scene1MultiPOV /></Sequence>
      <Sequence from={t2}  durationInFrames={s2} ><Scene3Security /></Sequence>
      <Sequence from={t3}  durationInFrames={s3} ><Scene4SocialConnection /></Sequence>
      <Sequence from={t4}  durationInFrames={s4} ><Scene2Ecosystem /></Sequence>
      <Sequence from={t5}  durationInFrames={s5} ><Scene5OutingBegins /></Sequence>
      <Sequence from={t5bOpt} durationInFrames={s5bOpt}><Scene5bOutingOptions /></Sequence>
      <Sequence from={t6}  durationInFrames={s6} ><Scene6ConfigureOuting /></Sequence>
      <Sequence from={t6b} durationInFrames={s6b}><Scene5bResponses /></Sequence>
      <Sequence from={t7}  durationInFrames={s7} ><Scene7WaitingRoom /></Sequence>
      <Sequence from={t8}  durationInFrames={s8} ><Scene8VotingHero /></Sequence>
      <Sequence from={t9}  durationInFrames={s9} ><Scene9Winner /></Sequence>
      <Sequence from={t10} durationInFrames={s10}><Scene10LiveTracking /></Sequence>
      <Sequence from={t11} durationInFrames={s11}><Scene11LockScreen /></Sequence>
      <Sequence from={t12} durationInFrames={s12}><Scene12Montage /></Sequence>
      <Sequence from={t13} durationInFrames={s13}><Scene13EndCard /></Sequence>
    </AbsoluteFill>
  );
};
