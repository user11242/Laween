import { Composition } from 'remotion';
import { MainComposition } from './Composition';

export const RemotionRoot: React.FC = () => {
  return (
    <>
      <Composition
        id="LaweenPromo"
        component={MainComposition}
        durationInFrames={2340} // ~78s at 30 fps
        fps={30}
        width={1920}
        height={1080}
      />
    </>
  );
};
