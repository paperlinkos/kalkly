import React from 'react';
import { SUPPORTED_CURRENCIES, CurrencyItem } from '../services/currency';

interface Props {
  isOpen: boolean;
  onClose: () => void;
  onSelect: (currencyCode: string) => void;
  currentCurrency: string;
  title: string;
}

export const CurrencyModal: React.FC<Props> = ({
  isOpen,
  onClose,
  onSelect,
  currentCurrency,
  title
}) => {
  if (!isOpen) return null;

  return (
    <div style={{
      position: 'absolute',
      top: 0, left: 0, right: 0, bottom: 0,
      background: 'rgba(0,0,0,0.75)',
      backdropFilter: 'blur(3px)',
      zIndex: 100,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      padding: '16px'
    }}>
      <div style={{
        background: 'var(--casing-bg)',
        border: '3px solid var(--casing-border)',
        borderRadius: '20px',
        width: '100%',
        maxHeight: '85%',
        display: 'flex',
        flexDirection: 'column',
        overflow: 'hidden',
        boxShadow: '0 10px 30px rgba(0,0,0,0.5)'
      }}>
        {/* Header */}
        <div style={{
          padding: '12px 16px',
          borderBottom: '2px solid var(--casing-border)',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center'
        }}>
          <span style={{ fontWeight: 800, fontSize: '13px', letterSpacing: '1px', textTransform: 'uppercase' }}>
            {title}
          </span>
          <button
            onClick={onClose}
            style={{
              background: 'var(--casing-border)',
              color: 'var(--casing-bg)',
              border: 'none',
              borderRadius: '50%',
              width: '24px',
              height: '24px',
              fontWeight: 'bold',
              cursor: 'pointer'
            }}
          >
            ✕
          </button>
        </div>

        {/* Currency List */}
        <div style={{
          flex: 1,
          overflowY: 'auto',
          padding: '8px'
        }}>
          {SUPPORTED_CURRENCIES.map((item: CurrencyItem) => {
            const isSelected = item.code === currentCurrency;
            return (
              <div
                key={item.code}
                onClick={() => {
                  onSelect(item.code);
                  onClose();
                }}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  padding: '10px 12px',
                  borderRadius: '10px',
                  border: isSelected ? '2px solid var(--casing-border)' : '1px solid transparent',
                  background: isSelected ? 'var(--key-bg)' : 'transparent',
                  cursor: 'pointer',
                  marginBottom: '4px'
                }}
              >
                <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                  <span style={{ fontSize: '18px' }}>{item.flag}</span>
                  <div>
                    <div style={{ fontWeight: 800, fontSize: '13px' }}>{item.code}</div>
                    <div style={{ fontSize: '11px', color: 'var(--text-muted)' }}>{item.name}</div>
                  </div>
                </div>
                <span style={{ fontWeight: 800, fontSize: '14px', fontFamily: 'var(--font-mono)' }}>
                  {item.symbol}
                </span>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
};
