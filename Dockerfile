FROM node:24-slim

ENV NODE_ENV=production

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci --omit=dev

COPY --chown=node:node app.ts server.ts status.ts ./
COPY --chown=node:node public ./public

USER node

EXPOSE 3000

CMD ["node", "server.ts"]
