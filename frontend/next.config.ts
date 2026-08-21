import type { NextConfig } from "next";

// The dev server binds to port 3000 inside the container, but
// docker-compose publishes it to the host as ${FRONTEND_PORT:-3000}
// (configurable, see .env.example). Next.js 15.3+'s dev-server
// cross-origin protection compares the browser's Origin header against
// what it thinks its own origin is, so when those ports differ (e.g.
// FRONTEND_PORT=3005), requests get rejected with 403 unless the actual
// published origin is allow-listed here.
const devOrigins = [`localhost:${process.env.FRONTEND_PORT ?? "3000"}`, "localhost:3000"];

const nextConfig: NextConfig = {
  output: "standalone",
  allowedDevOrigins: devOrigins,
};

export default nextConfig;
