import { AbsoluteFill, useVideoConfig, Sequence } from 'remotion';
import { Scene1Ecosystem } from './scenes/Scene1Ecosystem';
import { Scene2Security } from './scenes/Scene2Security';
import { Scene3JoinGroup } from './scenes/Scene3JoinGroup';
import { Scene4OutingStory } from './scenes/Scene4OutingStory';
import { Scene5LiveMap } from './scenes/Scene5LiveMap';
import { Scene6DynamicIsland } from './scenes/Scene6DynamicIsland';
import { Scene7MediaVault } from './scenes/Scene7MediaVault';
import { NetworkBackground } from './components/NetworkBackground';

export const MainComposition = () => {
  const { fps, durationInFrames, width, height } = useVideoConfig();

  // Basic timeline math at 30 fps
  const s1 = 120; // 4 seconds
  const s2 = 60;  // 2 seconds
  const s3 = 90;  // 3 seconds
  const s4 = 150; // 5 seconds
  const s5 = 180; // 6 seconds
  const s6 = 120; // 4 seconds
  const s7 = 120; // 4 seconds

  return (
    <AbsoluteFill style={{ backgroundColor: '#050714', color: 'white' }}>
      <NetworkBackground />
      <Sequence from={0} durationInFrames={s1}>
        <Scene1Ecosystem />
      </Sequence>
      
      <Sequence from={s1} durationInFrames={s2}>
        <Scene2Security />
      </Sequence>

      <Sequence from={s1 + s2} durationInFrames={s3}>
        <Scene3JoinGroup />
      </Sequence>

      <Sequence from={s1 + s2 + s3} durationInFrames={s4}>
        <Scene4OutingStory />
      </Sequence>

      <Sequence from={s1 + s2 + s3 + s4} durationInFrames={s5}>
        <Scene5LiveMap />
      </Sequence>

      <Sequence from={s1 + s2 + s3 + s4 + s5} durationInFrames={s6}>
        <Scene6DynamicIsland />
      </Sequence>

      <Sequence from={s1 + s2 + s3 + s4 + s5 + s6} durationInFrames={s7}>
        <Scene7MediaVault />
      </Sequence>
    </AbsoluteFill>
  );
};
