const security={
 'X-Content-Type-Options':'nosniff','Referrer-Policy':'strict-origin-when-cross-origin','X-Frame-Options':'DENY',
 'Content-Security-Policy':"default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self' https:; media-src 'self' https:; connect-src 'self' https://richrow-radio.129-213-164-255.sslip.io; frame-src https://www.youtube-nocookie.com; base-uri 'self'; form-action 'self'; frame-ancestors 'none'"
};
const json=(status,data,extra={})=>new Response(JSON.stringify(data),{status,headers:{...security,'Content-Type':'application/json','Cache-Control':'no-store',...extra}});
const digest=async s=>Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',new TextEncoder().encode(s)))).map(n=>n.toString(16).padStart(2,'0')).join('');
const token=()=>Array.from(crypto.getRandomValues(new Uint8Array(32))).map(n=>n.toString(16).padStart(2,'0')).join('');
const clean=(v,max)=>{if(typeof v!=='string'||!v.trim()||v.length>max)throw Error('Invalid fields');return v.trim();};
async function parse(request){if(Number(request.headers.get('Content-Length'))>16384)throw Error('Too large');const reader=request.body?.getReader();if(!reader)return {};let size=0,chunks=[];for(;;){const {value,done}=await reader.read();if(done)break;size+=value.length;if(size>16384){await reader.cancel();throw Error('Too large');}chunks.push(value);}const bytes=new Uint8Array(size);let offset=0;for(const chunk of chunks){bytes.set(chunk,offset);offset+=chunk.length;}return JSON.parse(new TextDecoder().decode(bytes)||'{}');}
async function rate(db,key,max){const now=Date.now();const r=await db.prepare(`INSERT INTO rate_limits(key,hits,expires) VALUES(?,1,?) ON CONFLICT(key) DO UPDATE SET hits=CASE WHEN expires<? THEN 1 ELSE hits+1 END, expires=CASE WHEN expires<? THEN excluded.expires ELSE expires END RETURNING hits`).bind(key,now+60000,now,now).first();return r.hits<=max;}
async function session(request,db){const raw=/\btu_session=([a-f0-9]{64})\b/.exec(request.headers.get('Cookie')||'')?.[1];if(!raw)return null;const hashed=await digest(raw);return await db.prepare('SELECT token FROM sessions WHERE token=? AND expires>?').bind(hashed,Date.now()).first();}
function allowedOrigin(request,env){const origin=request.headers.get('Origin');const actual=new URL(request.url).origin;return origin===actual&&(actual===env.PUBLIC_ORIGIN||(env.PREVIEW_ORIGIN&&actual===env.PREVIEW_ORIGIN)||actual==='http://localhost:8787');}
export default {
 async fetch(request,env,ctx){
  const url=new URL(request.url),p=url.pathname,db=env.DB;
  if(!p.startsWith('/api/')){
   if(!['GET','HEAD'].includes(request.method))return json(405,{error:'Method not allowed'});
   if(p==='/admin')url.pathname='/admin.html';
   const response=await env.ASSETS.fetch(new Request(url,request));const h=new Headers(response.headers);for(const [k,v]of Object.entries(security))h.set(k,v);return new Response(response.body,{status:response.status,headers:h});
  }
  if(!db)return json(503,{error:'The service is being prepared. Please try again later.'});
  try{
   const ip=request.headers.get('CF-Connecting-IP')||'local';const key=await digest(ip);
   if(!await rate(db,'all:'+key,60))return json(429,{error:'Please wait a minute and try again.'});
   if(request.method==='POST'&&(!allowedOrigin(request,env)||!request.headers.get('Content-Type')?.startsWith('application/json')))return json(403,{error:'Request rejected'});
   if(p==='/api/content'&&request.method==='GET'){const {results}=await db.prepare("SELECT id,kind,body FROM records WHERE published=1 AND kind NOT IN ('booking','chat') ORDER BY id DESC").all();return json(200,results.map(r=>({...r,body:JSON.parse(r.body)})));}
   if(p==='/api/chat'&&request.method==='GET'){const {results}=await db.prepare("SELECT id,body FROM records WHERE kind='chat' AND published=1 ORDER BY id DESC LIMIT 50").all();return json(200,results.reverse().map(r=>({...r,body:JSON.parse(r.body)})));}
   if(p==='/api/booking'&&request.method==='POST'){if(!await rate(db,'booking:'+key,5))return json(429,{error:'Please wait a minute and try again.'});const b=await parse(request);if(b.website)return json(200,{ok:true});const record={name:clean(b.name,100),email:clean(b.email,254),type:clean(b.type,100),date:clean(b.date,30),message:clean(b.message,2000)};if(!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(record.email))throw Error('Invalid email');await db.prepare("INSERT INTO records(kind,body) VALUES('booking',?)").bind(JSON.stringify(record)).run();return json(201,{ok:true});}
   if(p==='/api/chat'&&request.method==='POST'){if(!await rate(db,'chat:'+key,5))return json(429,{error:'Please wait a minute and try again.'});const b=await parse(request);await db.prepare("INSERT INTO records(kind,body) VALUES('chat',?)").bind(JSON.stringify({name:clean(b.name,40),message:clean(b.message,500)})).run();return json(201,{ok:true,pending:true});}
   if(p==='/api/admin/login'&&request.method==='POST'){
    if(!env.ADMIN_PASSWORD||env.ADMIN_PASSWORD.length<16)return json(503,{error:'Private management is not configured yet.'});
    if(!await rate(db,'login:'+key,5))return json(429,{error:'Try again in a minute.'});
    const b=await parse(request),a=await digest(env.ADMIN_PASSWORD),c=await digest(typeof b.password==='string'?b.password:'');let mismatch=0;for(let i=0;i<a.length;i++)mismatch|=a.charCodeAt(i)^c.charCodeAt(i);if(mismatch||(env.ADMIN_EMAIL&&String(b.email||'').trim().toLowerCase()!==env.ADMIN_EMAIL.trim().toLowerCase()))return json(401,{error:'Unable to sign in'});
    const raw=token();await db.prepare('INSERT INTO sessions VALUES (?,?)').bind(await digest(raw),Date.now()+8*3600000).run();return json(200,{ok:true},{'Set-Cookie':`tu_session=${raw}; HttpOnly; Secure; SameSite=Strict; Path=/; Max-Age=28800`});
   }
   if(p.startsWith('/api/admin/')){
    const signed=await session(request,db);if(!signed)return json(401,{error:'Sign in required'});
    if(p==='/api/admin/logout'&&request.method==='POST'){await db.prepare('DELETE FROM sessions WHERE token=?').bind(signed.token).run();return json(200,{ok:true},{'Set-Cookie':'tu_session=; HttpOnly; Secure; SameSite=Strict; Path=/; Max-Age=0'});}
    if(p==='/api/admin/records'&&request.method==='GET'){const {results}=await db.prepare('SELECT * FROM records ORDER BY id DESC LIMIT 200').all();return json(200,results.map(r=>({...r,body:JSON.parse(r.body)})));}
    if(p==='/api/admin/record'&&request.method==='POST'){const b=await parse(request);if(b.id){const r=await db.prepare('SELECT kind FROM records WHERE id=?').bind(Number(b.id)).first();if(!r)return json(404,{error:'Record not found'});if(r.kind==='booking')throw Error('Private booking');await db.prepare('UPDATE records SET published=? WHERE id=?').bind(b.published?1:0,Number(b.id)).run();return json(200,{ok:true});}
     if(!['team','events','music','videos','gallery','merch','chat'].includes(b.kind))throw Error('Invalid kind');const record={title:clean(b.title,120),description:clean(b.description,1000)};if(b.kind==='chat'){record.name='Team Unstoppable';record.message=record.description;}for(const field of ['url','image'])if(b[field]){const u=new URL(b[field]);if(u.protocol!=='https:')throw Error('Invalid URL');record[field]=u.href;}
     await db.prepare('INSERT INTO records(kind,body,published) VALUES(?,?,?)').bind(b.kind,JSON.stringify(record),b.published?1:0).run();return json(201,{ok:true});}
   }
   return json(404,{error:'Not found'});
  }catch(error){console.error('Request failed:',error instanceof SyntaxError?'invalid JSON':error.message);return json(400,{error:'Please check your entries and try again.'});}
 },
 async scheduled(event,env){await env.DB.batch([env.DB.prepare('DELETE FROM sessions WHERE expires<?').bind(Date.now()),env.DB.prepare('DELETE FROM rate_limits WHERE expires<?').bind(Date.now())]);}
};
