import React, { useState, useEffect } from 'react';
import { sound } from '../../services/sound';

interface Props {
  dpadInput: string | null;
  actionInput: string | null;
}

const GRID_SIZE = 8;
const GLYPHS = ['■', '●', '▲', '◆', '✖'];

export const PixelMatch3: React.FC<Props> = ({ dpadInput, actionInput }) => {
  const [grid, setGrid] = useState<number[][]>(() => createInitialGrid());
  const [cursor, setCursor] = useState<{ r: number; c: number }>({ r: 3, c: 3 });
  const [selectedTile, setSelectedTile] = useState<{ r: number; c: number } | null>(null);
  const [score, setScore] = useState<number>(0);
  const [movesLeft, setMovesLeft] = useState<number>(25);
  const [gameOver, setGameOver] = useState<boolean>(false);

  function createInitialGrid(): number[][] {
    const newGrid: number[][] = [];
    for (let r = 0; r < GRID_SIZE; r++) {
      const row: number[] = [];
      for (let c = 0; c < GRID_SIZE; c++) {
        row.push(Math.floor(Math.random() * GLYPHS.length));
      }
      newGrid.push(row);
    }
    return newGrid;
  }

  // Handle Controls
  useEffect(() => {
    if (gameOver) {
      if (actionInput === 'START' || actionInput === 'A') {
        resetGame();
      }
      return;
    }

    if (dpadInput) {
      sound.playArcadeMove();
      setCursor(prev => {
        let { r, c } = prev;
        if (dpadInput === 'UP') r = Math.max(0, r - 1);
        if (dpadInput === 'DOWN') r = Math.min(GRID_SIZE - 1, r + 1);
        if (dpadInput === 'LEFT') c = Math.max(0, c - 1);
        if (dpadInput === 'RIGHT') c = Math.min(GRID_SIZE - 1, c + 1);

        // If we had a tile selected, swap with new cursor position!
        if (selectedTile && (r !== selectedTile.r || c !== selectedTile.c)) {
          // Verify adjacent
          const isAdjacent = Math.abs(r - selectedTile.r) + Math.abs(c - selectedTile.c) === 1;
          if (isAdjacent) {
            swapAndCheckMatches(selectedTile, { r, c });
            setSelectedTile(null);
          }
        }

        return { r, c };
      });
    }

    if (actionInput === 'A') {
      if (!selectedTile) {
        setSelectedTile(cursor);
        sound.playArcadeAction();
      } else {
        // Deselect or swap
        if (selectedTile.r === cursor.r && selectedTile.c === cursor.c) {
          setSelectedTile(null);
        } else {
          const isAdjacent = Math.abs(cursor.r - selectedTile.r) + Math.abs(cursor.c - selectedTile.c) === 1;
          if (isAdjacent) {
            swapAndCheckMatches(selectedTile, cursor);
            setSelectedTile(null);
          } else {
            setSelectedTile(cursor);
          }
        }
      }
    }
  }, [dpadInput, actionInput]);

  const resetGame = () => {
    setGrid(createInitialGrid());
    setCursor({ r: 3, c: 3 });
    setSelectedTile(null);
    setScore(0);
    setMovesLeft(25);
    setGameOver(false);
    sound.playArcadeAction();
  };

  const swapAndCheckMatches = (t1: { r: number; c: number }, t2: { r: number; c: number }) => {
    const newGrid = grid.map(row => [...row]);
    const temp = newGrid[t1.r][t1.c];
    newGrid[t1.r][t1.c] = newGrid[t2.r][t2.c];
    newGrid[t2.r][t2.c] = temp;

    // Check matches
    const matches = findMatches(newGrid);
    if (matches.length > 0) {
      clearMatchesAndCascade(newGrid, matches);
      setMovesLeft(m => {
        const nextM = m - 1;
        if (nextM <= 0) setGameOver(true);
        return nextM;
      });
    } else {
      // Revert swap if no match
      sound.playClear();
    }
  };

  const findMatches = (board: number[][]): { r: number; c: number }[] => {
    const matched: Set<string> = new Set();

    // Horizontal
    for (let r = 0; r < GRID_SIZE; r++) {
      for (let c = 0; c < GRID_SIZE - 2; c++) {
        const val = board[r][c];
        if (val === board[r][c + 1] && val === board[r][c + 2]) {
          matched.add(`${r},${c}`);
          matched.add(`${r},${c + 1}`);
          matched.add(`${r},${c + 2}`);
        }
      }
    }

    // Vertical
    for (let c = 0; c < GRID_SIZE; c++) {
      for (let r = 0; r < GRID_SIZE - 2; r++) {
        const val = board[r][c];
        if (val === board[r + 1][c] && val === board[r + 2][c]) {
          matched.add(`${r},${c}`);
          matched.add(`${r + 1},${c}`);
          matched.add(`${r + 2},${c}`);
        }
      }
    }

    return Array.from(matched).map(key => {
      const [r, c] = key.split(',').map(Number);
      return { r, c };
    });
  };

  const clearMatchesAndCascade = (board: number[][], matches: { r: number; c: number }[]) => {
    sound.playScoreWin();
    setScore(s => s + matches.length * 15);

    matches.forEach(({ r, c }) => {
      board[r][c] = -1; // marked cleared
    });

    // Drop down
    for (let c = 0; c < GRID_SIZE; c++) {
      let emptyCount = 0;
      for (let r = GRID_SIZE - 1; r >= 0; r--) {
        if (board[r][c] === -1) {
          emptyCount++;
        } else if (emptyCount > 0) {
          board[r + emptyCount][c] = board[r][c];
          board[r][c] = -1;
        }
      }

      // Fill top empty spots
      for (let r = 0; r < emptyCount; r++) {
        board[r][c] = Math.floor(Math.random() * GLYPHS.length);
      }
    }

    setGrid([...board]);
  };

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
        <span>GLYPH MATCH</span>
        <span>MOVES:{movesLeft}</span>
        <span>SCORE:{score.toString().padStart(4, '0')}</span>
      </div>

      {/* Grid */}
      <div style={{
        flex: 1,
        display: 'grid',
        gridTemplateColumns: `repeat(${GRID_SIZE}, 1fr)`,
        gridTemplateRows: `repeat(${GRID_SIZE}, 1fr)`,
        gap: '3px',
        padding: '6px',
        position: 'relative'
      }}>
        {grid.map((row, r) =>
          row.map((val, c) => {
            const isCursor = cursor.r === r && cursor.c === c;
            const isSelected = selectedTile?.r === r && selectedTile?.c === c;

            return (
              <div
                key={`${r}-${c}`}
                style={{
                  borderRadius: '4px',
                  border: isCursor
                    ? '2px solid var(--accent-red)'
                    : isSelected
                    ? '2px solid var(--screen-text)'
                    : '1px solid rgba(0,0,0,0.1)',
                  backgroundColor: isSelected
                    ? 'rgba(0,0,0,0.25)'
                    : isCursor
                    ? 'rgba(0,0,0,0.12)'
                    : 'rgba(0,0,0,0.04)',
                  color: 'var(--screen-text)',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  fontFamily: 'var(--font-pixel)',
                  fontSize: '13px',
                  boxShadow: isCursor ? '0 0 6px var(--accent-red)' : 'none'
                }}
              >
                {GLYPHS[val] || ''}
              </div>
            );
          })
        )}

        {gameOver && (
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
            <div style={{ fontSize: '13px' }}>GAME OVER!</div>
            <div>FINAL SCORE: {score}</div>
            <div style={{ fontSize: '9px', opacity: 0.85, lineHeight: '1.6' }}>
              PRESS START / A<br />TO PLAY AGAIN
            </div>
          </div>
        )}
      </div>
    </div>
  );
};
