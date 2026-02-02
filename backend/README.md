# Enterprise Productivity Backend

This repository contains a production-ready backend scaffold for an AI-powered Attendance/Productivity/Chat/Timesheet system built with NestJS and Prisma.

Quick start (local with Docker):

1. Copy `.env.example` to `.env` and adjust secrets.
2. Start services:

```bash
docker-compose up --build
```

3. In the backend container, run migrations:

```bash
npm run prisma:generate
npm run prisma:migrate
```

API base: `http://localhost:3000/api/v1`

Notes:
- All timestamps are server-generated.
- JWT secrets must be rotated for production.
- This scaffold includes Prisma schema and core modules (Auth, Attendance, Chat). Other modules include placeholders to be implemented.
