import { Composition } from 'remotion';
import { MainComposition } from './Composition';

export const RemotionRoot: React.FC = () => {
  return (
    <>
      <Composition
        id="LaweenPromo"
        component={MainComposition}
        durationInFrames={1800} // 1 min at 30 fps
        fps={30}
        width={1080}
        height={1920}
      />
    </>
  );
};
