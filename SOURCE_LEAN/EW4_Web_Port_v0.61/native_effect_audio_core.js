(function(root,factory){if(typeof module==='object'&&module.exports)module.exports=factory();else root.EW4NativeEffectAudio=factory()})(typeof globalThis!=='undefined'?globalThis:this,function(){
'use strict';
const SIMPLE={
 'Privateer':'privateer','Frigate':'frigate','Battleship':'battleship','Ironclad':'ironclad',
 'Small Fortress':'Small Fortress','Fortress':'Fortress','Large Fortress':'Large Fortress','Coastal Fort':'Coastal Fort'
};
const GRADED={
 'Militia':'militia','Line Infantry':'line infantry','Light Infantry':'light infantry','Grenadier':'grenadier','Guards':'guards','Machine Gun':'machine gun',
 'Light Cavalry':'light cavalry','Heavy Cavalry':'heavy cavalry','Guards Cavalry':'guards cavalry','Armored Car':'armored chariot',
 'Light Artillery':'light artillery','Heavy Artillery':'heavy artillery','Siege Artillery':'siege artillery','Rocket':'rocket'
};
const INDIA_SPECIAL=new Set(['Militia','Light Infantry','Guards']);
function directionFromDelta(dx){return Number(dx)<0?'left':'right'}
function resolveTimeline(unit,direction='right',countryCode=''){
 if(!unit)return null;direction=direction==='left'?'left':'right';const name=unit.army_name||unit.name||'';
 if(SIMPLE[name])return `${SIMPLE[name]} ${direction}`;
 const base=GRADED[name];if(!base)return null;const grade=Math.max(1,(Number(unit.grade)||0)+1),ind=(countryCode==='ind'&&INDIA_SPECIAL.has(name))?' ind':'';
 return `${base}${ind} ${grade} ${direction}`;
}
function cues(data,timeline){const arr=data?.timelines?.[timeline]||[];return arr.filter(Boolean).map(x=>({at:+x.at||0,sound:x.sound||'',effect:x.effect||'',x:+x.x||0,y:+x.y||0,rot:+x.rot||0}));}
function audioCues(data,timeline){return cues(data,timeline).filter(x=>x.sound);}
function visualCues(data,timeline){return cues(data,timeline).filter(x=>x.effect);}
function scheduledCues(data,timeline,presentationSpeed=1){const speed=Math.max(1e-6,Number(presentationSpeed)||1);return cues(data,timeline).map(c=>({...c,delayMs:c.at*1000/speed}));}
function scheduledAudioCues(data,timeline,presentationSpeed=1){const speed=Math.max(1e-6,Number(presentationSpeed)||1);return audioCues(data,timeline).map(c=>({...c,delayMs:c.at*1000/speed}));}
return{resolveTimeline,directionFromDelta,cues,audioCues,visualCues,scheduledCues,scheduledAudioCues};
});
