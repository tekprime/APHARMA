import "dotenv/config";
import fs from "fs";
import path from "path";
import { pool } from "./pool.js";

async function ensureMigrationsTable(): Promise<void> {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS _migrations (
      id SERIAL PRIMARY KEY,
      filename VARCHAR(255) NOT NULL UNIQUE,
      applied_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    )
  `);
}

async function getAppliedMigrations(): Promise<Set<string>> {
  const result = await pool.query<{ filename: string }>(
    "SELECT filename FROM _migrations",
  );
  return new Set(result.rows.map((row) => row.filename));
}

async function runMigration(filename: string, sql: string): Promise<void> {
  const client = await pool.connect();

  try {
    await client.query("BEGIN");
    await client.query(sql);
    await client.query("INSERT INTO _migrations (filename) VALUES ($1)", [
      filename,
    ]);
    await client.query("COMMIT");
    console.log(`Applied migration: ${filename}`);
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  } finally {
    client.release();
  }
}

async function migrate(): Promise<void> {
  await ensureMigrationsTable();

  const migrationsDir = path.join(process.cwd(), "src", "migrations");
  const files = fs
    .readdirSync(migrationsDir)
    .filter((file) => file.endsWith(".sql"))
    .sort();

  const applied = await getAppliedMigrations();

  for (const filename of files) {
    if (applied.has(filename)) {
      console.log(`Skipped migration (already applied): ${filename}`);
      continue;
    }

    const sql = fs.readFileSync(path.join(migrationsDir, filename), "utf8");
    await runMigration(filename, sql);
  }
}

migrate()
  .catch((error) => {
    console.error("Migration failed:", error);
    process.exit(1);
  })
  .finally(async () => {
    await pool.end();
  });
