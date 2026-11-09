import assert from 'node:assert/strict';
import {pool} from '../src/db.js';
const base='http://127.0.0.1:3000';const emails=[],ids=[];let videoId;
async function json(path,body,token){const r=await fetch(base+path,{method:'POST',headers:{'Content-Type':'application/json',...(token?{Authorization:'Bearer '+token}:{})},body:JSON.stringify(body)});return [r,await r.json()];}
try{
 assert.equal((await fetch(base+'/health')).status,200);
 for(let i=0;i<2;i++){const email=`integration-${Date.now()}-${i}@minitube.test`;emails.push(email);const [r,j]=await json('/api/v1/auth/register',{displayName:'Integration Test',email,password:'TestOnly1234'});assert.equal(r.status,201);ids.push(j.data);}
 const [login]=await json('/api/v1/auth/login',{email:emails[0],password:'TestOnly1234'});assert.equal(login.status,200);
 const [bad]=await json('/api/v1/videos',{videoUrl:'https://example.com/a.mp4'},ids[0].token);assert.equal(bad.status,422);
 const bytes=Buffer.alloc(64);bytes.writeUInt32BE(64);bytes.write('ftyp',4);bytes.write('isom',8);
 const form=new FormData();form.set('video',new Blob([bytes],{type:'video/mp4'}),'test.mp4');form.set('title','Integration upload');form.set('description','Synthetic container test, not playable media');form.set('categoryId','1');
 const upload=await fetch(base+'/api/v1/videos',{method:'POST',headers:{Authorization:'Bearer '+ids[0].token},body:form});const created=await upload.json();assert.equal(upload.status,201,JSON.stringify(created));videoId=created.data.id;
 const stream=await fetch(base+created.data.videoUrl,{headers:{Range:'bytes=0-11'}});assert.equal(stream.status,206);assert.equal((await stream.arrayBuffer()).byteLength,12);
 const forbidden=await fetch(base+'/api/v1/videos/'+videoId,{method:'DELETE',headers:{Authorization:'Bearer '+ids[1].token}});assert.equal(forbidden.status,403);

 const channelHeaders={Authorization:'Bearer '+ids[0].token,'Content-Type':'application/json'};
 const channelUpdate=await fetch(base+'/api/v1/me/channel',{method:'PUT',headers:channelHeaders,body:JSON.stringify({name:'Integration Channel',description:'Saved description',avatarUrl:null})});assert.equal(channelUpdate.status,200);
 const currentChannel=await (await fetch(base+'/api/v1/me/channel',{headers:channelHeaders})).json();assert.equal(currentChannel.data.name,'Integration Channel');
 const publicChannel=await (await fetch(base+'/api/v1/channels/'+currentChannel.data.id)).json();assert.equal(publicChannel.data.description,'Saved description');
 const [commentResponse,comment]=await json('/api/v1/videos/'+videoId+'/comments',{content:'Integration comment'},ids[0].token);assert.equal(commentResponse.status,201);
 const deniedComment=await fetch(base+'/api/v1/comments/'+comment.data.id,{method:'DELETE',headers:{Authorization:'Bearer '+ids[1].token}});assert.equal(deniedComment.status,403);
 const comments=await (await fetch(base+'/api/v1/videos/'+videoId+'/comments')).json();assert.equal(comments.data.length,1);
 const removedComment=await fetch(base+'/api/v1/comments/'+comment.data.id,{method:'DELETE',headers:channelHeaders});assert.equal(removedComment.status,204);
 for(let i=0;i<2;i++)assert.equal((await fetch(base+'/api/v1/me/history/'+videoId,{method:'PUT',headers:channelHeaders})).status,204);
 const history=await (await fetch(base+'/api/v1/me/history',{headers:channelHeaders})).json();assert.equal(history.meta.total,1);
 const otherHistory=await (await fetch(base+'/api/v1/me/history',{headers:{Authorization:'Bearer '+ids[1].token}})).json();assert.equal(otherHistory.meta.total,0);
 await fetch(base+'/api/v1/me/history/'+videoId,{method:'DELETE',headers:{Authorization:'Bearer '+ids[1].token}});
 assert.equal((await (await fetch(base+'/api/v1/me/history',{headers:channelHeaders})).json()).meta.total,1);
 await fetch(base+'/api/v1/me/history',{method:'DELETE',headers:channelHeaders});
 assert.equal((await (await fetch(base+'/api/v1/me/history',{headers:channelHeaders})).json()).meta.total,0);
 console.log('PASS channel persistence, public channel, comment authorship, history upsert and account isolation.');

 const badForm=new FormData();badForm.set('video',new Blob(['invalid video']),'broken.mp4');badForm.set('title','Broken');badForm.set('categoryId','1');
 const badReplace=await fetch(base+'/api/v1/videos/'+videoId+'/file',{method:'PUT',headers:{Authorization:'Bearer '+ids[0].token},body:badForm});assert.equal(badReplace.status,422);
 assert.equal((await (await fetch(base+'/api/v1/videos/'+videoId+'/stream')).arrayBuffer()).byteLength,64);
 const replacement=Buffer.alloc(80);replacement.writeUInt32BE(80);replacement.write('ftyp',4);replacement.write('isom',8);
 const replacementForm=()=>{const f=new FormData();f.set('video',new Blob([replacement]),'replacement.mp4');f.set('title','Replaced video');f.set('categoryId','2');return f;};
 assert.equal((await fetch(base+'/api/v1/videos/'+videoId+'/file',{method:'PUT',headers:{Authorization:'Bearer '+ids[1].token},body:replacementForm()})).status,403);
 const replaced=await fetch(base+'/api/v1/videos/'+videoId+'/file',{method:'PUT',headers:{Authorization:'Bearer '+ids[0].token},body:replacementForm()});assert.equal(replaced.status,200);const data=await replaced.json();assert.equal(data.data.id,videoId);
 assert.equal((await (await fetch(base+'/api/v1/videos/'+videoId+'/stream')).arrayBuffer()).byteLength,80);
 console.log('PASS replacement preserves video ID, rejects wrong owner and retains original media on failure.');
 const deleted=await fetch(base+'/api/v1/videos/'+videoId,{method:'DELETE',headers:{Authorization:'Bearer '+ids[0].token}});assert.equal(deleted.status,204);videoId=null;
 assert.equal((await fetch(base+created.data.videoUrl)).status,404);
 console.log('PASS health, registration, login, URL rejection, multipart upload, range streaming, ownership, deletion.');
} finally {
 for(const a of ids){if(videoId)await pool.execute('DELETE FROM videos WHERE id=? AND channel_id IN (SELECT id FROM channels WHERE owner_id=?)',[videoId,a.user.id]);await pool.execute('DELETE FROM auth_sessions WHERE user_id=?',[a.user.id]);await pool.execute('DELETE FROM channels WHERE owner_id=?',[a.user.id]);await pool.execute('DELETE FROM users WHERE id=?',[a.user.id]);}
 await pool.end();
}
