import React, { useState, useEffect, useRef } from 'react';
import { sound } from '../../services/sound';

interface Props {
  dpadInput: string | null; // 'UP' | 'DOWN' | 'LEFT' | 'RIGHT'
  actionInput: string | null; // 'A' | 'B' | 'START' | 'SELECT'
}

export const PixelRacer: React.FC<Props> = ({ dpadInput, actionInput }) => {
  const [playerLane, setPlayerLane] = useState<number>(1); // Lanes 0, 1, 2
  const [obstacles, setObstacles] = useState<{ id: number; lane: number; y: number }[]>([]);
  const [score, setScore] = useState<number>(0);
  const [highScore, setHighScore] = useState<number>(() => {
    return parseInt(localStorage.getItem('RACER_HI_SCORE') || '0', 10);
  });
  const [gameOver, setGameOver] = useState<boolean>(false);
  const [gameStarted, setGameStarted] = useState<boolean>(false);

  const nextObsId = useRef(0);
  const gameLoopRef = useRef<number | null>(null);

  // Handle Control Inputs
  useEffect(() => {
    if (dpadInput === 'LEFT') {
      setPlayerLane(prev => Math.max(0, prev - 1));
      sound.playArcadeMove();
    } else if (dpadInput === 'RIGHT') {
      setPlayerLane(prev => Math.min(2, prev + 1));
      sound.playArcadeMove();
    }

    if (actionInput === 'START' || actionInput === 'A') {
      if (!gameStarted || gameOver) {
        resetGame();
      }
    }
  }, [dpadInput, actionInput]);

  const resetGame = () => {
    setPlayerLane(1);
    setObstacles([]);
    setScore(0);
    setGameOver(false);
    setGameStarted(true);
    sound.playArcadeAction();
  };

  // Game loop tick
  useEffect(() => {
    if (!gameStarted || gameOver) return;

    const intervalTime = Math.max(80, 200 - Math.floor(score / 50) * 15);

    const timer = setInterval(() => {
      setObstacles(prevObs => {
        // Move obstacles down
        const moved = prevObs.map(o => ({ ...o, y: o.y + 1 })).filter(o => o.y < 16);

        // Check collision with player at y = 14
        const collision = moved.some(o => o.lane === playerLane && (o.y === 14 || o.y === 15));
        if (collision) {
          setGameOver(true);
          sound.playGameOver();
          setHighScore(prev => {
            const newHi = Math.max(prev, score);
            localStorage.setItem('RACER_HI_SCORE', newHi.toString());
            return newHi;
          });
          return prevObs;
        }

        // Spawn new obstacle randomly
        if (moved.length === 0 || moved[moved.length - 1].y > 5) {
          if (Math.random() < 0.65) {
            const lane = Math.floor(Math.random() * 3);
            moved.push({ id: nextObsId.current++, lane, y: 0 });
          }
        }

        setScore(s => s + 1);
        if (score > 0 && score % 25 === 0) {
          sound.playScoreWin();
        }

        return moved;
      });
    }, intervalTime);

    return () => clearInterval(timer);
  }, [gameStarted, gameOver, playerLane, score]);

  return (
    <div className="game-view-container" style={{ width: '100%', height: '100%', display: 'flex', flexDirection: 'column' }}>
      {/* Header */}
      <div style={{
        display: 'flex',
        justifyContent: 'space-between',
        padding: '6px 12px',
        fontFamily: 'var(--font-pixel)',
        fontSize: '10px',
        color: 'var(--screen-text)',
        borderBottom: '2px solid var(--screen-border)',
        background: 'rgba(0,0,0,0.08)'
      }}>
        <span>RACER</span>
        <span>SCORE:{score.toString().padStart(4, '0')}</span>
        <span>HI:{highScore.toString().padStart(4, '0')}</span>
      </div>

      {/* Grid Canvas Screen (3 Lanes x 16 Rows) */}
      <div style={{
        flex: 1,
        display: 'grid',
        gridTemplateColumns: 'repeat(3, 1fr)',
        gridTemplateRows: 'repeat(16, 1fr)',
        gap: '2px',
        padding: '6px',
        background: 'transparent',
        position: 'relative'
      }}>
        {Array.from({ length: 48 }).map((_, idx) => {
          const lane = idx % 3;
          const y = Math.floor(idx / 3);

          const isPlayer = y === 14 && lane === playerLane;
          const isObstacle = obstacles.some(o => o.lane === lane && o.y === y);

          return (
            <div
              key={idx}
              style={{
                borderRadius: '3px',
                border: '1px solid rgba(0,0,0,0.05)',
                backgroundColor: isPlayer
                  ? 'var(--accent-red)'
                  : isObstacle
                  ? 'var(--screen-text)'
                  : 'rgba(0,0,0,0.03)',
                boxShadow: isPlayer
                  ? '0 0 6px var(--accent-red)'
                  : isObstacle
                  ? '0 0 4px var(--screen-text)'
                  : 'none'
              }}
            />
          );
        })}

        {/* Start / Game Over Overlay */}
        {(!gameStarted || gameOver) && (
          <div style={{
            position: 'absolute',
            top: 0, left: 0, right: 0, bottom: 0,
            background: 'rgba(15, 26, 16, 0.85)',
            color: 'var(--screen-bg)',
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'center',
            gap: '12px',
            fontFamily: 'var(--font-pixel)',
            fontSize: '11px',
            textAlign: 'center',
            padding: '16px'
          }}>
            <div style={{ fontSize: '14px', color: gameOver ? '#FF5555' : 'var(--screen-text)' }}>
              {gameOver ? 'CRASHED!' : 'PIXEL RACER'}
            </div>
            {gameOver && <div>FINAL SCORE: {score}</div>}
            <div style={{ fontSize: '9px', opacity: 0.85, lineHeight: '1.6' }}>
              PRESS START / A<br />
              D-PAD ◄ ► TO DRIVE
            </div>
          </div>
        )}
      </div>
    </div>
  );
};
