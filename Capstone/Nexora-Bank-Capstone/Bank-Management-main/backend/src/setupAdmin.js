import 'dotenv/config';
import bcrypt from 'bcryptjs';
import pool from './db.js';

const name = process.env.ADMIN_NAME || 'Nexora Administrator';
const email = (process.env.ADMIN_EMAIL || 'admin44@gmail.com').trim().toLowerCase();
const password = process.env.ADMIN_PASSWORD || 'admin444';

try {
  await pool.query(`CREATE TABLE IF NOT EXISTS users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('admin','employee') NOT NULL DEFAULT 'employee',
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  )`);

  if (password.length < 8) {
    throw new Error('ADMIN_PASSWORD must contain at least 8 characters.');
  }

  const hash = await bcrypt.hash(password, 12);
  await pool.execute(
    "INSERT INTO users(full_name,email,password_hash,role,is_active) VALUES(?,?,?,'admin',1) ON DUPLICATE KEY UPDATE full_name=VALUES(full_name),password_hash=VALUES(password_hash),role='admin',is_active=1",
    [name, email, hash]
  );

  console.log(`Admin account is ready: ${email}`);
} catch (error) {
  console.error('Admin setup failed:', error.message);
  process.exitCode = 1;
} finally {
  await pool.end();
}
