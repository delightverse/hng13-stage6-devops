FROM node:18-alpine

RUN apk add --no-cache dumb-init

WORKDIR /usr/src/app

# ✅ COPY ONLY package.json (skip lockfile)
COPY package.json ./

RUN npm install --only=production && npm cache clean --force

COPY . .

RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 -G nodejs && \
    chown -R nodejs:nodejs /usr/src/app

USER nodejs

EXPOSE 8082

ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "server.js"]
