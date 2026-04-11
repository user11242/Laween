import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import LiveTrack from './components/LiveTrack';
import OutingSession from './components/OutingSession';
import MediaVault from './components/MediaVault';
import Ecosystem from './components/Ecosystem';
import './App.css';

function App() {
  return (
    <Router>
      <Routes>
        <Route path="/live-track" element={<LiveTrack />} />
        <Route path="/outing-session" element={<OutingSession />} />
        <Route path="/media-vault" element={<MediaVault />} />
        <Route path="/ecosystem" element={<Ecosystem />} />
        <Route path="/" element={<div style={{color: 'white', padding: '20px'}}>Promo UI Components Runner. Navigate to specific paths.</div>} />
      </Routes>
    </Router>
  )
}

export default App;
