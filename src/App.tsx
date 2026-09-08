import React, { useState, useEffect, useCallback } from 'react';
import { DeviceFrame } from './components/DeviceFrame';
import { UpperBezelScreen } from './components/UpperBezelScreen';
import { CartridgeBar } from './components/CartridgeBar';
import { LowerControlDeck } from './components/LowerControlDeck';
import { sound } from './services/sound';

export const App: React.FC = () => {
  const [mode, setMode] = useState<'CALC' | 'CURRENCY' | 'ARCADE'>('CALC');

  // Calculator State
  const [calcDisplay, setCalcDisplay] = useState<string>('0');
  const [calcPrev, setCalcPrev] = useState<number | null>(null);
  const [calcOp, setCalcOp] = useState<string | null>(null);
  const [calcNewInput, setCalcNewInput] = useState<boolean>(true);
  const [calcHistory, setCalcHistory] = useState<string[]>([]);

  // Currency State
  const [currencyAmount, setCurrencyAmount] = useState<string>('100');
  const [fromCurrency, setFromCurrency] = useState<string>('USD');
  const [toCurrency, setToCurrency] = useState<string>('EUR');

  // Arcade State
  const [arcadeGame, setArcadeGame] = useState<number>(0);
  const [dpadInput, setDpadInput] = useState<string | null>(null);
  const [actionInput, setActionInput] = useState<string | null>(null);

  // Transient Arcade Input triggers (reset after brief pulse)
  const triggerDpad = (dir: 'UP' | 'DOWN' | 'LEFT' | 'RIGHT') => {
    setDpadInput(dir);
    setTimeout(() => setDpadInput(null), 50);
  };

  const triggerAction = (action: 'A' | 'B' | 'START' | 'SELECT') => {
    setActionInput(action);
    setTimeout(() => setActionInput(null), 50);
  };

  // Keyboard Mapping for Handheld Controls
  const handleKeyDown = useCallback((e: KeyboardEvent) => {
    if (mode === 'ARCADE') {
      if (e.key === 'ArrowUp' || e.key === 'w' || e.key === 'W') {
        e.preventDefault();
        triggerDpad('UP');
      } else if (e.key === 'ArrowDown' || e.key === 's' || e.key === 'S') {
        e.preventDefault();
        triggerDpad('DOWN');
      } else if (e.key === 'ArrowLeft' || e.key === 'a' || e.key === 'A') {
        e.preventDefault();
        triggerDpad('LEFT');
      } else if (e.key === 'ArrowRight' || e.key === 'd' || e.key === 'D') {
        e.preventDefault();
        triggerDpad('RIGHT');
      } else if (e.key === 'z' || e.key === 'Z' || e.key === ' ' || e.key === 'Enter') {
        e.preventDefault();
        triggerAction('A');
      } else if (e.key === 'x' || e.key === 'X' || e.key === 'Shift') {
        e.preventDefault();
        triggerAction('B');
      } else if (e.key === 'p' || e.key === 'P' || e.key === 'Escape') {
        e.preventDefault();
        triggerAction('START');
      }
    } else {
      // Calculator / Currency Keyboard Input
      if (e.key >= '0' && e.key <= '9') {
        handleCalcOrCurrencyKey(e.key);
      } else if (e.key === '.') {
        handleCalcOrCurrencyKey('.');
      } else if (e.key === '+' || e.key === '-' || e.key === '*' || e.key === '/') {
        const map: Record<string, string> = { '*': '×', '/': '÷', '+': '+', '-': '-' };
        if (mode === 'CALC') handleCalcOrCurrencyKey(map[e.key]);
      } else if (e.key === 'Enter' || e.key === '=') {
        if (mode === 'CALC') handleCalcOrCurrencyKey('=');
      } else if (e.key === 'Backspace') {
        handleCalcOrCurrencyKey('DEL');
      } else if (e.key === 'Escape' || e.key === 'c' || e.key === 'C') {
        handleCalcOrCurrencyKey('C');
      }
    }
  }, [mode, calcDisplay, calcPrev, calcOp, calcNewInput, currencyAmount]);

  useEffect(() => {
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [handleKeyDown]);

  // Calculator Logic
  const handleCalcKey = (key: string) => {
    if (key >= '0' && key <= '9') {
      if (calcNewInput || calcDisplay === '0') {
        setCalcDisplay(key);
        setCalcNewInput(false);
      } else {
        if (calcDisplay.length < 14) {
          setCalcDisplay(calcDisplay + key);
        }
      }
    } else if (key === '.') {
      if (calcNewInput) {
        setCalcDisplay('0.');
        setCalcNewInput(false);
      } else if (!calcDisplay.includes('.')) {
        setCalcDisplay(calcDisplay + '.');
      }
    } else if (key === 'C') {
      setCalcDisplay('0');
      setCalcPrev(null);
      setCalcOp(null);
      setCalcNewInput(true);
      sound.playClear();
    } else if (key === 'DEL') {
      if (!calcNewInput && calcDisplay.length > 1) {
        setCalcDisplay(calcDisplay.slice(0, -1));
      } else {
        setCalcDisplay('0');
        setCalcNewInput(true);
      }
    } else if (key === '+/-') {
      const num = parseFloat(calcDisplay);
      if (!isNaN(num)) {
        setCalcDisplay((-num).toString());
      }
    } else if (key === '%') {
      const num = parseFloat(calcDisplay);
      if (!isNaN(num)) {
        setCalcDisplay((num / 100).toString());
      }
    } else if (['+', '-', '×', '÷'].includes(key)) {
      const num = parseFloat(calcDisplay);
      if (calcPrev !== null && calcOp && !calcNewInput) {
        const result = computeArithmetic(calcPrev, num, calcOp);
        setCalcPrev(result);
        setCalcDisplay(result.toString());
      } else {
        setCalcPrev(num);
      }
      setCalcOp(key);
      setCalcNewInput(true);
    } else if (key === '=') {
      if (calcPrev !== null && calcOp) {
        const currentNum = parseFloat(calcDisplay);
        const result = computeArithmetic(calcPrev, currentNum, calcOp);
        const expression = `${calcPrev} ${calcOp} ${currentNum} = ${result}`;

        setCalcHistory(prev => [...prev, expression]);
        setCalcDisplay(result.toString());
        setCalcPrev(null);
        setCalcOp(null);
        setCalcNewInput(true);
        sound.playScoreWin();
      }
    }
  };

  const computeArithmetic = (a: number, b: number, op: string): number => {
    let res = 0;
    if (op === '+') res = a + b;
    if (op === '-') res = a - b;
    if (op === '×') res = a * b;
    if (op === '÷') res = b !== 0 ? a / b : 0;

    return parseFloat(res.toFixed(8));
  };

  // Currency Keypad Logic
  const handleCurrencyKey = (key: string) => {
    if (key >= '0' && key <= '9') {
      if (currencyAmount === '0') {
        setCurrencyAmount(key);
      } else if (currencyAmount.length < 10) {
        setCurrencyAmount(currencyAmount + key);
      }
    } else if (key === '.') {
      if (!currencyAmount.includes('.')) {
        setCurrencyAmount(currencyAmount + '.');
      }
    } else if (key === 'C') {
      setCurrencyAmount('0');
      sound.playClear();
    } else if (key === 'DEL') {
      if (currencyAmount.length > 1) {
        setCurrencyAmount(currencyAmount.slice(0, -1));
      } else {
        setCurrencyAmount('0');
      }
    } else if (key === 'SWAP') {
      const temp = fromCurrency;
      setFromCurrency(toCurrency);
      setToCurrency(temp);
      sound.playModeSwitch();
    } else if (key.startsWith('PAIR_')) {
      const pairTarget = key.replace('PAIR_', '');
      setFromCurrency('USD');
      setToCurrency(pairTarget);
      sound.playClick(950);
    }
  };

  const handleCalcOrCurrencyKey = (key: string) => {
    if (mode === 'CALC') handleCalcKey(key);
    if (mode === 'CURRENCY') handleCurrencyKey(key);
  };

  return (
    <DeviceFrame>
      {/* Upper LCD Bezel Screen (~45% of height) */}
      <UpperBezelScreen
        mode={mode}
        calcDisplay={calcDisplay}
        calcHistory={calcHistory}
        fromCurrency={fromCurrency}
        toCurrency={toCurrency}
        currencyAmount={currencyAmount}
        onSetFromCurrency={setFromCurrency}
        onSetToCurrency={setToCurrency}
        onSwapCurrencies={() => {
          const temp = fromCurrency;
          setFromCurrency(toCurrency);
          setToCurrency(temp);
        }}
        arcadeGame={arcadeGame}
        onSelectArcadeGame={setArcadeGame}
        dpadInput={dpadInput}
        actionInput={actionInput}
      />

      {/* Center Cartridge Bar (~5% of height) */}
      <CartridgeBar
        mode={mode}
        onModeChange={setMode}
      />

      {/* Lower Control Deck (~50% of height) */}
      <LowerControlDeck
        mode={mode}
        onKeyPress={handleCalcOrCurrencyKey}
        onDpadPress={triggerDpad}
        onActionPress={triggerAction}
      />
    </DeviceFrame>
  );
};
