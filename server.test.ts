import { test, before, after } from "node:test";
import assert from "node:assert/strict";
import type { AddressInfo } from "node:net";
import { app } from "./app.ts";

let baseUrl = "";
const server = app.listen(0);

before(async () => {
  await new Promise((resolve) => server.once("listening", resolve));
  const { port } = server.address() as AddressInfo;
  baseUrl = `http://localhost:${port}`;
});

after(() => {
  server.close();
});

test("GET /health returns 200 with ok status", async () => {
  const res = await fetch(`${baseUrl}/health`);
  assert.equal(res.status, 200);
  const body = await res.json();
  assert.deepEqual(body, { status: "ok" });
});

test("GET /api/status/:orderNumber returns status for a valid order number", async () => {
  const res = await fetch(`${baseUrl}/api/status/1234567`);
  assert.equal(res.status, 200);
  const body = await res.json();
  assert.equal(body.orderNumber, "1234567");
  assert.equal(typeof body.status, "string");
  assert.match(body.estimatedDelivery, /^\d{4}-\d{2}-\d{2}$/);
});

test("GET /api/status/:orderNumber is deterministic for the same order number", async () => {
  const first = await (await fetch(`${baseUrl}/api/status/9876543210`)).json();
  const second = await (await fetch(`${baseUrl}/api/status/9876543210`)).json();
  assert.deepEqual(first, second);
});

test("GET /api/status/:orderNumber rejects an order number that is too short", async () => {
  const res = await fetch(`${baseUrl}/api/status/12345`);
  assert.equal(res.status, 400);
  const body = await res.json();
  assert.match(body.error, /6 to 10 digits/);
});

test("GET /api/status/:orderNumber rejects an order number that is too long", async () => {
  const res = await fetch(`${baseUrl}/api/status/12345678901`);
  assert.equal(res.status, 400);
});

test("GET /api/status/:orderNumber rejects non-digit input", async () => {
  const res = await fetch(`${baseUrl}/api/status/abc1234`);
  assert.equal(res.status, 400);
});

test("GET / serves the HTML page", async () => {
  const res = await fetch(`${baseUrl}/`);
  assert.equal(res.status, 200);
  assert.match(res.headers.get("content-type") ?? "", /text\/html/);
});
