(function(root,factory){if(typeof module==='object'&&module.exports)module.exports=factory();else root.EW4NativeTutorial=factory()})(typeof self!=='undefined'?self:this,function(){
  'use strict';
  const MAP_WIDTH=79;
  const WAIT_NAMES=new Set(['wait touch','wait area','wait ui','wait action']);
  function int(v,d=0){const n=Number(v);return Number.isFinite(n)?Math.trunc(n):d}
  function areaCell(id,width=MAP_WIDTH){id=int(id,-1);return id<0?null:{id,q:id%width,r:Math.floor(id/width)}}
  function normalizeCommand(c){
    const out={name:String(c?.name||'').trim().toLowerCase()};
    for(const k of ['id','x','y','w','h','row'])if(c?.[k]!=null)out[k]=int(c[k]);
    if(c?.string!=null)out.string=String(c.string);
    return out
  }
  function normalizeScript(commands){return (Array.isArray(commands)?commands:[]).map(normalizeCommand).filter(c=>c.name)}
  function sameUI(wait,name,row){if(!wait||wait.type!=='ui'||String(wait.string)!==String(name))return false;if(wait.row==null)return true;return int(wait.row)===int(row,-999)}
  class Runner{
    constructor(hooks={}){this.hooks=hooks||{};this.commands=[];this.pc=0;this.wait=null;this.done=false;this.seed=0;this.lastCommand=null}
    load(commands){this.commands=normalizeScript(commands);this.pc=0;this.wait=null;this.done=false;this.seed=0;this.lastCommand=null;return this}
    start(commands){if(commands)this.load(commands);this.pump();return this.snapshot()}
    snapshot(){return{pc:this.pc,total:this.commands.length,wait:this.wait?{...this.wait}:null,done:this.done,seed:this.seed,lastCommand:this.lastCommand?{...this.lastCommand}:null}}
    emit(name,...args){const fn=this.hooks?.[name];if(typeof fn==='function')return fn(...args)}
    pump(){
      while(!this.done&&!this.wait&&this.pc<this.commands.length){
        const c=this.commands[this.pc],name=c.name;this.lastCommand=c;
        if(WAIT_NAMES.has(name)){
          if(name==='wait touch')this.wait={type:'touch'};
          else if(name==='wait area')this.wait={type:'area',id:int(c.id)};
          else if(name==='wait ui')this.wait={type:'ui',string:String(c.string||''),...(c.row!=null?{row:int(c.row)}:{})};
          else this.wait={type:'action'};
          this.emit('onWait',this.wait,c,this.snapshot());return
        }
        if(name==='rand seed'){this.seed=int(c.id);this.emit('onSeed',this.seed,c)}
        else if(name==='show text')this.emit('onShowText',int(c.id),c);
        else if(name==='hide text')this.emit('onHideText',c);
        else if(name==='draw ui rect')this.emit('onDrawUIRect',c);
        else if(name==='draw rect')this.emit('onDrawWorldRect',{...c,cell:areaCell(c.id)},c);
        else if(name==='clear rect')this.emit('onClearRect',c);
        else if(name==='moveto area')this.emit('onMoveToArea',areaCell(c.id),c);
        else if(name==='sel area')this.emit('onSelectArea',areaCell(c.id),c);
        else if(name==='unsel area')this.emit('onUnselectArea',areaCell(c.id),c);
        else if(name==='exit'){this.done=true;this.emit('onExit',c,this.snapshot());return}
        else this.emit('onUnknown',c);
        this.pc++
      }
      if(!this.done&&this.pc>=this.commands.length){this.done=true;this.emit('onExit',null,this.snapshot())}
    }
    resolve(){this.wait=null;this.pc++;this.pump();return this.snapshot()}
    notifyTouch(){return this.wait?.type==='touch'?this.resolve():this.snapshot()}
    notifyArea(id){id=typeof id==='object'&&id?int(id.id):int(id);return this.wait?.type==='area'&&int(this.wait.id)===id?this.resolve():this.snapshot()}
    notifyUI(name,row){return sameUI(this.wait,name,row)?this.resolve():this.snapshot()}
    notifyAction(){return this.wait?.type==='action'?this.resolve():this.snapshot()}
  }
  function commandStats(commands){const stats={};for(const c of normalizeScript(commands))stats[c.name]=(stats[c.name]||0)+1;return stats}
  return{MAP_WIDTH,areaCell,normalizeCommand,normalizeScript,Runner,commandStats};
});
