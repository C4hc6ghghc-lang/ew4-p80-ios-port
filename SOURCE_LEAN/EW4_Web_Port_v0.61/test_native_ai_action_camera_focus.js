const fs=require('fs'),assert=require('assert');
const app=fs.readFileSync('app.js','utf8'),sw=fs.readFileSync('sw.js','utf8');

// Native action-presentation controller 0x59f30 is shared by AI-driven actions too;
// Web AI must use the same proven pair focus gate unless fast-forward skips presentation.
assert(app.includes('function queueNativeAIPairFocus(source,target,continuation)'));
assert(app.includes("battleState.phase!=='ai'||battleState.aiFastForward"));
assert(app.includes("battleState.cameraPresentationKind='ai'"));
assert(app.includes('if(queueNativeAIPairFocus(u,target,runAttack))return;runAttack();return'));
assert(app.includes("if(moved&&queueNativeAIPairFocus(u,{q:plan.q,r:plan.r},applyMove))return;applyMove()"));

// AI fast-forward must remain usable while a normal AI camera presentation is active.
// It skips focus for subsequent actions rather than changing combat rules/scheduler order.
const round="document.getElementById('round-btn').onclick=()=>{if(!battleState||battleState.ended||battleState.dialogueActive)return;if(battleState.phase==='ai'){battleState.aiFastForward=true;flash('快进敌军行动',700);return}if(battleState.cameraPresentationPending||battleState.cameraMotion)return;";
assert(app.includes(round));

// Presentation-kind bookkeeping must clear after the motor completes.
assert(app.includes('state.cameraPresentationPending=false;state.cameraPresentationKind=null;'));
assert(app.includes('cameraPresentationPending:false,cameraPresentationKind:null'));
assert(sw.includes("ew4-port-v061-r14-39-posthandoff"));
console.log('native AI action camera focus: PASS');
