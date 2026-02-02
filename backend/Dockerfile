FROM node:20-alpine

WORKDIR /usr/src/app

COPY package.json package-lock.json* ./
RUN npm ci --production --legacy-peer-deps || npm install --production --legacy-peer-deps

COPY prisma ./prisma
COPY src ./src
COPY tsconfig.json ./

RUN npm run prisma:generate
RUN npm run build

ENV NODE_ENV=production
EXPOSE 3000
CMD ["node", "dist/main.js"]
