(function(root,factory){
  const api=factory();
  if(typeof module==='object'&&module.exports)module.exports=api;
  else root.EW4NativeCampaignLine=api;
})(typeof self!=='undefined'?self:this,function(){
  'use strict';
  function attrs(text){
    const out={};String(text||'').replace(/([A-Za-z_][\w-]*)="([^"]*)"/g,(_,k,v)=>(out[k]=v,''));return out;
  }
  function parse(xml){
    const rows=[];const re=/<line\b([^>]*)\/>/g;let m;
    while((m=re.exec(String(xml||'')))){
      const a=attrs(m[1]),countries=String(a.countries||'').split(',').map(x=>x.trim()).filter(Boolean);
      rows.push({name:String(a.name||''),hide:+a.hide||0,start:+a.start||0,end:+a.end||0,stars:+a.stars||0,countries});
    }
    return rows;
  }
  function lineForZone(lines,zone){return Array.isArray(lines)?(lines[Math.max(0,(+zone||1)-1)]||null):null}
  function titleKey(line){return line?.name?`name_${line.name}`:''}
  return Object.freeze({parse,lineForZone,titleKey});
});
