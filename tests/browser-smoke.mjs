import assert from "node:assert/strict";
import { createRequire } from "node:module";
import { mkdir } from "node:fs/promises";
import { fileURLToPath } from "node:url";

const require = createRequire(import.meta.url);
const { chromium } = require(process.env.PLAYWRIGHT_MODULE || "playwright");
const base = process.env.TEST_BASE_URL || "http://127.0.0.1:3107";
if (!["127.0.0.1", "localhost"].includes(new URL(base).hostname))
  throw new Error(
    "This smoke test is restricted to the local, unconfigured lab.",
  );
await mkdir(new URL("../artifacts/qa/", import.meta.url), { recursive: true });
const browser = await chromium.launch({ channel: "msedge", headless: true });
try {
  const errors = [];
  const context = await browser.newContext();
  const page = await context.newPage();
  page.on("pageerror", (error) => errors.push(error.message));
  const health = await context.request.get(`${base}/api/health`);
  assert.equal(health.status(), 200);
  assert.deepEqual(await health.json(), { status: "ok" });
  for (const path of [
    "/app/dashboard",
    "/app/clients",
    "/app/services",
    "/app/team",
    "/admin",
    "/onboarding",
    "/mfa",
    "/reset-password",
  ]) {
    const response = await context.request.get(`${base}${path}`, {
      maxRedirects: 0,
    });
    assert.equal(response.status(), 307, path);
    assert.ok(
      response.headers().location.endsWith("/login?state=unconfigured"),
      path,
    );
    assert.match(response.headers()["cache-control"], /no-store/);
  }
  for (const [mode, width, height] of [
    ["desktop", 1440, 1000],
    ["mobile", 390, 844],
  ]) {
    await page.setViewportSize({ width, height });
    for (const path of ["login", "register", "forgot-password"]) {
      await page.goto(`${base}/${path}`, {
        waitUntil: "domcontentloaded",
        timeout: 60000,
      });
      await page
        .getByRole("status")
        .filter({ hasText: "El acceso aun no esta habilitado" })
        .waitFor();
      await page.waitForFunction(() =>
        [...document.images].every(
          (img) => img.complete && img.naturalWidth > 0,
        ),
      );
      await page.evaluate(() => document.fonts.ready);
      assert.equal(
        await page.locator('form button[type="submit"]').isDisabled(),
        true,
      );
      assert.equal(await page.locator('a[href="/app/dashboard"]').count(), 0);
      assert.equal(
        await page.evaluate(
          () => document.documentElement.scrollWidth <= window.innerWidth,
        ),
        true,
        `${mode}/${path} overflow`,
      );
      assert.equal(
        await page
          .locator("img")
          .evaluateAll((images) =>
            images.every((img) => img.complete && img.naturalWidth > 0),
          ),
        true,
      );
      await page.screenshot({
        path: fileURLToPath(
          new URL(`../artifacts/qa/${mode}-${path}.png`, import.meta.url),
        ),
        fullPage: true,
      });
    }
  }
  for (const path of [
    "/auth/callback?code=invalid&next=https://evil.example",
    "/auth/confirm?token_hash=invalid&type=admin",
  ]) {
    const response = await context.request.get(`${base}${path}`, {
      maxRedirects: 0,
    });
    assert.equal(response.status(), 307);
    assert.equal(response.headers().location, `${base}/login?state=link`);
  }
  assert.deepEqual(errors, []);
  console.log(
    "PASS: health, 8 protected routes, callback redirects, 6 responsive screenshots, loaded brand images, no horizontal overflow, no page errors. Auth intentionally unconfigured.",
  );
} finally {
  await browser.close();
}
