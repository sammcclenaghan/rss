# Mercury Parser extraction sidecar. Build context is this directory:
#   docker build -t rss-extract ./extract
FROM node:22-slim

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm install --omit=dev && npm cache clean --force

COPY server.js ./

ENV NODE_ENV="production"
EXPOSE 3000
CMD ["node", "server.js"]
