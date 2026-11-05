// Checks data and interaction logic in a DOM stub. This is NOT a browser render test.
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..');
const html=fs.readFileSync(path.join(root,'docs/presentation_demo.html'),'utf8');
const script=html.match(/<script>([\s\S]*?)<\/script>/)[1];
const nodes=new Map();
class Element {
  constructor(id,attrs={}){this.id=id;this.attrs=attrs;this.children=[];this.style={};this.value='';this.textContent='';this.hidden=false;}
  setAttribute(k,v){this.attrs[k]=v;}getAttribute(k){return this.attrs[k];}
  append(child){this.children.push(child);}replaceChildren(){this.children=[];}
  click(){this.onclick();}focus(){}
}
for(const match of html.matchAll(/<[^>]+\bid="([^"]+)"[^>]*>/g)){
  assert(!nodes.has(match[1]),'duplicate id');
  const attrs=Object.fromEntries([...match[0].matchAll(/([\w-]+)="([^"]*)"/g)].map(m=>[m[1],m[2]]));
  nodes.set(match[1],new Element(match[1],attrs));
}
const get=id=>{assert(nodes.has(id),'missing '+id);return nodes.get(id);};
get('waits').value='1';get('flip').value='0';
const tabs=[...nodes.values()].filter(e=>e.attrs.role==='tab');
vm.runInNewContext(script,{document:{getElementById:get,querySelectorAll:()=>tabs,createElement:()=>new Element(''),documentElement:{requestFullscreen:()=>Promise.resolve()}}});
assert.equal(get('speed').textContent,'115.4×');assert.equal(get('swcycles').textContent,'24,576 cycles');
get('waits').value='5';get('waits').onchange();assert.equal(get('hwcycles').textContent,'234 cycles');assert.equal(get('speed').textContent,'105.0×');
get('tab-avalanche').click();assert.equal(get('machine').hidden,true);assert.equal(get('avalanche').hidden,false);
get('tab-avalanche').onkeydown({key:'ArrowRight',preventDefault(){}});assert.equal(get('machine').hidden,false);
const records=fs.readFileSync(path.join(root,'tb/internal/benchmark_vectors.mem'),'utf8').trim().split(/\r?\n/);
for(let i=0;i<128;i++){
  get('flip').value=String(i);get('flip').oninput();
  const want=records[285+i].slice(64),original=records[284].slice(64);
  const differences=(BigInt('0x'+want)^BigInt('0x'+original)).toString(2).replace(/0/g,'').length;
  assert.equal(get('cipher1').textContent.replaceAll(' ',''),want);
  assert.equal(Number(get('changed').textContent),differences);
  assert.equal(get('bits').children.length,128);
  assert.equal(get('bits').children.filter(e=>e.className==='bit changed').length,differences);
}
get('next').click();assert.equal(Number(get('flip').value),0);
console.log('PASS presenter data/logic: two wait modes, tabs/keyboard, 128 flip selections, ciphertext bits and wrap. Browser layout NOT inspected.');
