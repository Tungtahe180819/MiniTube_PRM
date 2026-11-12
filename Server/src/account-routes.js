import { randomBytes, randomInt, scryptSync, createHash, timingSafeEqual } from 'node:crypto';
import { rateLimit } from 'express-rate-limit';
import { initializeApp, getApps } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';

const fail = (status, message) => Object.assign(new Error(message), { status });
const digest = value => createHash('sha256').update(value).digest('hex');
export function passwordHash(value) {
  if (typeof value !== 'string' || value.length < 8 || value.length > 64 || !/[a-z]/i.test(value) || !/[0-9]/.test(value)) throw fail(422, 'Use 8–64 characters with letters and numbers.');
  const salt = randomBytes(16).toString('hex');
  return salt + ':' + scryptSync(value, salt, 64).toString('hex');
}
export function passwordMatches(value, encoded) {
  if (typeof value !== 'string' || value.length > 64) return false;
  const [salt, hash] = String(encoded).split(':');
  return !!salt && /^[a-f0-9]{128}$/.test(hash || '') && timingSafeEqual(Buffer.from(hash, 'hex'), scryptSync(value, salt, 64));
}
export function normalizePhone(value) {
  if (value == null) return null;
  if (typeof value !== 'string') throw fail(422, 'Invalid phone number.');
  if (value.trim() === '') return null;
  let phone = value.replace(/[\s()-]/g, '');
  if (/^0[0-9]{9}$/.test(phone)) phone = '+84' + phone.slice(1);
  if (!/^\+[1-9][0-9]{7,14}$/.test(phone)) throw fail(422, 'Use a valid international phone number, e.g. +84901234567.');
  return phone;
}
export function profileFields(body) {
  const name = typeof body.displayName === 'string' ? body.displayName.trim() : '';
  if (name.length < 2 || name.length > 50) throw fail(422, 'Display name must have 2–50 characters.');
  const bio = typeof body.bio === 'string' ? body.bio.trim() : '';
  if (bio.length > 500) throw fail(422, 'Bio is limited to 500 characters.');
  const gender = body.gender || null;
  if (gender && !['male', 'female', 'other', 'prefer_not_to_say'].includes(gender)) throw fail(422, 'Invalid gender.');
  const birth = body.dateOfBirth || null;
  if (birth) {
    const date = new Date(birth + 'T00:00:00Z');
    if (!/^\d{4}-\d{2}-\d{2}$/.test(birth) || !Number.isFinite(date.getTime()) || date.toISOString().slice(0, 10) !== birth || birth > new Date().toISOString().slice(0, 10) || birth < '1900-01-01') throw fail(422, 'Choose a valid birthday from 1900 to today.');
  }
  if (body.avatarUrl != null && typeof body.avatarUrl !== 'string') throw fail(422, 'Invalid avatar URL.');
  const avatar = body.avatarUrl?.trim() || null;
  if (avatar) {
    let url; try { url = new URL(avatar); } catch { throw fail(422, 'Avatar must be an HTTPS image URL.'); }
    if (avatar.length > 2048 || url.protocol !== 'https:' || url.username || url.password) throw fail(422, 'Avatar must be an HTTPS image URL.');
  }
  return { name, bio, gender, birth, avatar, phone: normalizePhone(body.phoneNumber) };
}
export const userDto = r => ({
  id: String(r.id), email: r.email, displayName: r.display_name,
  avatarUrl: r.avatar_url || null, phoneNumber: r.phone_number || null,
  phoneVerified: !!r.phone_verified_at,
  dateOfBirth: r.date_of_birth ? (typeof r.date_of_birth === 'string' ? r.date_of_birth.slice(0, 10) : r.date_of_birth.toISOString().slice(0, 10)) : null,
  gender: r.gender || null, bio: r.bio || '', hasPassword: r.has_password !== 0,
  googleLinked: !!r.google_uid,
});
const development = () => process.env.AUTH_DEV_MODE === 'true' && process.env.NODE_ENV !== 'production';

export function registerAccountRoutes(app, { pool, auth, session }) {
  const sensitive = rateLimit({ windowMs: 15 * 60 * 1000, limit: 30, standardHeaders: 'draft-8', legacyHeaders: false, message: { error: { message: 'Too many attempts. Try again in 15 minutes.' } } });
  app.use('/api/v1/auth/login', sensitive);
  app.get('/api/v1/auth/config', (req, res) => res.json({ data: { developmentOtp: development(), googleEnabled: !!process.env.FIREBASE_PROJECT_ID } }));
  app.put('/api/v1/me', auth, async (req, res) => {
    const [existing] = await pool.execute('SELECT * FROM users WHERE id=?', [req.userId]);
    const old = userDto(existing[0]);
    const fields = profileFields({ ...old, ...req.body });
    const c = await pool.getConnection();
    try {
      await c.beginTransaction();
      await c.execute('UPDATE users SET display_name=?,avatar_url=?,bio=?,gender=?,date_of_birth=?,phone_verified_at=IF(phone_number <=> ?,phone_verified_at,NULL),phone_number=? WHERE id=?', [fields.name, fields.avatar, fields.bio, fields.gender, fields.birth, fields.phone, fields.phone, req.userId]);
      if (old.phoneNumber !== fields.phone) await c.execute('DELETE FROM account_otps WHERE user_id=?', [req.userId]);
      const [rows] = await c.execute('SELECT * FROM users WHERE id=?', [req.userId]);
      await c.commit(); res.json({ data: userDto(rows[0]) });
    } catch (e) { await c.rollback(); throw e; } finally { c.release(); }
  });
  app.post('/api/v1/auth/change-password', sensitive, auth, async (req, res) => {
    const encoded = passwordHash(req.body.newPassword);
    const c = await pool.getConnection();
    try {
      await c.beginTransaction();
      const [rows] = await c.execute('SELECT * FROM users WHERE id=? FOR UPDATE', [req.userId]);
      if (!rows[0].has_password || !passwordMatches(req.body.currentPassword, rows[0].password_hash)) throw fail(401, 'Current password is incorrect. Google-only accounts can reset via a verified phone.');
      if (passwordMatches(req.body.newPassword, rows[0].password_hash)) throw fail(422, 'Choose a different new password.');
      await c.execute('UPDATE users SET password_hash=? WHERE id=?', [encoded, req.userId]);
      await c.execute('DELETE FROM auth_sessions WHERE user_id=?', [req.userId]);
      await c.execute('DELETE FROM account_otps WHERE user_id=?', [req.userId]);
      await c.commit(); res.sendStatus(204);
    } catch (e) { await c.rollback(); throw e; } finally { c.release(); }
  });

  async function issueOtp(req, res, purpose) {
    // No fake SMS: explicit local-development mode only until an SMS provider is configured.
    if (!development()) throw fail(503, 'SMS delivery is not configured. Local OTP demo requires AUTH_DEV_MODE=true outside production.');
    const phone = normalizePhone(req.body.phoneNumber);
    if (!phone) throw fail(422, 'Enter your phone number.');
    const c = await pool.getConnection();
    const challenge = randomBytes(24).toString('hex');
    const code = String(randomInt(100000, 1000000));
    try {
      await c.beginTransaction();
      // Serialize requests for this phone to enforce the resend cooldown.
      const [users] = await c.execute('SELECT * FROM users WHERE phone_number=? FOR UPDATE', [phone]);
      const candidate = users[0];
      const userId = purpose === 'verify_phone'
        ? (candidate && String(candidate.id) === req.userId ? req.userId : null)
        : (candidate?.phone_verified_at ? String(candidate.id) : null);
      if (purpose === 'verify_phone' && !userId) throw fail(422, 'Save this phone number in your profile first.');
      // expires_at was always written in UTC, including older rows whose
      // created_at default used the MySQL server's local timezone.
      const [recent] = await c.execute('SELECT CEIL(TIMESTAMPDIFF(MICROSECOND,UTC_TIMESTAMP(3),DATE_SUB(expires_at,INTERVAL 4 MINUTE))/1000000) AS retry_after FROM account_otps WHERE phone_number=? AND expires_at>DATE_ADD(UTC_TIMESTAMP(3),INTERVAL 4 MINUTE) ORDER BY expires_at DESC LIMIT 1', [phone]);
      if (recent.length) {
        const retryAfter = Math.max(1, Math.min(60, Number(recent[0].retry_after)));
        throw Object.assign(fail(429, `Wait ${retryAfter} seconds before requesting another code.`), { retryAfter });
      }
      await c.execute('UPDATE account_otps SET consumed_at=UTC_TIMESTAMP(3) WHERE phone_number=? AND purpose=? AND consumed_at IS NULL', [phone, purpose]);
      await c.execute('INSERT INTO account_otps(id,user_id,phone_number,purpose,code_hash,expires_at,created_at) VALUES(?,?,?,?,?,DATE_ADD(UTC_TIMESTAMP(3),INTERVAL 5 MINUTE),UTC_TIMESTAMP(3))', [challenge, userId, phone, purpose, digest(challenge + ':' + code)]);
      await c.commit();
      res.json({ data: { challengeId: challenge, expiresIn: 300, retryAfter: 60, developmentCode: code, delivery: 'development', message: 'Development OTP only. No SMS was sent.' } });
    } catch (e) { await c.rollback(); throw e; } finally { c.release(); }
  }
  async function consumeOtp(req, res, purpose) {
    if (!development()) throw fail(503, 'SMS delivery is not configured.');
    const { challengeId, code } = req.body;
    if (typeof challengeId !== 'string' || !/^[a-f0-9]{48}$/.test(challengeId) || !/^\d{6}$/.test(String(code))) throw fail(422, 'Enter a valid six-digit code.');
    const encoded = purpose === 'reset_password' ? passwordHash(req.body.newPassword) : null;
    const c = await pool.getConnection();
    try {
      await c.beginTransaction();
      const [rows] = await c.execute('SELECT *,expires_at>UTC_TIMESTAMP(3) AS valid FROM account_otps WHERE id=? FOR UPDATE', [challengeId]);
      const otp = rows[0];
      if (!otp || otp.purpose !== purpose || otp.consumed_at || Number(otp.valid) !== 1 || otp.attempts >= 5 || (purpose === 'verify_phone' && String(otp.user_id) !== req.userId)) throw fail(422, 'Invalid or expired code. Request another code.');
      if (digest(challengeId + ':' + code) !== otp.code_hash) {
        await c.execute('UPDATE account_otps SET attempts=attempts+1 WHERE id=?', [challengeId]);
        await c.commit(); throw fail(422, 'Incorrect code. At most five attempts are allowed.');
      }
      if (!otp.user_id) throw fail(422, 'Invalid or expired code. Request another code.');
      const [users] = await c.execute('SELECT * FROM users WHERE id=? FOR UPDATE', [otp.user_id]);
      if (!users[0] || users[0].phone_number !== otp.phone_number || (purpose === 'reset_password' && !users[0].phone_verified_at)) throw fail(422, 'Phone number is no longer eligible.');
      await c.execute('UPDATE account_otps SET consumed_at=UTC_TIMESTAMP(3) WHERE id=?', [challengeId]);
      if (purpose === 'verify_phone') {
        await c.execute('UPDATE users SET phone_verified_at=UTC_TIMESTAMP(3) WHERE id=?', [otp.user_id]);
        users[0].phone_verified_at = new Date();
      } else {
        await c.execute('UPDATE users SET password_hash=?,has_password=1 WHERE id=?', [encoded, otp.user_id]);
        await c.execute('DELETE FROM auth_sessions WHERE user_id=?', [otp.user_id]);
        await c.execute('UPDATE account_otps SET consumed_at=UTC_TIMESTAMP(3) WHERE user_id=? AND consumed_at IS NULL', [otp.user_id]);
      }
      await c.commit();
      if (purpose === 'verify_phone') res.json({ data: userDto(users[0]) }); else res.sendStatus(204);
    } catch (e) { await c.rollback(); throw e; } finally { c.release(); }
  }
  app.post('/api/v1/me/phone/request', sensitive, auth, (req, res) => issueOtp(req, res, 'verify_phone'));
  app.post('/api/v1/me/phone/verify', sensitive, auth, (req, res) => consumeOtp(req, res, 'verify_phone'));
  app.post('/api/v1/auth/forgot-password', sensitive, (req, res) => issueOtp(req, res, 'reset_password'));
  app.post('/api/v1/auth/reset-password', sensitive, (req, res) => consumeOtp(req, res, 'reset_password'));

  async function googleIdentity(token) {
    if (!process.env.FIREBASE_PROJECT_ID) throw fail(503, 'Google login needs Firebase configuration. It is not configured yet.');
    if (typeof token !== 'string' || token.length > 10000) throw fail(401, 'Invalid Google credential.');
    try {
      const firebase = getApps().find(a => a.name === 'minitube-auth') || initializeApp({ projectId: process.env.FIREBASE_PROJECT_ID }, 'minitube-auth');
      const identity = await getAuth(firebase).verifyIdToken(token);
      if (identity.firebase?.sign_in_provider !== 'google.com' || !identity.email_verified || !identity.email) throw new Error('Wrong provider');
      return identity;
    } catch { throw fail(401, 'Google credential could not be verified.'); }
  }
  app.post('/api/v1/auth/google', sensitive, async (req, res) => {
    const identity = await googleIdentity(req.body.idToken);
    const c = await pool.getConnection();
    try {
      await c.beginTransaction();
      let [rows] = await c.execute('SELECT * FROM users WHERE google_uid=?', [identity.uid]);
      if (!rows.length) {
        const [sameEmail] = await c.execute('SELECT id FROM users WHERE email=?', [identity.email.toLowerCase()]);
        if (sameEmail.length) throw fail(409, 'This email already has an account. Sign in with your password and link Google from My Profile.');
        const name = String(identity.name || identity.email.split('@')[0]).slice(0, 50).padEnd(2, '_');
        const [result] = await c.execute('INSERT INTO users(email,display_name,password_hash,has_password,google_uid) VALUES(?,?,?,0,?)', [identity.email.toLowerCase(), name, passwordHash(randomBytes(32).toString('hex')), identity.uid]);
        await c.execute('INSERT INTO channels(owner_id,name) VALUES(?,?)', [result.insertId, name]);
        [rows] = await c.execute('SELECT * FROM users WHERE id=?', [result.insertId]);
      }
      const data = await session(c, rows[0].id); await c.commit();
      res.json({ data: { user: userDto(rows[0]), ...data } });
    } catch (e) { await c.rollback(); throw e; } finally { c.release(); }
  });
  app.post('/api/v1/me/google', sensitive, auth, async (req, res) => {
    const identity = await googleIdentity(req.body.idToken);
    const [users] = await pool.execute('SELECT * FROM users WHERE id=?', [req.userId]);
    if (users[0].email.toLowerCase() !== identity.email.toLowerCase()) throw fail(409, 'Link the Google account with the same email as your profile.');
    if (users[0].google_uid && users[0].google_uid !== identity.uid) throw fail(409, 'Another Google identity is already linked.');
    await pool.execute('UPDATE users SET google_uid=? WHERE id=?', [identity.uid, req.userId]);
    users[0].google_uid = identity.uid; res.json({ data: userDto(users[0]) });
  });
}
