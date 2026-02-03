# ======================================================
# MONDAHA DOCS (Docusaurus) - Production Image
# Root-based project (package.json at repo root)
# Node >= 20
# ======================================================

FROM node:20-alpine AS deps
WORKDIR /app

# Copia manifests (para cache de deps)
COPY package.json package-lock.json* yarn.lock* ./

# Instala deps de forma resiliente:
# - npm ci se existir package-lock.json
# - yarn install se existir yarn.lock
# - fallback npm install
RUN if [ -f package-lock.json ]; then \
  npm ci; \
  elif [ -f yarn.lock ]; then \
  corepack enable && yarn install --frozen-lockfile; \
  else \
  npm install; \
  fi


FROM node:20-alpine AS build
WORKDIR /app

COPY --from=deps /app/node_modules /app/node_modules
COPY . .

RUN npm run build


FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production

COPY --from=build /app/build /app/build
COPY --from=build /app/node_modules /app/node_modules
COPY --from=build /app/package.json /app/package.json

# Opcional (alguns setups usam docusaurus.config.* no runtime)
# COPY --from=build /app/docusaurus.config.* /app/

EXPOSE 3000

CMD ["npm", "run", "serve", "--", "--host", "0.0.0.0", "--port", "3000"]
