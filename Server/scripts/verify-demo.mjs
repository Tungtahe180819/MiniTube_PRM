import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { pool } from '../src/db.js';
import { seedDemo } from './seed-demo.mjs';

async function counts() {
  const result = {};
  for (const table of ['users', 'channels', 'categories', 'videos', 'comments', 'watch_history']) {
    const [rows] = await pool.query(`SELECT COUNT(*) AS total FROM ${table}`);
    result[table] = String(rows[0].total);
  }
  return result;
}

try {
  await seedDemo();
  const before = await counts();
  await seedDemo();
  assert.deepEqual(await counts(), before, 'Running seed again must not duplicate data');
  const [rows] = await pool.execute('SELECT file_name,size_bytes FROM videos WHERE file_name IN (?,?,?)', [
    'minitube-seed-learning-v1.mp4', 'minitube-seed-creative-v1.mp4', 'minitube-seed-nature-v1.mp4',
  ]);
  assert.equal(rows.length, 3);
  const fixture = await readFile(new URL('../db/fixtures/demo.mp4', import.meta.url));
  for (const row of rows) {
    const media = await readFile(new URL('../storage/videos/' + row.file_name, import.meta.url));
    assert.ok(media.equals(fixture));
    assert.equal(Number(row.size_bytes), media.length);
  }
  console.log('PASS: repeatable seed, no duplicate records, all 3 media files match the fixture.');
} finally {
  await pool.end();
}
