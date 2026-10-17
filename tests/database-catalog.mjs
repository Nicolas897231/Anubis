import { createDatabase } from "./database-harness.mjs";
const db = await createDatabase();
try {
  const tables = (
    await db.query(
      "select tablename from pg_tables where schemaname='public' order by tablename",
    )
  ).rows;
  const catalog = [];
  for (const { tablename } of tables) {
    const columns = (
      await db.query(
        "select column_name,data_type,is_nullable,column_default from information_schema.columns where table_schema='public' and table_name=$1 order by ordinal_position",
        [tablename],
      )
    ).rows;
    const constraints = (
      await db.query(
        "select c.conname,pg_get_constraintdef(c.oid) as definition from pg_constraint c join pg_class t on t.oid=c.conrelid join pg_namespace n on n.oid=t.relnamespace where n.nspname='public' and t.relname=$1 order by c.conname",
        [tablename],
      )
    ).rows;
    const indexes = (
      await db.query(
        "select indexname,indexdef from pg_indexes where schemaname='public' and tablename=$1 order by indexname",
        [tablename],
      )
    ).rows;
    catalog.push({ table: tablename, columns, constraints, indexes });
  }
  process.stdout.write(JSON.stringify(catalog));
} finally {
  await db.close();
}
