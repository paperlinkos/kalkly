import React, { useState, useEffect } from 'react';
import { Volume2, VolumeX, Moon, Sun } from 'lucide-react';
import { sound } from '../services/sound';

interface Props {
  children: React.ReactNode;
}

export const DeviceFrame: React.FC<Props> = ({ children }) => {
  const [theme, setTheme] = useState<'light' | 'dark'>('light');
  const [soundOn, setSoundOn] = useState<boolean>(true);

  useEffect(() => {
    document.documentElement.setAttribute('data-theme', theme);
  }, [theme]);

  const toggleTheme = () => {
    const nextTheme = theme === 'light' ? 'dark' : 'light';
    setTheme(nextTheme);
    sound.playClick(900);
  };

  const toggleSound = () => {
    const nextSound = !soundOn;
    setSoundOn(nextSound);
    sound.setEnabled(nextSound);
    if (nextSound) sound.playClick(1100);
  };

  return (
    <div className="device-wrapper">
      <div className="device-casing">
        {/* Top Bezel Header */}
        <div className="top-bezel-bar">
          <div className="speaker-grille">
            <div className="speaker-dot" />
            <div className="speaker-dot" />
            <div className="speaker-dot" />
            <div className="speaker-dot" />
            <div className="speaker-dot" />
            <div className="speaker-dot" />
          </div>

          <div className="brand-stamp">DYNAMO SYSTEM</div>

          <div className="system-status">
            <button
              className="sound-toggle-btn"
              onClick={toggleSound}
              title={soundOn ? 'Mute Sound' : 'Enable Sound'}
            >
              {soundOn ? <Volume2 size={15} /> : <VolumeX size={15} />}
            </button>

            <button
              className="theme-toggle-btn"
              onClick={toggleTheme}
              title={`Switch to ${theme === 'light' ? 'Dark' : 'Light'} Mode`}
            >
              {theme === 'light' ? <Moon size={15} /> : <Sun size={15} />}
            </button>

            <div className="led-indicator" title="System Powered ON" />
          </div>
        </div>

        {/* Outer Frame Content Body */}
        {children}
      </div>
    </div>
  );
};
