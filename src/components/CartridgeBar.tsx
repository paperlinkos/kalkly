import React from 'react';
import { sound } from '../services/sound';
import { Calculator, DollarSign, Gamepad2 } from 'lucide-react';

interface Props {
  mode: 'CALC' | 'CURRENCY' | 'ARCADE';
  onModeChange: (newMode: 'CALC' | 'CURRENCY' | 'ARCADE') => void;
}

export const CartridgeBar: React.FC<Props> = ({ mode, onModeChange }) => {
  const handleSwitch = (targetMode: 'CALC' | 'CURRENCY' | 'ARCADE') => {
    if (mode !== targetMode) {
      sound.playModeSwitch();
      onModeChange(targetMode);
    }
  };

  return (
    <div className="cartridge-bar">
      <button
        className={`cartridge-tab ${mode === 'CALC' ? 'active' : ''}`}
        onClick={() => handleSwitch('CALC')}
      >
        <div className="cartridge-tab-led" />
        <Calculator size={11} />
        <span>CALC</span>
      </button>

      <button
        className={`cartridge-tab ${mode === 'CURRENCY' ? 'active' : ''}`}
        onClick={() => handleSwitch('CURRENCY')}
      >
        <div className="cartridge-tab-led" />
        <DollarSign size={11} />
        <span>CURRENCY</span>
      </button>

      <button
        className={`cartridge-tab ${mode === 'ARCADE' ? 'active' : ''}`}
        onClick={() => handleSwitch('ARCADE')}
      >
        <div className="cartridge-tab-led" />
        <Gamepad2 size={11} />
        <span>ARCADE</span>
      </button>
    </div>
  );
};
