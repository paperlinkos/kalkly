import React from 'react';
import { sound } from '../services/sound';
import { Delete, ArrowLeftRight } from 'lucide-react';

interface Props {
  mode: 'CALC' | 'CURRENCY' | 'ARCADE';
  // Keypress callbacks
  onKeyPress: (key: string) => void;
  onDpadPress: (dir: 'UP' | 'DOWN' | 'LEFT' | 'RIGHT') => void;
  onActionPress: (action: 'A' | 'B' | 'START' | 'SELECT') => void;
}

export const LowerControlDeck: React.FC<Props> = ({
  mode,
  onKeyPress,
  onDpadPress,
  onActionPress
}) => {
  const handleKeyClick = (key: string) => {
    sound.playClick(key === '=' || key === 'C' ? 1000 : 750);
    onKeyPress(key);
  };

  return (
    <div className="control-deck">
      {/* 1. CALCULATOR KEYPAD GRID ($4 x 5) */}
      {mode === 'CALC' && (
        <div className="keypad-grid">
          <button className="chiclet-btn clear-btn" onClick={() => handleKeyClick('C')}>C</button>
          <button className="chiclet-btn util-btn" onClick={() => handleKeyClick('+/-')}>+/-</button>
          <button className="chiclet-btn util-btn" onClick={() => handleKeyClick('%')}>%</button>
          <button className="chiclet-btn operator" onClick={() => handleKeyClick('÷')}>÷</button>

          <button className="chiclet-btn" onClick={() => handleKeyClick('7')}>7</button>
          <button className="chiclet-btn" onClick={() => handleKeyClick('8')}>8</button>
          <button className="chiclet-btn" onClick={() => handleKeyClick('9')}>9</button>
          <button className="chiclet-btn operator" onClick={() => handleKeyClick('×')}>×</button>

          <button className="chiclet-btn" onClick={() => handleKeyClick('4')}>4</button>
          <button className="chiclet-btn" onClick={() => handleKeyClick('5')}>5</button>
          <button className="chiclet-btn" onClick={() => handleKeyClick('6')}>6</button>
          <button className="chiclet-btn operator" onClick={() => handleKeyClick('-')}>-</button>

          <button className="chiclet-btn" onClick={() => handleKeyClick('1')}>1</button>
          <button className="chiclet-btn" onClick={() => handleKeyClick('2')}>2</button>
          <button className="chiclet-btn" onClick={() => handleKeyClick('3')}>3</button>
          <button className="chiclet-btn operator" onClick={() => handleKeyClick('+')}>+</button>

          <button className="chiclet-btn util-btn" onClick={() => handleKeyClick('DEL')}>
            <Delete size={18} />
          </button>
          <button className="chiclet-btn" onClick={() => handleKeyClick('0')}>0</button>
          <button className="chiclet-btn" onClick={() => handleKeyClick('.')}>.</button>
          <button className="chiclet-btn operator" onClick={() => handleKeyClick('=')}>=</button>
        </div>
      )}

      {/* 2. CURRENCY CONVERTER KEYPAD GRID ($4 x 5) */}
      {mode === 'CURRENCY' && (
        <div className="keypad-grid">
          <button className="chiclet-btn clear-btn" onClick={() => handleKeyClick('C')}>C</button>
          <button className="chiclet-btn util-btn" onClick={() => handleKeyClick('SWAP')}>
            <ArrowLeftRight size={16} />
          </button>
          <button className="chiclet-btn util-btn" onClick={() => handleKeyClick('PAIR_EUR')}>USD/EUR</button>
          <button className="chiclet-btn util-btn" onClick={() => handleKeyClick('PAIR_GBP')}>USD/GBP</button>

          <button className="chiclet-btn" onClick={() => handleKeyClick('7')}>7</button>
          <button className="chiclet-btn" onClick={() => handleKeyClick('8')}>8</button>
          <button className="chiclet-btn" onClick={() => handleKeyClick('9')}>9</button>
          <button className="chiclet-btn util-btn" onClick={() => handleKeyClick('PAIR_JPY')}>USD/JPY</button>

          <button className="chiclet-btn" onClick={() => handleKeyClick('4')}>4</button>
          <button className="chiclet-btn" onClick={() => handleKeyClick('5')}>5</button>
          <button className="chiclet-btn" onClick={() => handleKeyClick('6')}>6</button>
          <button className="chiclet-btn util-btn" onClick={() => handleKeyClick('PAIR_CAD')}>USD/CAD</button>

          <button className="chiclet-btn" onClick={() => handleKeyClick('1')}>1</button>
          <button className="chiclet-btn" onClick={() => handleKeyClick('2')}>2</button>
          <button className="chiclet-btn" onClick={() => handleKeyClick('3')}>3</button>
          <button className="chiclet-btn util-btn" onClick={() => handleKeyClick('PAIR_NGN')}>USD/NGN</button>

          <button className="chiclet-btn util-btn" onClick={() => handleKeyClick('DEL')}>
            <Delete size={18} />
          </button>
          <button className="chiclet-btn" onClick={() => handleKeyClick('0')}>0</button>
          <button className="chiclet-btn" onClick={() => handleKeyClick('.')}>.</button>
          <button className="chiclet-btn operator" onClick={() => handleKeyClick('PAIR_INR')}>USD/INR</button>
        </div>
      )}

      {/* 3. ARCADE CONSOLE HARDWARE MORPH */}
      {mode === 'ARCADE' && (
        <div className="arcade-controls-container">
          <div className="arcade-main-controls">
            {/* Raised Cross D-Pad */}
            <div className="dpad-container">
              <div className="dpad-cross">
                <button
                  className="dpad-btn dpad-up"
                  onClick={() => onDpadPress('UP')}
                >
                  ▲
                </button>
                <button
                  className="dpad-btn dpad-left"
                  onClick={() => onDpadPress('LEFT')}
                >
                  ◄
                </button>
                <div className="dpad-center" />
                <button
                  className="dpad-btn dpad-right"
                  onClick={() => onDpadPress('RIGHT')}
                >
                  ►
                </button>
                <button
                  className="dpad-btn dpad-down"
                  onClick={() => onDpadPress('DOWN')}
                >
                  ▼
                </button>
              </div>
            </div>

            {/* Angled A/B Action Buttons */}
            <div className="action-buttons-group">
              <button
                className="arcade-action-btn btn-b"
                onClick={() => onActionPress('B')}
              >
                B
              </button>
              <button
                className="arcade-action-btn btn-a"
                onClick={() => onActionPress('A')}
              >
                A
              </button>
            </div>
          </div>

          {/* Bottom Dual Pill Switches (Select / Start) */}
          <div className="bottom-pill-bar">
            <div className="pill-switch-wrapper">
              <button
                className="pill-switch-btn"
                onClick={() => onActionPress('SELECT')}
              />
              <span className="pill-switch-label">SELECT</span>
            </div>

            <div className="pill-switch-wrapper">
              <button
                className="pill-switch-btn"
                onClick={() => onActionPress('START')}
              />
              <span className="pill-switch-label">START</span>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
