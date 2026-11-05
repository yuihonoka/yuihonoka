// 小鱼yu的手机 锁屏解锁：输入密码，或粘贴带 #t= 的链接
const LOCK='https://raw.githubusercontent.com/yuihonoka/yuihonoka/main/xiaoyu/app/lock.json';
const hx=s=>new Uint8Array(s.match(/../g).map(h=>parseInt(h,16)));
export async function go(){
  const v=(prompt('输入解锁密码')||'').trim(); if(!v) return;
  const IS_GW=h=>/trycloudflare\.com$|^localhost$|^127\./.test(h);
  let tok='', server='';
  try{const u=new URL(v);tok=u.searchParams.get('t')||(u.hash.startsWith('#t=')?decodeURIComponent(u.hash.slice(3)):'');server=IS_GW(u.hostname)?u.origin:''}catch(e){}
  if(!tok){
    try{
      const j=await (await fetch(LOCK+'?_='+Date.now(),{cache:'no-store'})).json();
      const base=await crypto.subtle.importKey('raw',new TextEncoder().encode(v),'PBKDF2',false,['deriveKey']);
      const key=await crypto.subtle.deriveKey({name:'PBKDF2',salt:hx(j.salt),iterations:j.it,hash:'SHA-256'},base,{name:'AES-CBC',length:256},false,['decrypt']);
      const ct=Uint8Array.from(atob(j.ct),c=>c.charCodeAt(0));
      tok=new TextDecoder().decode(await crypto.subtle.decrypt({name:'AES-CBC',iv:hx(j.iv)},key,ct)).trim();
    }catch(e){alert('密码不对');return}
  }
  localStorage.setItem('yq_cfg',JSON.stringify({server,token:tok}));location.reload();
}
