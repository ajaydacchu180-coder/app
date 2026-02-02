import { Injectable, CanActivate, ExecutionContext, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';

@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(private readonly jwtService: JwtService) {}

  canActivate(context: ExecutionContext): boolean {
    const req = context.switchToHttp().getRequest();
    const auth = req.headers['authorization'] as string | undefined;
    if (!auth || !auth.startsWith('Bearer ')) throw new UnauthorizedException();
    const token = auth.replace('Bearer ', '').trim();
    try {
      const payload = this.jwtService.verify(token, { secret: process.env.JWT_ACCESS_SECRET || 'dev_access_secret' });
      req.user = { id: payload.sub, role: payload.role || payload?.role || payload?.r };
      return true;
    } catch (e) {
      throw new UnauthorizedException();
    }
  }
}
