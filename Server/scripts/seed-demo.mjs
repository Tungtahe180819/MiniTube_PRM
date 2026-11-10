import { constants } from 'node:fs';
import { copyFile, mkdir, readFile, unlink } from 'node:fs/promises';
import { randomBytes, scryptSync, timingSafeEqual, createHash } from 'node:crypto';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { pool } from '../src/db.js';
import { validateMp4 } from '../src/media.js';

const serverRoot = fileURLToPath(new URL('../', import.meta.url));
const fixture = path.join(serverRoot, 'db/fixtures/demo.mp4');
const mediaRoot = path.join(serverRoot, 'storage/videos');
const accounts = [
  { email: 'demo@minitube.test', password: 'Demo1234', name: 'Demo Creator', channel: 'MiniTube Learning' },
  { email: 'studio@minitube.test', password: 'Studio1234', name: 'Studio Creator', channel: 'MiniTube Studio' },
];
const videos = [
  { key: 'learning', title: 'Welcome to MiniTube', category: 'Learning', owner: 0 },
  { key: 'creative', title: 'Creative video demo', category: 'Creative', owner: 1 },
  { key: 'nature', title: 'Nature category demo', category: 'Nature', owner: 0 },
];

function matchesPassword(password, encoded) {
  const [salt, hash] = String(encoded).split(':');
  if (!salt || !/^[a-f0-9]{128}$/.test(hash || '')) return false;
  return timingSafeEqual(Buffer.from(hash, 'hex'), scryptSync(password, salt, 64));
}

export async function seedDemo() {
  if (!await validateMp4(fixture)) throw new Error('Missing or invalid db/fixtures/demo.mp4. Restore it from Git.');
  const fixtureBytes = await readFile(fixture);
  await mkdir(mediaRoot, { recursive: true });
  const connection = await pool.getConnection();
  const createdFiles = [];
  let committed = false;
  let locked = false;
  try {
    const lockName = 'minitube-seed-' + createHash('sha256').update(process.env.DB_NAME || 'minitube').digest('hex').slice(0, 32);
    const [lock] = await connection.execute('SELECT GET_LOCK(?, 10) AS acquired', [lockName]);
    if (Number(lock[0].acquired) !== 1) throw new Error('Another seed is running. Try again later.');
    locked = lockName;
    await connection.beginTransaction();
    const users = [];
    for (const account of accounts) {
      const [existing] = await connection.execute('SELECT id,password_hash FROM users WHERE email=?', [account.email]);
      let userId;
      if (existing.length) {
        if (!matchesPassword(account.password, existing[0].password_hash)) {
          throw new Error(`Demo email already belongs to an account with a different password: ${account.email}. No account was overwritten.`);
        }
        userId = String(existing[0].id);
      } else {
        const salt = randomBytes(16).toString('hex');
        const hash = salt + ':' + scryptSync(account.password, salt, 64).toString('hex');
        const [result] = await connection.execute('INSERT INTO users(email,display_name,password_hash) VALUES(?,?,?)', [account.email, account.name, hash]);
        userId = String(result.insertId);
      }
      let [channels] = await connection.execute('SELECT id FROM channels WHERE owner_id=?', [userId]);
      if (!channels.length) {
        const [result] = await connection.execute('INSERT INTO channels(owner_id,name,description) VALUES(?,?,?)', [userId, account.channel, 'Local demo channel for the MiniTube team.']);
        channels = [{ id: result.insertId }];
      }
      users.push({ userId, channelId: String(channels[0].id) });
    }
    const videoIds = [];
    for (const video of videos) {
      const fileName = `minitube-seed-${video.key}-v1.mp4`;
      const destination = path.join(mediaRoot, fileName);
      try {
        await copyFile(fixture, destination, constants.COPYFILE_EXCL);
        createdFiles.push(destination);
      } catch (error) {
        if (error.code !== 'EEXIST') throw error;
        if (!(await readFile(destination)).equals(fixtureBytes)) {
          throw new Error(`Existing demo media differs: ${fileName}. It was not overwritten.`);
        }
      }
      const [existing] = await connection.execute('SELECT id,channel_id FROM videos WHERE file_name=?', [fileName]);
      let videoId;
      if (existing.length) {
        if (String(existing[0].channel_id) !== users[video.owner].channelId) throw new Error('Demo video belongs to another channel. No data was overwritten.');
        videoId = String(existing[0].id);
      } else {
        const [categories] = await connection.execute('SELECT id FROM categories WHERE name=?', [video.category]);
        if (!categories.length) throw new Error('Run npm run db:init before seeding.');
        const [result] = await connection.execute(
          'INSERT INTO videos(channel_id,category_id,title,description,file_name,original_name,size_bytes) VALUES(?,?,?,?,?,?,?)',
          [users[video.owner].channelId, categories[0].id, video.title,
            'Generated 4-second test pattern with a tone. This is demo content, not personal media.',
            fileName, 'demo.mp4', fixtureBytes.length],
        );
        videoId = String(result.insertId);
      }
      videoIds.push(videoId);
    }
    for (let index = 0; index < videoIds.length; index++) {
      const author = users[index % users.length].userId;
      const content = 'Demo comment: try playback, seeking and author-only deletion.';
      const [existing] = await connection.execute('SELECT id FROM comments WHERE user_id=? AND video_id=? AND content=?', [author, videoIds[index], content]);
      if (!existing.length) await connection.execute('INSERT INTO comments(user_id,video_id,content) VALUES(?,?,?)', [author, videoIds[index], content]);
    }
    for (const user of users) {
      await connection.execute('INSERT IGNORE INTO watch_history(user_id,video_id,last_watched_at) VALUES(?,?,UTC_TIMESTAMP(3))', [user.userId, videoIds[0]]);
    }
    await connection.commit();
    committed = true;
    console.log('Demo ready: 2 accounts/channels, 3 videos, 3 comments, 2 example history entries.');
    console.log('Login: demo@minitube.test / Demo1234 or studio@minitube.test / Studio1234');
    console.log('Existing accounts and edited records are preserved. History examples are seeded, not evidence of actual playback.');
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    if (!committed) for (const file of createdFiles) await unlink(file).catch(() => {});
    try {
      if (locked) await connection.execute('SELECT RELEASE_LOCK(?)', [locked]);
    } finally {
      connection.release();
    }
  }
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    await seedDemo();
  } catch (error) {
    console.error('Demo seed failed:', error.code || error.message);
    process.exitCode = 1;
  } finally {
    await pool.end();
  }
}
