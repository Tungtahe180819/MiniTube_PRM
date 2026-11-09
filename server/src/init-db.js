import {readFile} from 'node:fs/promises';
import {pool} from './db.js';
try {const sql=await readFile(new URL('../db/schema.sql',import.meta.url),'utf8');for(const statement of sql.split(';').map(s=>s.trim()).filter(Boolean)) await pool.query(statement);const [columns]=await pool.query("SHOW COLUMNS FROM videos LIKE 'thumbnail_url'");if(!columns.length)await pool.query('ALTER TABLE videos ADD COLUMN thumbnail_url VARCHAR(2048) NULL');console.log('Schema and categories initialized.');} finally {await pool.end();}
