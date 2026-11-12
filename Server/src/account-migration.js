export async function migrateAccounts(pool) {
  const columns = {
    avatar_url: 'VARCHAR(2048) NULL', phone_number: 'VARCHAR(16) NULL',
    phone_verified_at: 'DATETIME(3) NULL', date_of_birth: 'DATE NULL',
    gender: 'VARCHAR(24) NULL', bio: "VARCHAR(500) NOT NULL DEFAULT ''",
    google_uid: 'VARCHAR(128) NULL', has_password: 'TINYINT NOT NULL DEFAULT 1',
  };
  for (const [name, definition] of Object.entries(columns)) {
    const [rows] = await pool.query('SHOW COLUMNS FROM users LIKE ?', [name]);
    if (!rows.length) await pool.query(`ALTER TABLE users ADD COLUMN ${name} ${definition}`);
  }
  for (const [name, column] of [['uq_users_phone', 'phone_number'], ['uq_users_google', 'google_uid']]) {
    const [rows] = await pool.query('SHOW INDEX FROM users WHERE Key_name=?', [name]);
    if (!rows.length) await pool.query(`ALTER TABLE users ADD UNIQUE KEY ${name} (${column})`);
  }
}
