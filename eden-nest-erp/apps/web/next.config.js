/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  transpilePackages: ["@eden/ui", "@eden/domain", "@eden/api"],
  experimental: {
    typedRoutes: true,
  },
};

module.exports = nextConfig;
