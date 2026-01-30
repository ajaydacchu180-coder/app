import { SubscribeMessage, WebSocketGateway, OnGatewayInit, WebSocketServer, OnGatewayConnection, OnGatewayDisconnect } from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { PrismaService } from '../../prisma/prisma.service';
import { JwtService } from '@nestjs/jwt';
import { Queue } from 'bullmq';
import { AI_QUEUE_NAME } from '../ai/ai.constants';

@WebSocketGateway({ cors: { origin: '*' } })
export class ChatGateway implements OnGatewayInit, OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server!: Server;
  constructor(private prisma: PrismaService, private jwt: JwtService) {}

  afterInit(server: Server) {}

  async handleConnection(client: Socket, ...args: any[]) {
    // authenticate via token param (client sends { auth: { token } })
    const token = client.handshake.auth?.token as string | undefined;
    if (!token) {
      client.disconnect(true);
      return;
    }
    try {
      const payload = this.jwt.verify(token, { secret: process.env.JWT_ACCESS_SECRET || 'dev_access_secret' }) as any;
      const userId = payload.sub as number;
      // set socket rooms for presence, etc.
      client.data.userId = userId;
      // upsert using find/create to avoid requiring unique constraint
      const existing = await this.prisma.userPresence.findFirst({ where: { userId } });
      if (existing) {
        await this.prisma.userPresence.update({ where: { id: existing.id }, data: { status: 'online', lastSeen: new Date() } });
      } else {
        await this.prisma.userPresence.create({ data: { userId, status: 'online', lastSeen: new Date() } });
      }
      // optionally enqueue a lightweight activity signal for AI scoring
      try {
        const q = new Queue(AI_QUEUE_NAME, {
          connection: {
            host: process.env.REDIS_HOST || 'localhost',
            port: parseInt(process.env.REDIS_PORT || '6379'),
          },
        });
        await q.add('activity-signal', { userId, type: 'presence_online' }, { removeOnComplete: true });
        await q.close();
      } catch (err) {
        console.error('Failed to enqueue presence signal');
      }
    } catch (e) {
      client.disconnect(true);
    }
  }

  async handleDisconnect(client: Socket) {
    const userId = client.data?.userId as number | undefined;
    if (userId) {
      await this.prisma.userPresence.updateMany({ where: { userId }, data: { status: 'offline', lastSeen: new Date() } });
    }
  }

  @SubscribeMessage('message')
  async onMessage(client: Socket, payload: any) {
    // payload: { channelId, message }
    const now = new Date();
    const fromUserId = client.data?.userId ?? payload.fromUserId ?? 0;
    await this.prisma.chatMessage.create({ data: { channelId: payload.channelId, fromUserId, message: payload.message, createdAt: now } });
    this.server.to(String(payload.channelId)).emit('message', { channelId: payload.channelId, message: payload.message, createdAt: now, fromUserId });
  }
}
