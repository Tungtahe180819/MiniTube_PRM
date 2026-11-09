import express from 'express';
import cors from 'cors';
import multer from 'multer';
import {randomBytes,randomUUID,scryptSync,timingSafeEqual,createHash} from 'node:crypto';
import {mkdir,rename,unlink} from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {pool} from './db.js';
import {validateMp4} from './media.js';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'../storage');
const tmp=path.join(root,'tmp'),media=path.join(root,'videos');
await mkdir(tmp,{recursive:true});await mkdir(media,{recursive:true});
const app=express();app.disable('x-powered-by');app.use(cors({origin:process.env.CORS_ORIGIN||'http://localhost:5000'}));app.use(express.json({limit:'32kb'}));
const hash=s=>createHash('sha256').update(s).digest('hex');
const fail=(status,message)=>Object.assign(new Error(message),{status});
const id=v=>{if(!/^[1-9][0-9]*$/.test(String(v))) throw fail(400,'Invalid identifier.');return String(v);};
const text=(value,min,max)=>{if(typeof value!=='string')throw fail(422,'Missing text field.');const s=value.trim();if(s.length<min||s.length>max)throw fail(422,`Use ${min}-${max} characters.`);return s;};
const thumbnail=value=>{if(value==null||value==='')return null;const s=text(value,1,2048);let u;try{u=new URL(s);}catch{throw fail(422,'Thumbnail must be a direct HTTPS image URL.');}if(u.protocol!=='https:'||u.username||u.password)throw fail(422,'Thumbnail must be a direct HTTPS image URL.');return s;};
const safeDelete=async p=>{try{await unlink(p);}catch(e){if(e.code!=='ENOENT')console.error('Media cleanup failed; retry required.');}};
async function auth(req,res,next){try{const token=(req.headers.authorization||'').replace(/^Bearer /,'');const [rows]=await pool.execute('SELECT user_id FROM auth_sessions WHERE token_hash=? AND expires_at>UTC_TIMESTAMP(3)',[hash(token)]);if(!rows.length)throw fail(401,'Your session has expired.');req.userId=String(rows[0].user_id);next();}catch(e){next(e);}}
async function session(conn,userId){const token=randomBytes(32).toString('hex');const expiresAt=new Date(Date.now()+86400000);await conn.execute('INSERT INTO auth_sessions(user_id,token_hash,expires_at) VALUES(?,?,?)',[userId,hash(token),expiresAt]);return {token,expiresAt};}
const publicUser=r=>({id:String(r.id),email:r.email,displayName:r.display_name});
app.get('/health',async(req,res)=>{try{await pool.query('SELECT 1');res.json({status:'ready'});}catch{res.status(503).json({status:'database-unavailable'});}});
app.post('/api/v1/auth/register',async(req,res)=>{const name=text(req.body.displayName,2,50);const email=text(req.body.email,3,254).toLowerCase();const password=req.body.password;if(!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)||typeof password!=='string'||password.length<8||password.length>64||!/[a-z]/i.test(password)||!/[0-9]/.test(password))throw fail(422,'Invalid email or password.');const salt=randomBytes(16).toString('hex');const encoded=salt+':'+scryptSync(password,salt,64).toString('hex');const c=await pool.getConnection();try{await c.beginTransaction();const [result]=await c.execute('INSERT INTO users(email,display_name,password_hash) VALUES(?,?,?)',[email,name,encoded]);const uid=String(result.insertId);await c.execute('INSERT INTO channels(owner_id,name) VALUES(?,?)',[uid,name]);const data=await session(c,uid);await c.commit();res.status(201).json({data:{user:{id:uid,email,displayName:name},...data}});}catch(e){await c.rollback();throw e;}finally{c.release();}});
app.post('/api/v1/auth/login',async(req,res)=>{const email=text(req.body.email,3,254).toLowerCase();if(typeof req.body.password!=='string'||req.body.password.length>64)throw fail(401,'Invalid credentials.');const [rows]=await pool.execute('SELECT * FROM users WHERE email=?',[email]);if(!rows.length)throw fail(401,'Invalid credentials.');const [salt,encoded]=rows[0].password_hash.split(':');if(!timingSafeEqual(Buffer.from(encoded,'hex'),scryptSync(req.body.password,salt,64)))throw fail(401,'Invalid credentials.');res.json({data:{user:publicUser(rows[0]),...await session(pool,rows[0].id)}});});
app.post('/api/v1/auth/logout',auth,async(req,res)=>{await pool.execute('DELETE FROM auth_sessions WHERE token_hash=?',[hash(req.headers.authorization.replace(/^Bearer /,''))]);res.sendStatus(204);});
app.get('/api/v1/me',auth,async(req,res)=>{const [rows]=await pool.execute('SELECT * FROM users WHERE id=?',[req.userId]);res.json({data:publicUser(rows[0])});});
app.get('/api/v1/categories',async(req,res)=>{const [rows]=await pool.query('SELECT id,name FROM categories ORDER BY name');res.json({data:rows.map(r=>({...r,id:String(r.id)}))});});
const select=`SELECT v.*,c.name AS channel_name,c.owner_id,k.name AS category_name FROM videos v JOIN channels c ON c.id=v.channel_id JOIN categories k ON k.id=v.category_id`;
const dto=v=>({id:String(v.id),title:v.title,description:v.description,thumbnailUrl:v.thumbnail_url,createdAt:v.created_at,updatedAt:v.updated_at,videoUrl:`/api/v1/videos/${v.id}/stream`,fileName:v.original_name,sizeBytes:String(v.size_bytes),channel:{id:String(v.channel_id),ownerId:String(v.owner_id),name:v.channel_name},category:{id:String(v.category_id),name:v.category_name}});
async function findVideo(value){const [rows]=await pool.execute(select+' WHERE v.id=?',[id(value)]);if(!rows.length)throw fail(404,'Video not found.');return rows[0];}
app.get('/api/v1/videos',async(req,res)=>{const page=Math.max(1,Number(req.query.page)||1),size=20;const conditions=[],args=[];if(req.query.q){conditions.push('LOCATE(LOWER(?),LOWER(v.title))>0');args.push(text(req.query.q,1,100));}if(req.query.categoryId){conditions.push('v.category_id=?');args.push(id(req.query.categoryId));}const where=conditions.length?' WHERE '+conditions.join(' AND '):'';const [count]=await pool.execute('SELECT COUNT(*) AS total FROM videos v'+where,args);const [rows]=await pool.query(select+where+' ORDER BY v.created_at DESC,v.id DESC LIMIT ? OFFSET ?',[...args,size,(page-1)*size]);res.json({data:rows.map(dto),meta:{page,pageSize:size,total:count[0].total}});});
app.get('/api/v1/me/videos',auth,async(req,res)=>{const [rows]=await pool.execute(select+' WHERE c.owner_id=? ORDER BY v.created_at DESC,v.id DESC',[req.userId]);res.json({data:rows.map(dto)});});
app.put('/api/v1/me',auth,async(req,res)=>{await pool.execute('UPDATE users SET display_name=? WHERE id=?',[text(req.body.displayName,2,50),req.userId]);const [rows]=await pool.execute('SELECT * FROM users WHERE id=?',[req.userId]);res.json({data:publicUser(rows[0])});});
app.get('/api/v1/videos/:id',async(req,res)=>res.json({data:dto(await findVideo(req.params.id))}));
app.get('/api/v1/videos/:id/stream',async(req,res)=>{const v=await findVideo(req.params.id);res.type('video/mp4');res.sendFile(path.join(media,v.file_name),{acceptRanges:true,dotfiles:'deny'},e=>{if(e&&!res.headersSent)res.status(404).json({error:{message:'Media unavailable.'}});});});
const upload=multer({dest:tmp,limits:{fileSize:Number(process.env.MAX_VIDEO_MB||100)*1024*1024,files:1,fields:4,fieldSize:8192},fileFilter:(req,file,cb)=>cb(null,path.extname(file.originalname).toLowerCase()==='.mp4')}).single('video');
app.post('/api/v1/videos',auth,upload,async(req,res,next)=>{let stored;let conn;try{if(Object.keys(req.body).some(k=>!['title','description','categoryId','thumbnailUrl'].includes(k)))throw fail(422,'Only file upload and metadata are accepted.');if(!req.file)throw fail(422,'Choose an MP4 file. URLs are not accepted.');if(!await validateMp4(req.file.path))throw fail(422,'Invalid MP4 file content.');const title=text(req.body.title,1,120),description=text(req.body.description||'',0,2000),category=id(req.body.categoryId);const [channels]=await pool.execute('SELECT id FROM channels WHERE owner_id=?',[req.userId]);if(!channels.length)throw fail(409,'Account channel is missing.');const fileName=randomUUID()+'.mp4';stored=path.join(media,fileName);await rename(req.file.path,stored);conn=await pool.getConnection();await conn.beginTransaction();const [result]=await conn.execute('INSERT INTO videos(channel_id,category_id,title,description,file_name,original_name,size_bytes,thumbnail_url) VALUES(?,?,?,?,?,?,?,?)',[channels[0].id,category,title,description,fileName,req.file.originalname.slice(0,255),req.file.size,thumbnail(req.body.thumbnailUrl)]);const [created]=await conn.execute(select+' WHERE v.id=?',[String(result.insertId)]);await conn.commit();stored=null;res.status(201).json({data:dto(created[0])});}catch(e){if(conn)await conn.rollback();if(stored)await safeDelete(stored);next(e);}finally{if(conn)conn.release();if(req.file)await safeDelete(req.file.path);}});

app.put('/api/v1/videos/:id/file',auth,async(req,res,next)=>{const v=await findVideo(req.params.id);if(String(v.owner_id)!==req.userId)throw fail(403,'Permission denied.');next();},upload,async(req,res,next)=>{
 let stored,conn;let oldFile;let committed=false;
 try {
  if(!req.file)throw fail(422,'Choose an MP4 replacement file.');
  if(Object.keys(req.body).some(k=>!['title','description','categoryId','thumbnailUrl'].includes(k)))throw fail(422,'Only file upload and metadata are accepted.');
  if(!await validateMp4(req.file.path))throw fail(422,'Invalid MP4 file content.');
  const values=[text(req.body.title,1,120),text(req.body.description||'',0,2000),id(req.body.categoryId),thumbnail(req.body.thumbnailUrl)];
  if(req.aborted)throw fail(499,'Upload canceled.');
  const name=randomUUID()+'.mp4';stored=path.join(media,name);await rename(req.file.path,stored);
  conn=await pool.getConnection();await conn.beginTransaction();
  const [rows]=await conn.execute('SELECT file_name FROM videos WHERE id=? FOR UPDATE',[id(req.params.id)]);
  if(!rows.length)throw fail(404,'Video no longer exists.');oldFile=rows[0].file_name;
  await conn.execute('UPDATE videos SET title=?,description=?,category_id=?,thumbnail_url=?,file_name=?,original_name=?,size_bytes=? WHERE id=?',[...values,name,req.file.originalname.slice(0,255),req.file.size,id(req.params.id)]);
  const [result]=await conn.execute(select+' WHERE v.id=?',[req.params.id]);
  if(req.aborted)throw fail(499,'Upload canceled.');
  await conn.commit();committed=true;stored=null;
  await safeDelete(path.join(media,oldFile));
  res.json({data:dto(result[0])});
 }catch(e){if(conn&&!committed)await conn.rollback();if(stored)await safeDelete(stored);next(e);}
 finally{if(conn)conn.release();if(req.file)await safeDelete(req.file.path);}
});
app.put('/api/v1/videos/:id',auth,async(req,res)=>{const v=await findVideo(req.params.id);if(String(v.owner_id)!==req.userId)throw fail(403,'Permission denied.');if('videoUrl' in req.body||'file_name' in req.body)throw fail(422,'Media URLs cannot be submitted.');await pool.execute('UPDATE videos SET title=?,description=?,category_id=?,thumbnail_url=? WHERE id=?',[text(req.body.title,1,120),text(req.body.description||'',0,2000),id(req.body.categoryId),thumbnail(req.body.thumbnailUrl),v.id]);res.json({data:dto(await findVideo(v.id))});});
app.delete('/api/v1/videos/:id',auth,async(req,res)=>{const v=await findVideo(req.params.id);if(String(v.owner_id)!==req.userId)throw fail(403,'Permission denied.');await pool.execute('DELETE FROM videos WHERE id=?',[v.id]);await safeDelete(path.join(media,v.file_name));res.sendStatus(204);});

const channelDto=c=>({id:String(c.id),ownerId:String(c.owner_id),name:c.name,description:c.description,avatarUrl:c.avatar_url});
app.get('/api/v1/me/channel',auth,async(req,res)=>{const [r]=await pool.execute('SELECT * FROM channels WHERE owner_id=?',[req.userId]);if(!r.length)throw fail(404,'Channel not found.');res.json({data:channelDto(r[0])});});
app.put('/api/v1/me/channel',auth,async(req,res)=>{await pool.execute('UPDATE channels SET name=?,description=?,avatar_url=? WHERE owner_id=?',[text(req.body.name,2,80),text(req.body.description||'',0,1000),thumbnail(req.body.avatarUrl),req.userId]);const [r]=await pool.execute('SELECT * FROM channels WHERE owner_id=?',[req.userId]);if(!r.length)throw fail(404,'Channel not found.');res.json({data:channelDto(r[0])});});
app.get('/api/v1/channels/:id',async(req,res)=>{const [r]=await pool.execute('SELECT * FROM channels WHERE id=?',[id(req.params.id)]);if(!r.length)throw fail(404,'Channel not found.');res.json({data:channelDto(r[0])});});
app.get('/api/v1/channels/:id/videos',async(req,res)=>{const [rows]=await pool.execute(select+' WHERE v.channel_id=? ORDER BY v.created_at DESC,v.id DESC',[id(req.params.id)]);res.json({data:rows.map(dto)});});
const commentSelect='SELECT c.*,u.display_name FROM comments c JOIN users u ON u.id=c.user_id';
const commentDto=c=>({id:String(c.id),videoId:String(c.video_id),content:c.content,createdAt:c.created_at,author:{id:String(c.user_id),displayName:c.display_name}});
app.get('/api/v1/videos/:id/comments',async(req,res)=>{await findVideo(req.params.id);const [rows]=await pool.execute(commentSelect+' WHERE c.video_id=? ORDER BY c.created_at DESC,c.id DESC',[id(req.params.id)]);res.json({data:rows.map(commentDto)});});
app.post('/api/v1/videos/:id/comments',auth,async(req,res)=>{await findVideo(req.params.id);const [r]=await pool.execute('INSERT INTO comments(user_id,video_id,content) VALUES(?,?,?)',[req.userId,id(req.params.id),text(req.body.content,1,500)]);const [rows]=await pool.execute(commentSelect+' WHERE c.id=?',[String(r.insertId)]);res.status(201).json({data:commentDto(rows[0])});});
app.delete('/api/v1/comments/:id',auth,async(req,res)=>{const [r]=await pool.execute('SELECT user_id FROM comments WHERE id=?',[id(req.params.id)]);if(!r.length)return res.sendStatus(204);if(String(r[0].user_id)!==req.userId)throw fail(403,'Only the author can delete this comment.');await pool.execute('DELETE FROM comments WHERE id=?',[req.params.id]);res.sendStatus(204);});
app.put('/api/v1/me/history/:id',auth,async(req,res)=>{await findVideo(req.params.id);await pool.execute('INSERT INTO watch_history(user_id,video_id,last_watched_at) VALUES(?,?,UTC_TIMESTAMP(3)) ON DUPLICATE KEY UPDATE last_watched_at=UTC_TIMESTAMP(3)',[req.userId,id(req.params.id)]);res.sendStatus(204);});
app.get('/api/v1/me/history',auth,async(req,res)=>{const page=Math.max(1,Number(req.query.page)||1);const [count]=await pool.execute('SELECT COUNT(*) AS total FROM watch_history WHERE user_id=?',[req.userId]);const [rows]=await pool.query(select+' JOIN watch_history h ON h.video_id=v.id WHERE h.user_id=? ORDER BY h.last_watched_at DESC,v.id DESC LIMIT 20 OFFSET ?',[req.userId,(page-1)*20]);const [times]=await pool.execute('SELECT video_id,last_watched_at FROM watch_history WHERE user_id=?',[req.userId]);const dates=new Map(times.map(h=>[String(h.video_id),h.last_watched_at]));res.json({data:rows.map(v=>({video:dto(v),lastWatchedAt:dates.get(String(v.id))})),meta:{total:Number(count[0].total),page,pageSize:20}});});
app.delete('/api/v1/me/history/:id',auth,async(req,res)=>{await pool.execute('DELETE FROM watch_history WHERE user_id=? AND video_id=?',[req.userId,id(req.params.id)]);res.sendStatus(204);});
app.delete('/api/v1/me/history',auth,async(req,res)=>{await pool.execute('DELETE FROM watch_history WHERE user_id=?',[req.userId]);res.sendStatus(204);});
app.use((err,req,res,next)=>{if(req.file)safeDelete(req.file.path);const status=err.code==='LIMIT_FILE_SIZE'?413:err.code==='ER_DUP_ENTRY'?409:err.code==='ER_NO_REFERENCED_ROW_2'?422:err instanceof multer.MulterError?400:err.status||500;res.status(status).json({error:{code:err.code||'REQUEST_FAILED',message:status===500?'Unable to complete request.':status===413?'Video exceeds the size limit.':status===409?'Record already exists.':status===422&&err.code==='ER_NO_REFERENCED_ROW_2'?'Invalid category.':err.message}});});
const server=app.listen(Number(process.env.PORT||3000),'127.0.0.1',()=>console.log('MiniTube API listening on localhost:'+ (process.env.PORT||3000)));
process.on('SIGINT',()=>server.close(async()=>{await pool.end();process.exit(0);}));
