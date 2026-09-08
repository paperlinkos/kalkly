import React, { useState, useEffect, useRef } from 'react';
import { sound } from '../../services/sound';

interface Props {
  dpadInput: string | null;
  actionInput: string | null;
}

const COLS = 6;
const ROWS = 10;
const TARGET_SUM = 10;

export const PixelMathMatch: React.FC<Props> = ({ dpadInput, actionInput }) => {
  const [grid, setGrid] = useState<(number | null)[][]>(() =>
    Array(ROWS).fill(null).map(() => Array(COLS).fill(null))
  );

  const [activeBlock, setActiveBlock] = useState<{ x: number; y: number; val: number } | null>(null);
  const [score, setScore] = useState<number>(0);
  const [targetSum] = useState<number>(TARGET_SUM);
  const [gameOver, setGameOver] = useState<boolean>(false);
  const [gameStarted, setGameStarted] = useState<boolean>(false);

  // Handle D-Pad and Action Buttons
  useEffect(() => {
    if (!gameStarted || gameOver) {
      if (actionInput === 'START' || actionInput === 'A') {
        startGame();
      }
      return;
    }

    if (!activeBlock) return;

    if (dpadInput === 'LEFT') {
      if (activeBlock.x > 0 && !grid[activeBlock.y][activeBlock.x - 1]) {
        setActiveBlock(prev => prev ? { ...prev, x: prev.x - 1 } : null);
        sound.playArcadeMove();
      }
    } else if (dpadInput === 'RIGHT') {
      if (activeBlock.x < COLS - 1 && !grid[activeBlock.y][activeBlock.x + 1]) {
        setActiveBlock(prev => prev ? { ...prev, x: prev.x + 1 } : null);
        sound.playArcadeMove();
      }
    } else if (dpadInput === 'DOWN') {
      // Drop fast
      dropActiveBlock();
      sound.playArcadeMove();
    }

    if (actionInput === 'A' || actionInput === 'UP') {
      // Cycle value 1-9
      setActiveBlock(prev => prev ? { ...prev, val: (prev.val % 9) + 1 } : null);
      sound.playArcadeAction();
    }
  }, [dpadInput, actionInput, activeBlock, grid, gameStarted, gameOver]);

  const startGame = () => {
    setGrid(Array(ROWS).fill(null).map(() => Array(COLS).fill(null)));
    setScore(0);
    setGameOver(false);
    setGameStarted(true);
    spawnBlock();
    sound.playArcadeAction();
  };

  const spawnBlock = () => {
    const startX = Math.floor(COLS / 2);
    const val = Math.floor(Math.random() * 8) + 1; // 1-8

    if (grid[0][startX]) {
      setGameOver(true);
      sound.playGameOver();
      return;
    }

    setActiveBlock({ x: startX, y: 0, val });
  };

  const dropActiveBlock = () => {
    if (!activeBlock) return;

    if (activeBlock.y + 1 < ROWS && !grid[activeBlock.y + 1][activeBlock.x]) {
      setActiveBlock(prev => prev ? { ...prev, y: prev.y + 1 } : null);
    } else {
      // Lock block into grid
      lockBlock(activeBlock);
    }
  };

  const lockBlock = (block: { x: number; y: number; val: number }) => {
    const newGrid = grid.map(row => [...row]);
    newGrid[block.y][block.x] = block.val;

    // Check matches for target sum
    let clearedCount = 0;
    const toClear: { r: number; c: number }[] = [];

    for (let r = 0; r < ROWS; r++) {
      for (let c = 0; c < COLS; c++) {
        const val = newGrid[r][c];
        if (!val) continue;

        // Check right neighbor
        if (c + 1 < COLS && newGrid[r][c + 1]) {
          if (val + newGrid[r][c + 1]! === targetSum) {
            toClear.push({ r, c }, { r, c: c + 1 });
          }
        }
        // Check down neighbor
        if (r + 1 < ROWS && newGrid[r + 1][c]) {
          if (val + newGrid[r + 1][c]! === targetSum) {
            toClear.push({ r, c }, { r: r + 1, c });
          }
        }
      }
    }

    if (toClear.length > 0) {
      toClear.forEach(({ r, c }) => {
        newGrid[r][c] = null;
        clearedCount++;
      });
      sound.playScoreWin();
      setScore(s => s + clearedCount * 10);

      // Apply gravity drop
      for (let c = 0; c < COLS; c++) {
        let emptySpot = ROWS - 1;
        for (let r = ROWS - 1; r >= 0; r--) {
          if (newGrid[r][c] !== null) {
            const val = newGrid[r][c];
            newGrid[r][c] = null;
            newGrid[emptySpot][c] = val;
            emptySpot--;
          }
        }
      }
    }

    setGrid(newGrid);
    setActiveBlock(null);
    spawnBlock();
  };

  // Automatic tick drop
  useEffect(() => {
    if (!gameStarted || gameOver || !activeBlock) return;

    const timer = setInterval(() => {
      dropActiveBlock();
    }, 600);

    return () => clearInterval(timer);
  }, [activeBlock, gameStarted, gameOver, grid]);

  return (
    <div style={{ width: '100%', height: '100%', display: 'flex', flexDirection: 'column' }}>
      {/* Header */}
      <div style={{
        display: 'flex',
        justifyContent: 'space-between',
        padding: '6px 12px',
        fontFamily: 'var(--font-pixel)',
        fontSize: '9px',
        color: 'var(--screen-text)',
        borderBottom: '2px solid var(--screen-border)',
        background: 'rgba(0,0,0,0.08)'
      }}>
        <span>MATH MATCH</span>
        <span>TARGET:{targetSum}</span>
        <span>SCORE:{score.toString().padStart(4, '0')}</span>
      </div>

      {/* Grid */}
      <div style={{
        flex: 1,
        display: 'grid',
        gridTemplateColumns: `repeat(${COLS}, 1fr)`,
        gridTemplateRows: `repeat(${ROWS}, 1fr)`,
        gap: '2px',
        padding: '6px',
        position: 'relative'
      }}>
        {Array.from({ length: ROWS * COLS }).map((_, idx) => {
          const r = Math.floor(idx / COLS);
          const c = idx % COLS;

          const gridVal = grid[r][c];
          const isActive = activeBlock && activeBlock.x === c && activeBlock.y === r;
          const val = isActive ? activeBlock.val : gridVal;

          return (
            <div
              key={idx}
              style={{
                borderRadius: '4px',
                border: val ? '2px solid var(--screen-border)' : '1px solid rgba(0,0,0,0.05)',
                backgroundColor: isActive
                  ? 'var(--screen-text)'
                  : val
                  ? 'rgba(0,0,0,0.15)'
                  : 'rgba(0,0,0,0.03)',
                color: isActive ? 'var(--screen-bg)' : 'var(--screen-text)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontFamily: 'var(--font-pixel)',
                fontSize: '12px',
                fontWeight: 'bold'
              }}
            >
              {val || ''}
            </div>
          );
        })}

        {/* Overlay */}
        {(!gameStarted || gameOver) && (
          <div style={{
            position: 'absolute',
            top: 0, left: 0, right: 0, bottom: 0,
            background: 'rgba(15, 26, 16, 0.88)',
            color: 'var(--screen-bg)',
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'center',
            gap: '12px',
            fontFamily: 'var(--font-pixel)',
            fontSize: '10px',
            textAlign: 'center',
            padding: '16px'
          }}>
            <div style={{ fontSize: '13px' }}>{gameOver ? 'GAME OVER!' : 'MATH MATCH'}</div>
            <div>SUM ADJACENT DIGITS TO {targetSum}!</div>
            <div style={{ fontSize: '9px', opacity: 0.85, lineHeight: '1.6' }}>
              PRESS START / A<br />
              D-PAD ◄ ► MOVE | ▲ CHANGE
            </div>
          </div>
        )}
      </div>
    </div>
  );
};
