// Verify the exported game's actual WebAudio output without taking screenshots.
const { chromium } = require(process.argv[2]);
const { spawn } = require('node:child_process');
const fs = require('node:fs');
(async () => {
 let browser;
 const errors=[];const messages=[];
 const server=spawn('python3',['-m','http.server','8081','--bind','127.0.0.1','--directory','build'],{stdio:'ignore'});
 try {
  browser=await chromium.launch({headless:true,ignoreDefaultArgs:['--mute-audio'],executablePath:process.argv[3],args:['--no-sandbox','--use-angle=swiftshader','--enable-unsafe-swiftshader','--disable-dev-shm-usage']});
  const page=await browser.newPage({viewport:{width:1280,height:720}});
  page.on('pageerror',e=>errors.push(String(e)));
  page.on('console',m=>{messages.push(m.text());if(/SCRIPT ERROR|ERROR:|Shader compilation failed/.test(m.text()))errors.push(m.text());});
  await page.addInitScript(()=>{
   window.__audio=[];window.__audioConnections=0;
   const Native=window.AudioContext || window.webkitAudioContext;
   const originalConnect=AudioNode.prototype.connect;
   class MonitorContext extends Native {
    constructor(...args){super(...args);const analyser=this.createAnalyser();analyser.fftSize=32768;originalConnect.call(analyser,this.destination);window.__audio.push({context:this,analyser,peak:0});}
   }
   window.AudioContext=MonitorContext;
   if(window.webkitAudioContext)window.webkitAudioContext=MonitorContext;
   AudioNode.prototype.connect=function(destination,...args){const found=window.__audio.find(x=>x.context.destination===destination);if(found)window.__audioConnections++;return originalConnect.call(this,found?found.analyser:destination,...args);};
   setInterval(()=>{for(const monitor of window.__audio){const data=new Float32Array(monitor.analyser.fftSize);monitor.analyser.getFloatTimeDomainData(data);for(const value of data)monitor.peak=Math.max(monitor.peak,Math.abs(value));}},10);
  });
  await page.goto('http://127.0.0.1:8081/index.html');
  await page.waitForFunction(()=>!document.querySelector('#status'),null,{timeout:90000});
  await page.locator('canvas').click({position:{x:650,y:300}});
  await page.waitForTimeout(2500);
  await page.evaluate(()=>{const x=window.__audio[0];const tone=x.context.createOscillator();tone.connect(x.analyser);tone.start();tone.stop(x.context.currentTime+1.0);});
  await page.waitForTimeout(700);
  console.log('CALIBRATION',await page.evaluate(()=>window.__audio.map(x=>({peak:x.peak,time:x.context.currentTime}))));
  const probes=[];
  async function probe(name,action){await page.evaluate(()=>window.__audio.forEach(x=>x.peak=0));await action();await page.waitForTimeout(1200);const peak=await page.evaluate(()=>Math.max(0,...window.__audio.map(x=>x.peak)));probes.push({name,peak});if(peak<0.0001){console.log(JSON.stringify({messages,errors,diagnostics:await page.evaluate(()=>({contexts:window.__audio.map(x=>({state:x.context.state,peak:x.peak,sampleRate:x.context.sampleRate})),connections:window.__audioConnections}))}));throw new Error('No WebAudio signal for '+name);}}
  await probe('jump',()=>page.keyboard.press('Space',{delay:120}));
  await probe('dash',()=>page.keyboard.press('Shift',{delay:120}));
  await page.waitForTimeout(900);
  await probe('attack',()=>page.keyboard.press('j',{delay:120}));
  await probe('parry',()=>page.keyboard.press('f',{delay:120}));
  await probe('panel switch',()=>page.keyboard.press('3',{delay:120}));
  await probe('pause',()=>page.keyboard.press('Escape',{delay:120}));
  const geometry=JSON.parse(fs.readFileSync('build/qa/ui-geometry.json','utf8'));
  const r=geometry.controls;
  await probe('UI control',()=>page.mouse.click((r[0]+r[2]/2)*1280,(r[1]+r[3]/2)*720));
  const states=await page.evaluate(()=>window.__audio.map(x=>x.context.state));
  if(!states.includes('running'))throw new Error('AudioContext did not unlock on player input');
  if(errors.length)throw new Error(errors.join('\n'));
  fs.writeFileSync('build/qa/web-audio-results.json',JSON.stringify({passed:true,states,probes,errors},null,2));
  console.log('PASS: Exported WebAudio unlocks on input and produces real nonzero output for jump, dash, attack, parry, panel switching, pause and UI controls without engine or JavaScript errors.');
 } finally {if(browser)await browser.close();server.kill();}
})().catch(e=>{console.error(e);process.exitCode=1;});
