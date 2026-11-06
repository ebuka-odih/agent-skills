#!/usr/bin/env bash
set -euo pipefail
mkdir -p web/src/pages .github/workflows
echo '{"name":"web","private":true,"scripts":{"build":"vite build","preview":"vite preview --port 4173"},"dependencies":{"react":"^19","react-router-dom":"^7"},"devDependencies":{"vite":"^6"}}' > web/package.json
cat > web/src/routes.tsx <<'R'
// public routes
export const routes = [
  { path: "/", page: "Home" },
  { path: "/:city", page: "City" },
  { path: "/:city/:category", page: "CategoryList" },
  { path: "/place/:slug", page: "Place" },
];
R
echo '@custom-variant dark (&:where(.dark, .dark *));' > web/src/index.css
printf 'name: deploy\non: { push: { branches: [main] } }\njobs: { deploy: { runs-on: ubuntu-latest, steps: [ { run: echo deploy } ] } }\n' > .github/workflows/deploy.yml
echo "Production: https://www.example.city" > README.md
