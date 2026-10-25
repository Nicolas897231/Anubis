import { PGlite } from "@electric-sql/pglite";
import { readFile, readdir } from "node:fs/promises";

// Isolated PostgreSQL WASM database, never a URL or a deployed database.
// This shim models the DB contract of Supabase Auth, NOT JWT verification.
export async function createDatabase() {
  const db = new PGlite();
  await db.exec(`
    create role anon nologin;
    create role authenticated nologin;
    create schema auth;
    create schema storage;
    create table storage.buckets (
      id text primary key, name text not null, public boolean not null default false
    );
    create table storage.objects (
      id uuid primary key default gen_random_uuid(), bucket_id text not null,
      name text not null, owner_id uuid, unique (bucket_id, name)
    );
    alter table storage.objects enable row level security;
    create table auth.users (
      id uuid primary key, email text unique, email_confirmed_at timestamptz,
      raw_user_meta_data jsonb not null default '{}'
    );
    create function auth.jwt() returns jsonb language sql stable as
      $$ select coalesce(nullif(current_setting('request.jwt.claims',true),'')::jsonb,'{}'::jsonb) $$;
    create function auth.uid() returns uuid language sql stable as
      $$ select (auth.jwt()->>'sub')::uuid $$;
    grant usage on schema public,auth,storage to authenticated,anon;
    grant select,insert,delete on storage.buckets,storage.objects to authenticated,anon;
    grant execute on function auth.jwt(),auth.uid() to authenticated,anon;
  `);
  const directory = new URL("../supabase/migrations/", import.meta.url);
  const files = (await readdir(directory))
    .filter((file) => file.endsWith(".sql"))
    .sort();
  for (const file of files) {
    try {
      await db.exec(await readFile(new URL(file, directory), "utf8"));
    } catch (error) {
      await db.close();
      throw new Error(`Migration ${file}: ${error.message}`);
    }
  }
  return db;
}

export async function asUser(db, user, operation, aal = "aal2") {
  await db.query("select set_config('request.jwt.claims',$1,false)", [
    JSON.stringify({ sub: user, aal, role: "authenticated" }),
  ]);
  await db.exec("set role authenticated");
  try {
    return await operation();
  } finally {
    await db.exec("reset role");
    await db.query("select set_config('request.jwt.claims','{}',false)");
  }
}

export async function rpc(db, name, args = []) {
  if (!/^[a-z_]+$/.test(name)) throw new Error("Invalid fixture RPC");
  const result = await db.query(
    `select public.${name}(${args.map((_, i) => `$${i + 1}`).join(",")}) as value`,
    args,
  );
  return result.rows[0].value;
}
