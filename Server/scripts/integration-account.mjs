import assert from 'node:assert/strict';
import {randomInt} from 'node:crypto';
import {pool} from '../src/db.js';
const base=process.env.TEST_API_URL||'http://127.0.0.1:3000/api/v1';
let userId;
const email=`account-${Date.now()}@minitube.test`;
const phone='+84'+randomInt(900000000,999999999);
async function request(method,path,body,token){
 const response=await fetch(base+path,{method,headers:{'Content-Type':'application/json',...(token?{Authorization:'Bearer '+token}:{})},...(body?{body:JSON.stringify(body)}:{})});
 return [response.status,response.status===204?null:await response.json()];
}
async function ageCodes(){await pool.execute('UPDATE account_otps SET created_at=DATE_ADD(UTC_TIMESTAMP(3),INTERVAL 7 HOUR),expires_at=DATE_ADD(UTC_TIMESTAMP(3),INTERVAL 239 SECOND) WHERE user_id=?',[userId]);}
try{
 let [status,result]=await request('POST','/auth/register',{displayName:'Account Test',email,password:'Original1234'});assert.equal(status,201);userId=result.data.user.id;const token=result.data.token;
 const [,other]=await request('POST','/auth/login',{email,password:'Original1234'});const otherToken=other.data.token;
 assert.equal((await request('PUT','/me',{displayName:'Valid name',dateOfBirth:'2026-02-30'},token))[0],422);
 [status,result]=await request('PUT','/me',{displayName:'Updated name',phoneNumber:phone,dateOfBirth:'2003-08-18',gender:'male',bio:'Saved bio',avatarUrl:'https://example.com/avatar.png'},token);
 assert.equal(status,200);assert.equal(result.data.bio,'Saved bio');assert.equal(result.data.phoneVerified,false);
 const [,profile]=await request('GET','/me',null,token);assert.equal(profile.data.dateOfBirth,'2003-08-18');assert.equal(profile.data.phoneNumber,phone);
 let [,otp]=await request('POST','/me/phone/request',{phoneNumber:phone},token);assert.equal(otp.data.delivery,'development');
 const [cooldownStatus,cooldown]=await request('POST','/me/phone/request',{phoneNumber:phone},token);assert.equal(cooldownStatus,429);assert.ok(cooldown.error.retryAfter>0&&cooldown.error.retryAfter<=60);
 const [clock]=await pool.execute('SELECT ABS(TIMESTAMPDIFF(SECOND,created_at,UTC_TIMESTAMP(3))) AS drift FROM account_otps WHERE id=?',[otp.data.challengeId]);assert.ok(Number(clock[0].drift)<=2);
 const wrong=otp.data.developmentCode==='111111'?'222222':'111111';
 assert.equal((await request('POST','/me/phone/verify',{challengeId:otp.data.challengeId,code:wrong},token))[0],422);
 [status,result]=await request('POST','/me/phone/verify',{challengeId:otp.data.challengeId,code:otp.data.developmentCode},token);assert.equal(status,200);assert.equal(result.data.phoneVerified,true);
 assert.equal((await request('POST','/me/phone/verify',{challengeId:otp.data.challengeId,code:otp.data.developmentCode},token))[0],422);
 await ageCodes();
 [,otp]=await request('POST','/auth/forgot-password',{phoneNumber:phone});
 const reset={challengeId:otp.data.challengeId,code:otp.data.developmentCode,newPassword:'ResetPass1234'};
 assert.equal((await request('POST','/auth/reset-password',reset))[0],204);
 assert.equal((await request('POST','/auth/reset-password',reset))[0],422);
 assert.equal((await request('GET','/me',null,token))[0],401);assert.equal((await request('GET','/me',null,otherToken))[0],401);
 assert.equal((await request('POST','/auth/login',{email,password:'Original1234'}))[0],401);
 const [,newLogin]=await request('POST','/auth/login',{email,password:'ResetPass1234'});const newToken=newLogin.data.token;
 assert.equal((await request('POST','/auth/change-password',{currentPassword:'Wrong1234',newPassword:'FinalPass1234'},newToken))[0],401);
 assert.equal((await request('POST','/auth/change-password',{currentPassword:'ResetPass1234',newPassword:'FinalPass1234'},newToken))[0],204);
 assert.equal((await request('GET','/me',null,newToken))[0],401);
 const [,finalLogin]=await request('POST','/auth/login',{email,password:'FinalPass1234'});const finalToken=finalLogin.data.token;
 [,otp]=await request('POST','/auth/forgot-password',{phoneNumber:phone});
 await pool.execute('UPDATE account_otps SET expires_at=DATE_SUB(UTC_TIMESTAMP(3),INTERVAL 1 SECOND) WHERE id=?',[otp.data.challengeId]);
 assert.equal((await request('POST','/auth/reset-password',{challengeId:otp.data.challengeId,code:otp.data.developmentCode,newPassword:'Expired1234'}))[0],422);
 await ageCodes();
 [,otp]=await request('POST','/auth/forgot-password',{phoneNumber:phone});
 for(let i=0;i<5;i++)assert.equal((await request('POST','/auth/reset-password',{challengeId:otp.data.challengeId,code:otp.data.developmentCode==='111111'?'222222':'111111',newPassword:'Blocked1234'}))[0],422);
 assert.equal((await request('POST','/auth/reset-password',{challengeId:otp.data.challengeId,code:otp.data.developmentCode,newPassword:'Blocked1234'}))[0],422);
 [status,result]=await request('PUT','/me',{displayName:'Updated name',phoneNumber:'+84'+randomInt(800000000,899999999)},finalToken);assert.equal(status,200);assert.equal(result.data.phoneVerified,false);
 const [googleStatus]=await request('POST','/auth/google',{idToken:'fake-token'});assert.ok([401,503].includes(googleStatus));
 console.log('PASS profile persistence, phone verification, resend cooldown, reset/change password, session revocation, expired/replayed/locked OTPs, changed-phone invalidation and untrusted Google credentials.');
}finally{
 if(userId){await pool.execute('DELETE FROM account_otps WHERE user_id=?',[userId]);await pool.execute('DELETE FROM auth_sessions WHERE user_id=?',[userId]);await pool.execute('DELETE FROM channels WHERE owner_id=?',[userId]);await pool.execute('DELETE FROM users WHERE id=?',[userId]);}
 await pool.end();
}
