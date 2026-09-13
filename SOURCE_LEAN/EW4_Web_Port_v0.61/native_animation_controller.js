'use strict';

// EW4 native animation controller, derived from the proven v1.4.42 state machine.
// READY-loop semantics remain conservative, but Motion@speed is now applied.
// Native x86_64 evidence: the motion record defaults speed=1.0, parses XML speed
// into +0x1c, and the live unit animation update multiplies deltaTime by that field.

function motionRecords(unit, type, index = 0, direction = 'all') {
  return (unit?.motions || []).filter(m =>
    m.type === type && Number(m.index || 0) === Number(index) && (m.direction || 'all') === direction
  );
}

function hasMotion(unit, type, index = 0, direction = 'all') {
  return motionRecords(unit, type, index, direction).length > 0;
}

function selectAttackIndex(unit, { weapon = '', targetClass = '', direction = 'all' } = {}) {
  // Native caller: weapon enum "guns" against warship/fort selects attack index 1.
  // Directional units (notably ships) may expose left/right rather than all.
  const hasAlt=hasMotion(unit,'attack',1,direction)||hasMotion(unit,'attack',1,'all');
  if (weapon === 'guns' && (targetClass === 'warship' || targetClass === 'fort') && hasAlt) return 1;
  return 0;
}

function pickMotion(unit, type, index = 0, direction = 'all') {
  let rec = motionRecords(unit, type, index, direction)[0];
  if (!rec && direction !== 'all') rec = motionRecords(unit, type, index, 'all')[0];
  return rec || null;
}

function resolveAsset(pack, motion) {
  if (!motion) return null;
  const asset = pack?.assets?.[motion.asset];
  if (!asset) throw new Error(`Missing animation asset: ${motion.asset}`);
  return { ...asset, assetId: motion.asset, motion };
}

function buildAttackChain(pack, unitName, context = {}) {
  const unit = pack?.units?.[unitName];
  if (!unit) throw new Error(`Unknown unit in animation pack: ${unitName}`);
  const direction = context.direction || 'all';
  const attackIndex = context.attackIndex ?? selectAttackIndex(unit, context);
  const attack = pickMotion(unit, 'attack', attackIndex, direction);
  if (!attack) throw new Error(`Missing attack[${attackIndex}] for ${unitName}`);

  const chain = [{ kind: 'attack', index: attackIndex, direction, asset: resolveAsset(pack, attack) }];

  // Native-proven alternate attack tail: ATTACK(index>0) -> READY.
  if (attackIndex === 0) {
    const reload = pickMotion(unit, 'reload', 0, direction);
    const finish = pickMotion(unit, 'finish', 0, direction);
    if (reload) chain.push({ kind: 'reload', index: 0, direction, asset: resolveAsset(pack, reload) });
    if (finish) chain.push({ kind: 'finish', index: 0, direction, asset: resolveAsset(pack, finish) });
  }

  const ready = pickMotion(unit, 'ready', 0, direction);
  if (!ready) throw new Error(`Missing ready motion for ${unitName}`);
  chain.push({ kind: 'ready', index: 0, direction, asset: resolveAsset(pack, ready), terminal: true });
  return chain;
}

function motionSpeed(asset) {
  const n = Number(asset?.motion?.speed ?? 1);
  return Number.isFinite(n) && n > 0 ? n : 1;
}

function rawDurationMs(asset) {
  // Native playback advances the underlying BILE animation with deltaTime * speed,
  // therefore real duration is raw frame duration / Motion@speed.
  return (Number(asset.frame_count) / Number(asset.fps || 24)) * 1000 / motionSpeed(asset);
}

function frameAtElapsed(asset, elapsedMs) {
  const fps = Number(asset.fps || 24);
  const count = Number(asset.frame_count || 1);
  const idx = Math.floor(Math.max(0, elapsedMs) * motionSpeed(asset) * fps / 1000);
  return Math.min(count - 1, Math.max(0, idx));
}

function compactDrawOrigin(unit, screenPoint, unitZoom = 1) {
  const scale = 0.5 * Number(unitZoom || 1);
  return {
    x: Number(screenPoint?.x || 0) + Number(unit?.native_anchor?.x || 0) * scale,
    y: Number(screenPoint?.y || 0) + Number(unit?.native_anchor?.y || 0) * scale,
    scale,
  };
}

function frameRect(asset, frameIndex) {
  const s = asset.runtime_sheet;
  // Full compact runtime deliberately has no expanded runtime_sheet.png cache.
  if (!s) return null;
  const i = Math.max(0, Math.min(Number(asset.frame_count || 1) - 1, Number(frameIndex || 0)));
  const col = i % s.cols;
  const row = Math.floor(i / s.cols);
  return { sx: col * s.frame_w, sy: row * s.frame_h, sw: s.frame_w, sh: s.frame_h };
}

class NativeAnimationPlayer {
  constructor(pack, unitName, context = {}, startMs = 0) {
    this.pack = pack;
    this.unitName = unitName;
    this.context = { ...context };
    this.chain = buildAttackChain(pack, unitName, context);
    this.startMs = Number(startMs || 0);
    this.phaseStarts = [];
    let t = 0;
    for (const phase of this.chain) {
      this.phaseStarts.push(t);
      if (!phase.terminal) t += rawDurationMs(phase.asset);
    }
    this.activeDurationMs = t;
  }

  sample(nowMs) {
    const elapsed = Math.max(0, Number(nowMs) - this.startMs);
    for (let i = 0; i < this.chain.length; i++) {
      const phase = this.chain[i];
      const local = elapsed - this.phaseStarts[i];
      if (phase.terminal) {
        return {
          phase: phase.kind, motionIndex: phase.index, assetId: phase.asset.assetId,
          frameIndex: 0, rect: frameRect(phase.asset, 0), terminal: true,
          completedAttackChain: elapsed >= this.activeDurationMs,
        };
      }
      const dur = rawDurationMs(phase.asset);
      if (local < dur) {
        const fi = frameAtElapsed(phase.asset, local);
        return {
          phase: phase.kind, motionIndex: phase.index, assetId: phase.asset.assetId,
          frameIndex: fi, rect: frameRect(phase.asset, fi), terminal: false,
          completedAttackChain: false,
        };
      }
    }
    throw new Error('Animation chain resolution fell through');
  }
}

const api = {
  motionRecords, hasMotion, selectAttackIndex, pickMotion, resolveAsset,
  buildAttackChain, motionSpeed, rawDurationMs, frameAtElapsed, compactDrawOrigin, frameRect, NativeAnimationPlayer,
};

if (typeof module !== 'undefined' && module.exports) module.exports = api;
if (typeof window !== 'undefined') window.EW4NativeAnimation = api;
