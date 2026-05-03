const fs = require('fs');
const path = require('path');

const sampleRate = 44100;
const numChannels = 1;
const bitsPerSample = 16;

function writeWav(filename, soundSamples) {
  // Pad all sounds to be at least 1 second long to avoid Remotion Studio waveform drawing errors (width=0)
  const minSamples = sampleRate * 1.0; 
  const totalSamples = Math.max(minSamples, soundSamples.length);
  
  const paddedSamples = new Float32Array(totalSamples);
  paddedSamples.set(soundSamples); // The rest will be 0 (silence)

  const dataSize = paddedSamples.length * 2; // 16-bit
  const buffer = Buffer.alloc(44 + dataSize);

  // RIFF header
  buffer.write('RIFF', 0);
  buffer.writeUInt32LE(36 + dataSize, 4);
  buffer.write('WAVE', 8);

  // fmt chunk
  buffer.write('fmt ', 12);
  buffer.writeUInt32LE(16, 16); // Subchunk1Size
  buffer.writeUInt16LE(1, 20); // AudioFormat (PCM)
  buffer.writeUInt16LE(numChannels, 22);
  buffer.writeUInt32LE(sampleRate, 24);
  buffer.writeUInt32LE(sampleRate * numChannels * (bitsPerSample / 8), 28); // ByteRate
  buffer.writeUInt16LE(numChannels * (bitsPerSample / 8), 32); // BlockAlign
  buffer.writeUInt16LE(bitsPerSample, 34);

  // data chunk
  buffer.write('data', 36);
  buffer.writeUInt32LE(dataSize, 40);

  // write samples
  for (let i = 0; i < paddedSamples.length; i++) {
    // Clamp sample between -1 and 1
    let sample = Math.max(-1, Math.min(1, paddedSamples[i]));
    // Convert to 16-bit integer
    let val = Math.floor(sample * 32767);
    buffer.writeInt16LE(val, 44 + i * 2);
  }

  const outPath = path.join(__dirname, 'public', 'sounds', filename);
  fs.writeFileSync(outPath, buffer);
  console.log('Created', filename);
}

// Generate Sine Wave
function generateSine(freq, durationSec, vol = 0.5, fadeOut = true) {
  const numSamples = Math.floor(sampleRate * durationSec);
  const samples = new Float32Array(numSamples);
  for (let i = 0; i < numSamples; i++) {
    const t = i / sampleRate;
    let env = 1;
    if (fadeOut) {
      env = 1 - (i / numSamples); // simple linear fade out
    }
    samples[i] = Math.sin(2 * Math.PI * freq * t) * vol * env;
  }
  return samples;
}

// ui_pop: short high pip
writeWav('ui_pop.wav', generateSine(800, 0.08, 0.5));

// swoosh_soft: noise sweep
const swooshSamples = new Float32Array(Math.floor(sampleRate * 0.15));
for(let i=0; i<swooshSamples.length; i++) {
    let env = 1 - (i/swooshSamples.length);
    swooshSamples[i] = (Math.random() * 2 - 1) * 0.3 * env;
}
writeWav('swoosh_soft.wav', swooshSamples);

// scan_pulse: longer tone with volume oscillation
const scanSamples = new Float32Array(Math.floor(sampleRate * 0.5));
for(let i=0; i<scanSamples.length; i++) {
    const t = i / sampleRate;
    const osc = (Math.sin(2 * Math.PI * 10 * t) + 1) / 2; // 10Hz pulse
    scanSamples[i] = Math.sin(2 * Math.PI * 400 * t) * 0.4 * osc;
}
writeWav('scan_pulse.wav', scanSamples);

// confirm_chime: two tones (major third)
const chimeDur = 0.3;
const chimeSamples = new Float32Array(Math.floor(sampleRate * chimeDur));
for(let i=0; i<chimeSamples.length; i++) {
    const t = i / sampleRate;
    const env = Math.exp(-t * 10); // exponential decay
    chimeSamples[i] = (Math.sin(2 * Math.PI * 523.25 * t) + Math.sin(2 * Math.PI * 659.25 * t)) * 0.25 * env;
}
writeWav('confirm_chime.wav', chimeSamples);

// notification: two quick beeps
const notifSamples = new Float32Array(Math.floor(sampleRate * 0.25));
for(let i=0; i<notifSamples.length; i++) {
    const t = i / sampleRate;
    const env1 = t < 0.1 ? 1 - (t/0.1) : 0;
    const env2 = t > 0.15 ? 1 - ((t-0.15)/0.1) : 0;
    notifSamples[i] = Math.sin(2 * Math.PI * 880 * t) * 0.4 * (env1 + env2);
}
writeWav('notification.wav', notifSamples);

// vote_win: arpeggio (C E G C)
const winDur = 0.6;
const winSamples = new Float32Array(Math.floor(sampleRate * winDur));
for(let i=0; i<winSamples.length; i++) {
    const t = i / sampleRate;
    let freq = 523.25; // C5
    if(t > 0.15) freq = 659.25; // E5
    if(t > 0.3) freq = 783.99; // G5
    if(t > 0.45) freq = 1046.50; // C6
    const env = 1 - (i/winSamples.length);
    winSamples[i] = Math.sin(2 * Math.PI * freq * t) * 0.4 * env;
}
writeWav('vote_win.wav', winSamples);

// map_pulse: low thud
const pulseSamples = new Float32Array(Math.floor(sampleRate * 0.2));
for(let i=0; i<pulseSamples.length; i++) {
    const t = i / sampleRate;
    const env = Math.exp(-t * 20);
    pulseSamples[i] = Math.sin(2 * Math.PI * 150 * t) * 0.6 * env;
}
writeWav('map_pulse.wav', pulseSamples);

// ambient_track: quiet low drone (10 mins)
const ambSamples = new Float32Array(Math.floor(sampleRate * 10));
for(let i=0; i<ambSamples.length; i++) {
    const t = i / sampleRate;
    ambSamples[i] = (Math.sin(2 * Math.PI * 100 * t) + Math.sin(2 * Math.PI * 150 * t)) * 0.1;
}
writeWav('ambient_track.wav', ambSamples);
