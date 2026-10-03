import http from 'node:http';
import {readFile,mkdir} from 'node:fs/promises';
import {DatabaseSync} from 'node:sqlite';
import {randomBytes,scryptSync,timingSafeEqual} from 'node:crypto';
import path from 'node:path';
const root=path.resolve('public'); await mkdir(process.env.DATA_DIR||'data',{recursive:true});
const db=new DatabaseSync(path.join(process.env.DATA_DIR||'data','team.sqlite'));
db.exec(`PRAGMA journal_mode=WAL; CREATE TABLE IF NOT EXISTS records(id INTEGER PRIMARY KEY, kind TEXT NOT NULL, body TEXT NOT NULL, published INTEGER NOT NULL DEFAULT 0, created TEXT DEFAULT CURRENT_TIMESTAMP); CREATE TABLE IF NOT EXISTS sessions(token TEXT PRIMARY KEY, expires INTEGER);`);
const salt=randomBytes(32), password=process.env.ADMIN_PASSWORD;
const hash=password?scryptSync(password,salt,64):null;
const limits=new Map();
function rate(key,max=30){const now=Date.now();let v=limits.get(key);if(!v||v.until<now)v={n:0,until:now+60000};limits.set(key,v);return ++v.n<=max;}
setInterval(()=>{for(const [k,v]of limits)if(v.until<Date.now())limits.delete(k);db.prepare('DELETE FROM sessions WHERE expires < ?').run(Date.now());},60000).unref();
function authorized(req){const token=/\btu_session=([a-f0-9]{64})\b/.exec(req.headers.cookie||'')?.[1];return token&&db.prepare('SELECT token FROM sessions WHERE token=? AND expires>?').get(token,Date.now());}
async function body(req){let text='';for await(const chunk of req){text+=chunk;if(Buffer.byteLength(text)>16384)throw Error('Request too large');}return JSON.parse(text||'{}');}
function text(v,max){if(typeof v!=='string'||!v.trim()||v.length>max)throw Error('Invalid fields');return v.trim();}
export const server=http.createServer(async(req,res)=>{
 const url=new URL(req.url,'http://localhost');
 const send=(status,data,headers={})=>{res.writeHead(status,{'Content-Type':'application/json','Cache-Control':'no-store',...headers});res.end(JSON.stringify(data));};
 res.setHeader('X-Content-Type-Options','nosniff');res.setHeader('Referrer-Policy','strict-origin-when-cross-origin');res.setHeader('X-Frame-Options','DENY');
 res.setHeader('Content-Security-Policy',"default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self' https:; media-src 'self' https://richrow-radio.129-213-164-255.sslip.io https:; connect-src 'self' https://richrow-radio.129-213-164-255.sslip.io; frame-src https://www.youtube-nocookie.com; base-uri 'self'; form-action 'self'; frame-ancestors 'none'");
 try{
  if(url.pathname.startsWith('/api/')){
   if(!rate(req.socket.remoteAddress))return send(429,{error:'Please wait a minute and try again.'});
   if(req.method==='POST'){
    const origin=req.headers.origin;const expected=process.env.PUBLIC_ORIGIN||`http://${req.headers.host}`;
    if(origin!==expected||!req.headers['content-type']?.startsWith('application/json'))return send(403,{error:'Request rejected'});
   }
   if(url.pathname==='/api/content'&&req.method==='GET'){return send(200,db.prepare("SELECT id,kind,body FROM records WHERE published=1 AND kind NOT IN ('booking','chat') ORDER BY id DESC").all().map(r=>({...r,body:JSON.parse(r.body)})));}
   if(url.pathname==='/api/chat'&&req.method==='GET')return send(200,db.prepare("SELECT id,body FROM records WHERE kind='chat' AND published=1 ORDER BY id DESC LIMIT 50").all().reverse().map(r=>({...r,body:JSON.parse(r.body)})));
   if(url.pathname==='/api/booking'&&req.method==='POST'){const b=await body(req);if(b.website)return send(200,{ok:true});const record={name:text(b.name,100),email:text(b.email,254),type:text(b.type,100),date:text(b.date,30),message:text(b.message,2000)};if(!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(record.email))throw Error('Enter a valid email');db.prepare("INSERT INTO records(kind,body) VALUES('booking',?)").run(JSON.stringify(record));return send(201,{ok:true});}
   if(url.pathname==='/api/chat'&&req.method==='POST'){const b=await body(req);const record={name:text(b.name,40),message:text(b.message,500)};db.prepare("INSERT INTO records(kind,body) VALUES('chat',?)").run(JSON.stringify(record));return send(201,{ok:true,pending:true});}
   if(url.pathname==='/api/admin/login'&&req.method==='POST'){
    if(!hash)return send(503,{error:'Private management is not configured yet.'});
    if(!rate('login:'+req.socket.remoteAddress,5))return send(429,{error:'Try again in a minute.'});
    const b=await body(req);const candidate=scryptSync(typeof b.password==='string'?b.password:'',salt,64);
    if(!timingSafeEqual(candidate,hash)||(process.env.ADMIN_EMAIL&&String(b.email||'').trim().toLowerCase()!==process.env.ADMIN_EMAIL.trim().toLowerCase()))return send(401,{error:'Unable to sign in'});
    const token=randomBytes(32).toString('hex');db.prepare('INSERT INTO sessions VALUES (?,?)').run(token,Date.now()+8*3600000);
    return send(200,{ok:true},{'Set-Cookie':`tu_session=${token}; HttpOnly; SameSite=Strict; Path=/; Max-Age=28800${process.env.NODE_ENV==='production'?'; Secure':''}`});
   }
   if(url.pathname.startsWith('/api/admin/')){
    if(!authorized(req))return send(401,{error:'Sign in required'});
    if(url.pathname==='/api/admin/logout'&&req.method==='POST'){const token=/tu_session=([a-f0-9]{64})/.exec(req.headers.cookie)?.[1];db.prepare('DELETE FROM sessions WHERE token=?').run(token);return send(200,{ok:true},{'Set-Cookie':'tu_session=; HttpOnly; SameSite=Strict; Path=/; Max-Age=0'});}
    if(url.pathname==='/api/admin/records'&&req.method==='GET')return send(200,db.prepare('SELECT * FROM records ORDER BY id DESC LIMIT 200').all().map(r=>({...r,body:JSON.parse(r.body)})));
    if(url.pathname==='/api/admin/record'&&req.method==='POST'){const b=await body(req);if(b.id){const r=db.prepare('SELECT kind FROM records WHERE id=?').get(Number(b.id));if(!r)return send(404,{error:'Record not found'});if(r.kind==='booking')throw Error('Bookings remain private');db.prepare('UPDATE records SET published=? WHERE id=?').run(b.published?1:0,Number(b.id));return send(200,{ok:true});}
     if(!['team','events','music','videos','gallery','merch','chat'].includes(b.kind))throw Error('Invalid category');const record={title:text(b.title,120),description:text(b.description,1000)};if(b.kind==='chat'){record.name='Team Unstoppable';record.message=record.description;}
     for(const key of ['url','image'])if(b[key]){const u=new URL(b[key]);if(u.protocol!=='https:')throw Error('Use an HTTPS URL');record[key]=u.href;}
     db.prepare('INSERT INTO records(kind,body,published) VALUES(?,?,?)').run(b.kind,JSON.stringify(record),b.published?1:0);return send(201,{ok:true});}
   }
   return send(404,{error:'Not found'});
  }
  if(req.method!=='GET'&&req.method!=='HEAD')return send(405,{error:'Method not allowed'});
  const pathname=url.pathname==='/'?'/index.html':url.pathname==='/admin'?'/admin.html':url.pathname;
  const target=path.resolve(root,'.'+decodeURIComponent(pathname));if(!target.startsWith(root+path.sep))return send(403,{error:'Forbidden'});
  try{const data=await readFile(target);const mime={'.html':'text/html; charset=utf-8','.js':'text/javascript','.css':'text/css','.json':'application/json','.svg':'image/svg+xml'};res.setHeader('Content-Type',mime[path.extname(target)]||'application/octet-stream');res.end(req.method==='HEAD'?undefined:data);}catch{return send(404,{error:'Not found'});}
 }catch(e){send(400,{error:e.message==='Request too large'?e.message:'Please check your entries and try again.'});}
});
if(process.env.NODE_ENV==='production'&&(!password||password.length<16||!process.env.PUBLIC_ORIGIN?.startsWith('https://')))throw Error('Production requires a strong ADMIN_PASSWORD and HTTPS PUBLIC_ORIGIN');
server.listen(Number(process.env.PORT||4173),process.env.HOST||'127.0.0.1',()=>console.log('Team Unstoppable ready'));
