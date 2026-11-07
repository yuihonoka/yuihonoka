const BASE='https://47-76-159-111.sslip.io';const $=s=>document.querySelector(s);
const TK=()=>localStorage.getItem('yu_tk')||'';
async function api(p,b,ms){const c=new AbortController();const to=setTimeout(()=>c.abort(),ms||150000);try{const r=await fetch(BASE+p,{method:b?'POST':'GET',headers:{'Content-Type':'application/json','X-App-Token':TK()},body:b?JSON.stringify(b):undefined,signal:c.signal});if(r.status===401){unlockShow();throw new Error('需要先解锁')}return await r.json()}finally{clearTimeout(to)}}
function toast(t,ms){let e=$('#toast');e.textContent=t;e.classList.add('on');clearTimeout(e._t);e._t=setTimeout(()=>e.classList.remove('on'),ms||2500)}
function unlockShow(){$('#unlock').classList.add('on')}
async function ulReq(){const r=await fetch(BASE+'/api/unlock/req',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({qq:3464948964})}).then(r=>r.json()).catch(()=>({msg:'连不上服务器'}));toast(r.msg||'已发送')}
async function ulVerify(){const code=$('#ulc').value.trim();const r=await fetch(BASE+'/api/unlock/verify',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({qq:3464948964,code})}).then(r=>r.json()).catch(()=>({msg:'连不上服务器'}));
 if(r.ok&&r.token){localStorage.setItem('yu_tk',r.token);window.Y&&Y.setToken&&Y.setToken(r.token);$('#unlock').classList.remove('on');toast('解锁成功');window.onUnlocked&&onUnlocked()}else toast(r.msg||'不对')}
let AU=null;function play(src,onend){try{AU&&AU.pause()}catch(e){};if(!src){onend&&onend();return}AU=new Audio(src);AU.onended=()=>{onend&&onend()};AU.onerror=()=>{onend&&onend()};AU.play().catch(()=>onend&&onend())}
function blob2b64(b){return new Promise(r=>{const f=new FileReader();f.onload=()=>r(f.result);f.readAsDataURL(b)})}
const UNLOCK_HTML=`<div id="unlock"><div class="ub"><img src="a1.jpg"><h3>先解锁一下</h3><p>验证码会由小鱼yu发到爸比的 QQ</p><div class="btn" onclick="ulReq()">发验证码</div><input id="ulc" inputmode="numeric" placeholder="6 位验证码"><div class="btn pri" onclick="ulVerify()">解锁</div></div></div><div id="toast"></div>`;
