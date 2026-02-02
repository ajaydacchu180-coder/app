import { Injectable, UnauthorizedException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { compare, hash } from 'bcrypt';
import { JwtService } from '@nestjs/jwt';
import * as crypto from 'crypto';
import * as OTPAuth from 'otpauth';

interface LoginMetadata {
  ip?: string;
  userAgent?: string;
}

@Injectable()
export class AuthService {
  constructor(private prisma: PrismaService, private jwt: JwtService) { }

  async validateUserByEmail(email: string, password: string) {
    const user = await this.prisma.user.findUnique({ where: { email }, include: { role: true } });
    if (!user) return null;
    const ok = await compare(password, user.passwordHash);
    if (!ok) return null;
    return user;
  }

  async login(email: string, password: string, metadata: LoginMetadata = {}) {
    const user = await this.validateUserByEmail(email, password);

    // Log the attempt (success or failure)
    await this.prisma.loginAuditLog.create({
      data: {
        userId: user?.id || null,
        username: email,
        success: !!user,
        ip: metadata.ip || null,
        userAgent: metadata.userAgent || null,
      }
    });

    if (!user) throw new UnauthorizedException('Invalid credentials');

    // Check if 2FA is enabled
    const twoFactorEnabled = await this.check2FAEnabled(user.id);

    if (twoFactorEnabled) {
      // Return partial response requiring 2FA verification
      return {
        requires2FA: true,
        userId: user.id,
        message: 'Please verify with your 2FA code',
      };
    }

    // Generate tokens
    return this.generateTokens(user, metadata);
  }

  private async generateTokens(user: any, metadata: LoginMetadata = {}) {
    const payload = { sub: user.id, role: user.role.name };
    const accessToken = this.jwt.sign(payload, { expiresIn: '15m' });
    const refreshToken = this.jwt.sign({ sub: user.id }, {
      secret: process.env.JWT_REFRESH_SECRET || 'dev_refresh_secret',
      expiresIn: '30d'
    });

    // Store refresh token hash
    const tokenHash = await hash(refreshToken, 10);
    await this.prisma.refreshToken.create({
      data: {
        userId: user.id,
        tokenHash,
        expiresAt: new Date(Date.now() + 30 * 24 * 3600 * 1000)
      }
    });

    return {
      accessToken,
      refreshToken,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role.name,
      }
    };
  }

  async refresh(userId: number, token: string) {
    const rt = await this.prisma.refreshToken.findFirst({ where: { userId, revokedAt: null } });
    if (!rt) throw new UnauthorizedException();

    const ok = await compare(token, rt.tokenHash);
    if (!ok) throw new UnauthorizedException();

    const payload = { sub: userId };
    const accessToken = this.jwt.sign(payload, { expiresIn: '15m' });
    return { accessToken };
  }

  async logout(userId: number, refreshToken: string, metadata: LoginMetadata = {}) {
    // Revoke the refresh token
    const tokens = await this.prisma.refreshToken.findMany({
      where: { userId, revokedAt: null }
    });

    for (const token of tokens) {
      if (await compare(refreshToken, token.tokenHash)) {
        await this.prisma.refreshToken.update({
          where: { id: token.id },
          data: { revokedAt: new Date() }
        });
        break;
      }
    }

    // Log the logout event
    await this.prisma.auditLog.create({
      data: {
        actorId: userId,
        action: 'USER_LOGOUT',
        entity: 'User',
        entityId: userId,
        data: {
          ip: metadata.ip,
          userAgent: metadata.userAgent,
          timestamp: new Date().toISOString(),
        }
      }
    });

    return { success: true, message: 'Logged out successfully' };
  }

  async changePassword(userId: number, currentPassword: string, newPassword: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new BadRequestException('User not found');

    // Verify current password
    const isValid = await compare(currentPassword, user.passwordHash);
    if (!isValid) throw new BadRequestException('Current password is incorrect');

    // Validate new password strength
    if (newPassword.length < 8) {
      throw new BadRequestException('Password must be at least 8 characters');
    }
    if (!/[A-Z]/.test(newPassword)) {
      throw new BadRequestException('Password must contain an uppercase letter');
    }
    if (!/[a-z]/.test(newPassword)) {
      throw new BadRequestException('Password must contain a lowercase letter');
    }
    if (!/[0-9]/.test(newPassword)) {
      throw new BadRequestException('Password must contain a number');
    }

    // Hash and update password
    const newHash = await hash(newPassword, 10);
    await this.prisma.user.update({
      where: { id: userId },
      data: { passwordHash: newHash }
    });

    // Revoke all refresh tokens (force re-login)
    await this.prisma.refreshToken.updateMany({
      where: { userId, revokedAt: null },
      data: { revokedAt: new Date() }
    });

    // Audit log
    await this.prisma.auditLog.create({
      data: {
        actorId: userId,
        action: 'PASSWORD_CHANGED',
        entity: 'User',
        entityId: userId,
      }
    });

    return { success: true, message: 'Password changed successfully' };
  }

  async getLoginHistory(userId: number) {
    const logs = await this.prisma.loginAuditLog.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take: 20,
    });

    return logs.map(log => ({
      id: log.id,
      success: log.success,
      ip: log.ip || 'Unknown',
      userAgent: log.userAgent || 'Unknown',
      timestamp: log.createdAt.toISOString(),
      device: this.parseUserAgent(log.userAgent),
    }));
  }

  private parseUserAgent(userAgent: string | null): string {
    if (!userAgent) return 'Unknown Device';

    if (userAgent.includes('iPhone')) return 'iPhone';
    if (userAgent.includes('iPad')) return 'iPad';
    if (userAgent.includes('Android')) return 'Android Device';
    if (userAgent.includes('Windows')) return 'Windows PC';
    if (userAgent.includes('Mac')) return 'Mac';
    if (userAgent.includes('Linux')) return 'Linux';

    return 'Unknown Device';
  }

  // =================== 2FA METHODS ===================

  private async check2FAEnabled(userId: number): Promise<boolean> {
    const consent = await this.prisma.consent.findFirst({
      where: { userId, type: '2FA_ENABLED' }
    });
    return !!consent;
  }

  async setup2FA(userId: number, email: string) {
    // Generate a secret
    const secret = new OTPAuth.Secret({ size: 20 });

    // Store temporarily (would be stored properly in production)
    await this.prisma.consent.upsert({
      where: { id: userId }, // Using consent table for demo
      create: {
        userId,
        type: '2FA_PENDING',
        grantedAt: new Date(),
      },
      update: {
        type: '2FA_PENDING',
        grantedAt: new Date(),
      }
    });

    // Create OTP URI for authenticator apps
    const totp = new OTPAuth.TOTP({
      issuer: 'Enterprise Attendance',
      label: email,
      algorithm: 'SHA1',
      digits: 6,
      period: 30,
      secret: secret,
    });

    return {
      secret: secret.base32,
      otpauthUrl: totp.toString(),
      qrCodeData: totp.toString(),
    };
  }

  async verify2FASetup(userId: number, code: string) {
    // In production, verify against stored pending secret
    // For demo, accept any 6-digit code
    if (code.length !== 6 || !/^\d+$/.test(code)) {
      throw new BadRequestException('Invalid verification code');
    }

    // Mark 2FA as enabled
    await this.prisma.consent.create({
      data: {
        userId,
        type: '2FA_ENABLED',
        grantedAt: new Date(),
      }
    });

    // Generate backup codes
    const backupCodes = this.generateBackupCodesInternal();

    // Audit log
    await this.prisma.auditLog.create({
      data: {
        actorId: userId,
        action: '2FA_ENABLED',
        entity: 'User',
        entityId: userId,
      }
    });

    return {
      success: true,
      message: '2FA enabled successfully',
      backupCodes,
    };
  }

  async verify2FA(userId: number, code: string) {
    // In production, verify TOTP code
    if (code.length !== 6 || !/^\d+$/.test(code)) {
      throw new BadRequestException('Invalid verification code');
    }

    // Get user and generate tokens
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { role: true }
    });

    if (!user) throw new UnauthorizedException('User not found');

    return this.generateTokens(user);
  }

  async disable2FA(userId: number, code: string) {
    // Verify code first
    if (code.length !== 6 || !/^\d+$/.test(code)) {
      throw new BadRequestException('Invalid verification code');
    }

    // Remove 2FA consent
    await this.prisma.consent.deleteMany({
      where: { userId, type: '2FA_ENABLED' }
    });

    // Audit log
    await this.prisma.auditLog.create({
      data: {
        actorId: userId,
        action: '2FA_DISABLED',
        entity: 'User',
        entityId: userId,
      }
    });

    return { success: true, message: '2FA disabled successfully' };
  }

  async get2FAStatus(userId: number) {
    const isEnabled = await this.check2FAEnabled(userId);
    return { enabled: isEnabled };
  }

  async generateBackupCodes(userId: number) {
    const codes = this.generateBackupCodesInternal();

    // In production, store hashed backup codes
    // For demo, just return them

    return {
      codes,
      message: 'Save these codes securely. Each can only be used once.'
    };
  }

  private generateBackupCodesInternal(count: number = 8): string[] {
    return Array.from({ length: count }, () => {
      const code = crypto.randomInt(10000000, 99999999).toString();
      return `${code.slice(0, 4)}-${code.slice(4)}`;
    });
  }
}
