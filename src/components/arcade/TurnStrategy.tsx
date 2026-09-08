import React, { useState, useEffect } from 'react';
import { sound } from '../../services/sound';

interface Props {
  dpadInput: string | null;
  actionInput: string | null;
}

type Direction = 'UP' | 'DOWN' | 'LEFT' | 'RIGHT';

interface Tank {
  r: number;
  c: number;
  hp: number;
  dir: Direction;
}

const ARENA_ROWS = 10;
const ARENA_COLS = 10;

export const TurnStrategy: React.FC<Props> = ({ dpadInput, actionInput }) => {
  const [player, setPlayer] = useState<Tank>({ r: 8, c: 5, hp: 100, dir: 'UP' });
  const [enemies, setEnemies] = useState<Tank[]>([
    { r: 1, c: 2, hp: 40, dir: 'DOWN' },
    { r: 1, c: 7, hp: 40, dir: 'DOWN' }
  ]);
  const [barricades, setBarricades] = useState<{ r: number; c: number }[]>([
    { r: 4, c: 3 }, { r: 4, c: 4 }, { r: 4, c: 5 }, { r: 4, c: 6 }
  ]);
  const [wave, setWave] = useState<number>(1);
  const [turnCount, setTurnCount] = useState<number>(1);
  const [log, setLog] = useState<string>('BATTLE START! MOVE OR FIRE.');
  const [gameOver, setGameOver] = useState<boolean>(false);
  const [victory, setVictory] = useState<boolean>(false);

  // Direction arrows display
  const dirIcon: Record<Direction, string> = {
    UP: '▲',
    DOWN: '▼',
    LEFT: '◄',
    RIGHT: '►'
  };

  // Process Controls
  useEffect(() => {
    if (gameOver || victory) {
      if (actionInput === 'START' || actionInput === 'A') {
        resetBattle();
      }
      return;
    }

    let actionTaken = false;
    let newPlayer = { ...player };

    if (dpadInput) {
      const dir = dpadInput as Direction;
      newPlayer.dir = dir;

      let nextR = newPlayer.r;
      let nextC = newPlayer.c;
      if (dir === 'UP') nextR--;
      if (dir === 'DOWN') nextR++;
      if (dir === 'LEFT') nextC--;
      if (dir === 'RIGHT') nextC++;

      // Check bounds & obstacles
      if (
        nextR >= 0 && nextR < ARENA_ROWS &&
        nextC >= 0 && nextC < ARENA_COLS &&
        !isOccupied(nextR, nextC, enemies, barricades)
      ) {
        newPlayer.r = nextR;
        newPlayer.c = nextC;
        sound.playArcadeMove();
        setLog(`MOVED ${dir}`);
      } else {
        sound.playArcadeMove();
        setLog(`FACING ${dir}`);
      }

      setPlayer(newPlayer);
      actionTaken = true;
    } else if (actionInput === 'A') {
      // FIRE CANNON
      fireCannon(player);
      sound.playArcadeAction();
      actionTaken = true;
    } else if (actionInput === 'B') {
      // DEPLOY BARRICADE
      deployBarricade(player);
      sound.playArcadeAction();
      actionTaken = true;
    }

    if (actionTaken) {
      setTurnCount(t => t + 1);
      // Enemy Turn execution after small pause
      setTimeout(() => {
        executeEnemyTurns(newPlayer);
      }, 150);
    }
  }, [dpadInput, actionInput]);

  const resetBattle = () => {
    setPlayer({ r: 8, c: 5, hp: 100, dir: 'UP' });
    setEnemies([
      { r: 1, c: 2, hp: 40, dir: 'DOWN' },
      { r: 1, c: 7, hp: 40, dir: 'DOWN' }
    ]);
    setBarricades([
      { r: 4, c: 3 }, { r: 4, c: 4 }, { r: 4, c: 5 }, { r: 4, c: 6 }
    ]);
    setWave(1);
    setTurnCount(1);
    setLog('READY! WAVE 1');
    setGameOver(false);
    setVictory(false);
  };

  const isOccupied = (r: number, c: number, enemyList: Tank[], wallList: { r: number; c: number }[]) => {
    if (wallList.some(w => w.r === r && w.c === c)) return true;
    if (enemyList.some(e => e.r === r && e.c === c)) return true;
    return false;
  };

  const fireCannon = (shooter: Tank) => {
    let r = shooter.r;
    let c = shooter.c;
    let hit = false;

    setLog(`CANNON FIRED ${shooter.dir}!`);

    while (!hit) {
      if (shooter.dir === 'UP') r--;
      if (shooter.dir === 'DOWN') r++;
      if (shooter.dir === 'LEFT') c--;
      if (shooter.dir === 'RIGHT') c++;

      if (r < 0 || r >= ARENA_ROWS || c < 0 || c >= ARENA_COLS) break;

      // Check barricade hit
      const wallIdx = barricades.findIndex(w => w.r === r && w.c === c);
      if (wallIdx !== -1) {
        setBarricades(prev => prev.filter((_, i) => i !== wallIdx));
        setLog('BARRICADE DESTROYED!');
        sound.playClear();
        hit = true;
        break;
      }

      // Check enemy hit
      const enemyIdx = enemies.findIndex(e => e.r === r && e.c === c);
      if (enemyIdx !== -1) {
        sound.playScoreWin();
        setEnemies(prev => {
          const updated = [...prev];
          updated[enemyIdx].hp -= 25;
          if (updated[enemyIdx].hp <= 0) {
            setLog('ENEMY TANK ELIMINATED!');
            updated.splice(enemyIdx, 1);
          } else {
            setLog(`HIT ENEMY! HP: ${updated[enemyIdx].hp}`);
          }

          if (updated.length === 0) {
            setVictory(true);
            sound.playScoreWin();
          }

          return updated;
        });
        hit = true;
        break;
      }
    }
  };

  const deployBarricade = (p: Tank) => {
    let r = p.r;
    let c = p.c;
    if (p.dir === 'UP') r--;
    if (p.dir === 'DOWN') r++;
    if (p.dir === 'LEFT') c--;
    if (p.dir === 'RIGHT') c++;

    if (r >= 0 && r < ARENA_ROWS && c >= 0 && c < ARENA_COLS) {
      if (!isOccupied(r, c, enemies, barricades)) {
        setBarricades(prev => [...prev, { r, c }]);
        setLog('BARRICADE DEPLOYED');
      }
    }
  };

  const executeEnemyTurns = (currentP: Tank) => {
    setEnemies(prevEnemies => {
      const updated = prevEnemies.map(enemy => {
        let e = { ...enemy };

        // If in same row or column as player, shoot!
        if (e.r === currentP.r) {
          e.dir = e.c > currentP.c ? 'LEFT' : 'RIGHT';
          // Check line of sight
          sound.playGameOver();
          setPlayer(p => {
            const nextHp = Math.max(0, p.hp - 15);
            if (nextHp === 0) setGameOver(true);
            return { ...p, hp: nextHp };
          });
          setLog('ENEMY SHOT YOU! -15 HP');
          return e;
        } else if (e.c === currentP.c) {
          e.dir = e.r > currentP.r ? 'UP' : 'DOWN';
          sound.playGameOver();
          setPlayer(p => {
            const nextHp = Math.max(0, p.hp - 15);
            if (nextHp === 0) setGameOver(true);
            return { ...p, hp: nextHp };
          });
          setLog('ENEMY SHOT YOU! -15 HP');
          return e;
        }

        // Otherwise move towards player
        const dr = currentP.r - e.r;
        const dc = currentP.c - e.c;
        if (Math.abs(dr) > Math.abs(dc)) {
          e.dir = dr > 0 ? 'DOWN' : 'UP';
          const nextR = e.r + (dr > 0 ? 1 : -1);
          if (!isOccupied(nextR, e.c, [], barricades) && !(nextR === currentP.r && e.c === currentP.c)) {
            e.r = nextR;
          }
        } else {
          e.dir = dc > 0 ? 'RIGHT' : 'LEFT';
          const nextC = e.c + (dc > 0 ? 1 : -1);
          if (!isOccupied(e.r, nextC, [], barricades) && !(e.r === currentP.r && nextC === currentP.c)) {
            e.c = nextC;
          }
        }

        return e;
      });

      return updated;
    });
  };

  return (
    <div style={{ width: '100%', height: '100%', display: 'flex', flexDirection: 'column' }}>
      {/* Header */}
      <div style={{
        display: 'flex',
        justifyContent: 'space-between',
        padding: '5px 10px',
        fontFamily: 'var(--font-pixel)',
        fontSize: '9px',
        color: 'var(--screen-text)',
        borderBottom: '2px solid var(--screen-border)',
        background: 'rgba(0,0,0,0.08)'
      }}>
        <span>HP:{player.hp}%</span>
        <span>TURN:{turnCount}</span>
        <span>WAVE:{wave}</span>
      </div>

      {/* Log Strip */}
      <div style={{
        padding: '3px 8px',
        fontFamily: 'var(--font-mono)',
        fontSize: '11px',
        color: 'var(--screen-text)',
        borderBottom: '1px solid var(--screen-border)',
        background: 'rgba(0,0,0,0.04)',
        textAlign: 'center',
        whiteSpace: 'nowrap',
        overflow: 'hidden',
        textOverflow: 'ellipsis'
      }}>
        {log}
      </div>

      {/* Grid Arena */}
      <div style={{
        flex: 1,
        display: 'grid',
        gridTemplateColumns: `repeat(${ARENA_COLS}, 1fr)`,
        gridTemplateRows: `repeat(${ARENA_ROWS}, 1fr)`,
        gap: '2px',
        padding: '4px',
        position: 'relative'
      }}>
        {Array.from({ length: ARENA_ROWS * ARENA_COLS }).map((_, idx) => {
          const r = Math.floor(idx / ARENA_COLS);
          const c = idx % ARENA_COLS;

          const isPlayer = player.r === r && player.c === c;
          const enemy = enemies.find(e => e.r === r && e.c === c);
          const isBarricade = barricades.some(w => w.r === r && w.c === c);

          return (
            <div
              key={idx}
              style={{
                borderRadius: '3px',
                border: isPlayer || enemy || isBarricade ? '1px solid var(--screen-border)' : '1px solid rgba(0,0,0,0.04)',
                backgroundColor: isPlayer
                  ? 'var(--accent-red)'
                  : enemy
                  ? 'var(--screen-text)'
                  : isBarricade
                  ? 'rgba(0,0,0,0.4)'
                  : 'rgba(0,0,0,0.02)',
                color: isPlayer ? '#FFF' : enemy ? 'var(--screen-bg)' : 'var(--screen-text)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontFamily: 'var(--font-pixel)',
                fontSize: '10px'
              }}
            >
              {isPlayer ? dirIcon[player.dir] : enemy ? dirIcon[enemy.dir] : isBarricade ? '█' : ''}
            </div>
          );
        })}

        {/* Overlay */}
        {(gameOver || victory) && (
          <div style={{
            position: 'absolute',
            top: 0, left: 0, right: 0, bottom: 0,
            background: 'rgba(15, 26, 16, 0.9)',
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
            <div style={{ fontSize: '13px', color: victory ? '#00FF66' : '#FF5555' }}>
              {victory ? 'VICTORY!' : 'TANK DESTROYED'}
            </div>
            <div>TURNS SURVIVED: {turnCount}</div>
            <div style={{ fontSize: '9px', opacity: 0.85, lineHeight: '1.6' }}>
              PRESS START / A<br />TO RESTART BATTLE
            </div>
          </div>
        )}
      </div>
    </div>
  );
};
