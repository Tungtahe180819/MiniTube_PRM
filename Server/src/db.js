import { config } from "dotenv";
config({ path: new URL("../.env", import.meta.url), quiet: true });
import mysql from "mysql2/promise";
export const pool = mysql.createPool({
  host: process.env.DB_HOST || "127.0.0.1",
  port: Number(process.env.DB_PORT || 3306),
  user: process.env.DB_USER || "minitube",
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME || "minitube",
  timezone: "Z",
  supportBigNumbers: true,
  bigNumberStrings: true,
  connectionLimit: 5,
  dateStrings: false,
});
