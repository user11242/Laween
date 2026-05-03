import { Composition } from 'remotion';
import { MainComposition } from './Composition';

export const RemotionRoot: React.FC = () => {
  return (
    <>
      <Composition
        id="LaweenPromo"
        component={MainComposition}
        durationInFrames={2968} // ~99s at 30 fps (s6b=300, s9=180, s13=180)
        fps={30}
        width={1920}
        height={1080}
      />
    </>
  );
};
