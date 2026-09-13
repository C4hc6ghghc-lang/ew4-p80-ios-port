const fs=require('fs');const assert=require('assert');
const app=fs.readFileSync('app.js','utf8'),html=fs.readFileSync('index.html','utf8'),css=fs.readFileSync('r14_native_forms.css','utf8'),sw=fs.readFileSync('sw.js','utf8');
assert(app.includes('function conquestBattle(idx)'),'native conquest battle resolver missing');
assert(app.includes('function renderConquestMapPreview'),'native conquest map preview missing');
assert(app.includes('nativeConquestCellPoint'),'conquest marker native odd-row projection missing');
assert(app.includes("openCountrySelect(live,c.map,c.idx)"),'conquest card must enter native list flow');
assert(app.includes('countryChoice=c.index'),'selected country must preserve BTL owner index');
assert(!app.includes("mode:'conquestTwoCountry'"),'single-player conquest must not use multiplayer two-country selector');
assert(app.includes("playerOwner:countryChoice"),'confirm must pass selected PlayerCountryID owner to battle');
assert(!html.includes('woodpanel country-grid'),'old Web country wall must not be primary conquest UI');
assert(html.includes('id="conquest-country-map-wrap"')&&html.includes('id="conquest-country-listback"'),'form_conquestlist map/list structure missing');
assert(css.includes('left:408px;top:23px;width:160px;height:297px'),'original form_conquestlist list background geometry missing');
assert(css.includes('left:410px;top:23px;width:158px;height:273px'),'original lbox_battles geometry missing');
assert(css.includes('width:154px;height:45px'),'original conquest list item height contract missing');
assert(css.includes('left:468px;top:298px;width:80px;height:22px'),'original winbtn_ok geometry missing');
assert(css.includes('.conq-country-flags'),'lbox_country-style flag strip missing');
assert(sw.includes('posthandoff'),'P10 service worker cache not advanced');
assert(sw.includes('choosestage_back.png')&&sw.includes('new_confirm.png'),'P10 conquest form assets not precached');
console.log('native conquest UI contract PASS');


const openDefs=(app.match(/function\s+openCountrySelect\s*\(/g)||[]).length;
assert(openDefs===1,`expected exactly one openCountrySelect definition, got ${openDefs}`);
assert(app.includes('renderConquestMapPreview(b,map)'),'native conquest selector must render the map preview');
assert(app.includes("el.className='native-conquest-country-row'"),'native conquest selector must build the vertical native country rows');
assert(!app.includes("el.className='country-card'"),'legacy Web country-card selector must not remain in app.js');
