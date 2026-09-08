import React, { useState } from 'react';
import { PixelRacer } from './arcade/PixelRacer';
import { PixelMathMatch } from './arcade/PixelMathMatch';
import { PixelMatch3 } from './arcade/PixelMatch3';
import { TurnStrategy } from './arcade/TurnStrategy';
import { CurrencyModal } from './CurrencyModal';
import { currencyService, SUPPORTED_CURRENCIES } from '../services/currency';
import { ArrowLeftRight, RefreshCw } from 'lucide-react';

interface Props {
  mode: 'CALC' | 'CURRENCY' | 'ARCADE';
  // Calculator props
  calcDisplay: string;
  calcHistory: string[];

  // Currency props
  fromCurrency: string;
  toCurrency: string;
  currencyAmount: string;
  onSetFromCurrency: (code: string) => void;
  onSetToCurrency: (code: string) => void;
  onSwapCurrencies: () => void;

  // Arcade inputs
  arcadeGame: number; // 0, 1, 2, 3
  onSelectArcadeGame: (gameIndex: number) => void;
  dpadInput: string | null;
  actionInput: string | null;
}

export const UpperBezelScreen: React.FC<Props> = ({
  mode,
  calcDisplay,
  calcHistory,
  fromCurrency,
  toCurrency,
  currencyAmount,
  onSetFromCurrency,
  onSetToCurrency,
  onSwapCurrencies,
  arcadeGame,
  onSelectArcadeGame,
  dpadInput,
  actionInput
}) => {
  const [modalType, setModalType] = useState<'FROM' | 'TO' | null>(null);

  // Currency calculations
  const numericAmount = parseFloat(currencyAmount) || 0;
  const conversion = currencyService.convert(numericAmount, fromCurrency, toCurrency);
  const fromItem = SUPPORTED_CURRENCIES.find(c => c.code === fromCurrency) || SUPPORTED_CURRENCIES[0];
  const toItem = SUPPORTED_CURRENCIES.find(c => c.code === toCurrency) || SUPPORTED_CURRENCIES[1];

  const formatNumber = (num: number) => {
    if (isNaN(num)) return '0.00';
    return num.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  };

  return (
    <div className="lcd-screen-container">
      <div className="lcd-glare-effect" />

      {/* Mode 1: CALCULATOR */}
      {mode === 'CALC' && (
        <div style={{
          height: '100%',
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'space-between',
          padding: '16px',
          color: 'var(--screen-text)',
          zIndex: 5
        }}>
          {/* History lines */}
          <div style={{
            flex: 1,
            overflowY: 'auto',
            display: 'flex',
            flexDirection: 'column',
            justifyContent: 'flex-end',
            alignItems: 'flex-end',
            gap: '4px',
            fontFamily: 'var(--font-mono)',
            fontSize: '15px',
            color: 'var(--screen-subtext)',
            opacity: 0.8
          }}>
            {calcHistory.slice(-3).map((item, idx) => (
              <div key={idx}>{item}</div>
            ))}
          </div>

          {/* Main Arithmetic Readout */}
          <div style={{
            fontSize: calcDisplay.length > 10 ? '32px' : '44px',
            fontWeight: 800,
            fontFamily: 'var(--font-mono)',
            textAlign: 'right',
            letterSpacing: '1px',
            wordBreak: 'break-all',
            lineHeight: '1.1'
          }}>
            {calcDisplay || '0'}
          </div>
        </div>
      )}

      {/* Mode 2: CURRENCY CONVERTER */}
      {mode === 'CURRENCY' && (
        <div style={{
          height: '100%',
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'space-between',
          padding: '12px',
          color: 'var(--screen-text)',
          zIndex: 5,
          position: 'relative'
        }}>
          {/* Source Currency Card */}
          <div
            onClick={() => setModalType('FROM')}
            style={{
              background: 'rgba(0,0,0,0.06)',
              borderRadius: '12px',
              padding: '10px 12px',
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
              border: '1px solid rgba(0,0,0,0.1)',
              cursor: 'pointer'
            }}
          >
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <span style={{ fontSize: '20px' }}>{fromItem.flag}</span>
              <div>
                <div style={{ fontSize: '14px', fontWeight: 800 }}>{fromItem.code}</div>
                <div style={{ fontSize: '10px', color: 'var(--screen-subtext)' }}>SOURCE</div>
              </div>
            </div>
            <div style={{ fontSize: '22px', fontWeight: 800, fontFamily: 'var(--font-mono)' }}>
              {fromItem.symbol} {currencyAmount || '0'}
            </div>
          </div>

          {/* Center Swap Action Bar */}
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '0 4px' }}>
            <span style={{ fontSize: '10px', fontFamily: 'var(--font-mono)', color: 'var(--screen-subtext)' }}>
              RATE: 1 {fromItem.code} = {conversion.rate.toFixed(4)} {toItem.code}
            </span>
            <button
              onClick={onSwapCurrencies}
              style={{
                background: 'var(--screen-text)',
                color: 'var(--screen-bg)',
                border: 'none',
                borderRadius: '50%',
                width: '26px',
                height: '26px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                cursor: 'pointer',
                boxShadow: '0 2px 4px rgba(0,0,0,0.2)'
              }}
            >
              <ArrowLeftRight size={13} />
            </button>
          </div>

          {/* Target Currency Card */}
          <div
            onClick={() => setModalType('TO')}
            style={{
              background: 'rgba(0,0,0,0.12)',
              borderRadius: '12px',
              padding: '10px 12px',
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
              border: '1px solid var(--screen-border)',
              cursor: 'pointer'
            }}
          >
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <span style={{ fontSize: '20px' }}>{toItem.flag}</span>
              <div>
                <div style={{ fontSize: '14px', fontWeight: 800 }}>{toItem.code}</div>
                <div style={{ fontSize: '10px', color: 'var(--screen-subtext)' }}>CONVERTED</div>
              </div>
            </div>
            <div style={{ fontSize: '22px', fontWeight: 800, fontFamily: 'var(--font-mono)' }}>
              {toItem.symbol} {formatNumber(conversion.converted)}
            </div>
          </div>

          {/* Footer Info Badge */}
          <div style={{
            display: 'flex',
            justifyContent: 'space-between',
            fontSize: '9px',
            fontFamily: 'var(--font-mono)',
            color: 'var(--screen-subtext)',
            paddingTop: '2px'
          }}>
            <span>SPREAD: 0.5% | S: {conversion.sellRate.toFixed(2)}</span>
            <span>{currencyService.getLastUpdated()}</span>
          </div>

          {/* Modal Popups */}
          <CurrencyModal
            isOpen={modalType === 'FROM'}
            onClose={() => setModalType(null)}
            onSelect={onSetFromCurrency}
            currentCurrency={fromCurrency}
            title="Select Source Currency"
          />
          <CurrencyModal
            isOpen={modalType === 'TO'}
            onClose={() => setModalType(null)}
            onSelect={onSetToCurrency}
            currentCurrency={toCurrency}
            title="Select Target Currency"
          />
        </div>
      )}

      {/* Mode 3: PIXEL ARCADE */}
      {mode === 'ARCADE' && (
        <div style={{
          height: '100%',
          display: 'flex',
          flexDirection: 'column',
          zIndex: 5
        }}>
          {/* Game Selector Chip Bar */}
          <div className="game-selector-strip">
            {['RACER', 'MATH MATCH', 'MATCH-3', 'TANK WAR'].map((name, idx) => (
              <button
                key={idx}
                className={`game-select-chip ${arcadeGame === idx ? 'active' : ''}`}
                onClick={() => onSelectArcadeGame(idx)}
              >
                {name}
              </button>
            ))}
          </div>

          {/* Active Arcade Game Screen */}
          <div style={{ flex: 1, position: 'relative' }}>
            {arcadeGame === 0 && <PixelRacer dpadInput={dpadInput} actionInput={actionInput} />}
            {arcadeGame === 1 && <PixelMathMatch dpadInput={dpadInput} actionInput={actionInput} />}
            {arcadeGame === 2 && <PixelMatch3 dpadInput={dpadInput} actionInput={actionInput} />}
            {arcadeGame === 3 && <TurnStrategy dpadInput={dpadInput} actionInput={actionInput} />}
          </div>
        </div>
      )}
    </div>
  );
};
