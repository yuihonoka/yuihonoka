// 小鱼yu的手机 锁屏：只有主人 QQ 收到小鱼yu发的验证码才能解锁；解锁后这台设备会记住
const GW='https://raw.githubusercontent.com/yuihonoka/yuihonoka/main/xiaoyu/app/gw.json';
const GWAPI='https://api.github.com/repos/yuihonoka/yuihonoka/contents/xiaoyu/app/gw.json?ref=main';
async function gw(){if(/sslip\.io$/.test(location.hostname))return location.origin;try{const p=await (await fetch('https://yuihonoka.github.io/yuihonoka/xiaoyu/app/gw.json?_='+Date.now(),{cache:'no-store'})).json();return atob(p.u.split('').reverse().join(''))}catch(e){}let j;try{const a=await (await fetch(GWAPI+'&_='+Date.now(),{cache:'no-store'})).json();j=JSON.parse(atob(a.content.replace(/\s/g,'')))}catch(e){j=await (await fetch(GW+'?_='+Date.now(),{cache:'no-store'})).json()}return atob(j.u.split('').reverse().join(''))}
async function post(base,p,b){return (await fetch(base+p,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(b)})).json()}
export async function go(){
  const qq='3464948964'; // 只认主人的 QQ，不用再手动输入
  let base; try{base=await gw()}catch(e){alert('小鱼yu现在不在线，等会儿再试');return}
  let r; try{r=await post(base,'/api/unlock/req',{qq})}catch(e){alert('连不上小鱼yu');return}
  if(!r.ok){alert(r.msg||'不能解锁');return}
  const code=(prompt('🔒 '+r.msg+'\n输入 6 位验证码（这台手机解锁一次以后就记住了，不会再问）')||'').trim(); if(!code) return;
  const v=await post(base,'/api/unlock/verify',{qq,code});
  if(!v.ok){alert(v.msg||'验证失败');return}
  localStorage.setItem('yq_cfg',JSON.stringify({server:'',token:v.token}));location.reload();
}
