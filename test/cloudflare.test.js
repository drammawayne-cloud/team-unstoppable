import {generateKeyPairSync,sign,createHash} from 'node:crypto';
import {test,after} from 'node:test';import assert from 'node:assert/strict';import {DatabaseSync} from 'node:sqlite';import {readFileSync} from 'node:fs';import worker from '../cloudflare/worker.js';
const sqlite=new DatabaseSync(':memory:');sqlite.exec(readFileSync('migrations/0001_initial.sql','utf8'));sqlite.exec(readFileSync('migrations/0002_record_revisions.sql','utf8'));
const DB={prepare(sql){let args=[];return {bind(...values){args=values;return this;},async first(){return sqlite.prepare(sql).get(...args)||null;},async all(){return {results:sqlite.prepare(sql).all(...args)};},async run(){return sqlite.prepare(sql).run(...args);}};},async batch(statements){return Promise.all(statements.map(s=>s.run()));}};
const env={DB,ADMIN_EMAIL:'manager@example.com',ADMIN_PASSWORD:'test-only-long-password',PUBLIC_ORIGIN:'https://1teamunstoppable.com',ASSETS:{fetch:async()=>new Response('TEAM UNSTOPPABLE')}};
const call=(route,data,cookie='',origin=env.PUBLIC_ORIGIN)=>worker.fetch(new Request(env.PUBLIC_ORIGIN+route,{method:data?'POST':'GET',headers:{Origin:origin,'Content-Type':'application/json',Cookie:cookie},body:data?JSON.stringify(data):undefined}),env,{});
after(()=>sqlite.close());
test('Cloudflare D1 preserves booking privacy, authentication, moderation and logout',async()=>{
 assert.equal((await call('/api/admin/records')).status,401);
 assert.equal((await call('/api/booking',{},'','https://evil.example')).status,403);
 assert.equal((await call('/api/booking',{name:'Test',email:'test@example.com',type:'Club',date:'2027-01-01',message:'Private request'})).status,201);
 assert.deepEqual(await (await call('/api/content')).json(),[]);
 assert.equal((await call('/api/admin/login',{password:'wrong'})).status,401);
 assert.equal((await call('/api/admin/login',{email:'wrong@example.com',password:env.ADMIN_PASSWORD})).status,401);
 const login=await call('/api/admin/login',{email:env.ADMIN_EMAIL,password:env.ADMIN_PASSWORD});assert.equal(login.status,200);const cookie=login.headers.get('set-cookie').split(';')[0];assert.match(login.headers.get('set-cookie'),/Secure/);
 assert.equal((await call('/api/chat',{name:'Test',message:'Moderate me'})).status,201);assert.deepEqual(await (await call('/api/chat')).json(),[]);
 const records=await (await call('/api/admin/records',null,cookie)).json();const booking=records.find(r=>r.kind==='booking'),chat=records.find(r=>r.kind==='chat');
 assert.equal((await call('/api/admin/record',{id:booking.id,published:true},cookie)).status,400);
 assert.equal((await call('/api/admin/record',{id:chat.id,published:true},cookie)).status,200);assert.equal((await (await call('/api/chat')).json()).length,1);
 await call('/api/admin/logout',{},cookie);assert.equal((await call('/api/admin/records',null,cookie)).status,401);
 assert.equal((await worker.fetch(new Request(env.PUBLIC_ORIGIN+'/api/admin/login',{method:'POST',headers:{Origin:env.PUBLIC_ORIGIN,'Content-Type':'application/json'},body:'{}'}),{...env,ADMIN_PASSWORD:undefined},{})).status,503);
});
test('Cloudflare static assets receive security headers and rate limits enforce distributed state',async()=>{const r=await call('/');assert.equal(r.status,200);assert.match(r.headers.get('Content-Security-Policy'),/frame-ancestors/);for(let i=0;i<65;i++)await call('/api/content');assert.equal((await call('/api/content')).status,429);});

test('management route preserves the extensionless asset path',async()=>{let forwarded;const r=await worker.fetch(new Request(env.PUBLIC_ORIGIN+'/admin'),{...env,ASSETS:{fetch:async request=>{forwarded=new URL(request.url).pathname;return new Response('Management email');}}},{});assert.equal(forwarded,'/admin');assert.equal(r.status,200);});

test('record updates enforce revision and do not overwrite later changes',async()=>{
 sqlite.exec('DELETE FROM rate_limits');
 const login=await call('/api/admin/login',{email:env.ADMIN_EMAIL,password:env.ADMIN_PASSWORD});assert.equal(login.status,200);const cookie=login.headers.get('set-cookie').split(';')[0];
 assert.equal((await call('/api/admin/record',{kind:'team',title:'Member',description:'Original'},cookie)).status,201);
 const rows=await (await call('/api/admin/records',null,cookie)).json(),row=rows.find(r=>r.kind==='team');assert.equal(row.revision,1);
 const first=await call('/api/admin/record-update',{id:row.id,revision:1,body:{title:'Updated',description:'Safe'},published:false},cookie);assert.equal(first.status,200);assert.equal((await first.json()).revision,2);
 const stale=await call('/api/admin/record-update',{id:row.id,revision:1,body:{title:'Stale',description:'Must not save'},published:true},cookie);assert.equal(stale.status,409);
 const current=(await (await call('/api/admin/records',null,cookie)).json()).find(r=>r.id===row.id);assert.equal(current.body.title,'Updated');assert.equal(current.published,0);
});

test('signed console read-only access rejects forged, expired and changed messages',async()=>{
 sqlite.exec('DELETE FROM rate_limits');
 const {privateKey,publicKey}=generateKeyPairSync('ed25519');const verifiedEnv={...env,CONSOLE_PUBLIC_KEY:publicKey.export({type:'spki',format:'pem'})};
 const body=JSON.stringify({op:'records'});const base={iss:'https://console.richrowrecords.com',aud:'teamunstoppable',sub:'owner',exp:Date.now()+15000,jti:'once',method:'POST',path:'/api/control-center',hash:createHash('sha256').update(body).digest('hex')};
 const send=async(claims,data=body,valid=true)=>{const payload=Buffer.from(JSON.stringify(claims)).toString('base64url');const signature=sign(null,Buffer.from(payload),privateKey).toString('base64url');return worker.fetch(new Request(env.PUBLIC_ORIGIN+'/api/control-center',{method:'POST',headers:{'Content-Type':'application/json','X-RR-Console-Proof':payload+'.'+(valid?(signature[0]==='A'?'B':'A')+signature.slice(1):signature)},body:data}),verifiedEnv,{});};
 assert.equal((await send(base,body,false)).status,200);
 assert.equal((await send(base,body,true)).status,403);
 assert.equal((await send({...base,exp:Date.now()-1000},body,false)).status,403);
 assert.equal((await send(base,JSON.stringify({op:'other'}),false)).status,403);
 const valid=await (await send(base,body,false)).json();assert.ok(Array.isArray(valid.records));assert.ok(valid.records.every(x=>!['chat','booking'].includes(x.kind)));
});
