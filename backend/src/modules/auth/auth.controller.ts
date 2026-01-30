import { Body, Controller, Post, Get, Req, UseGuards, HttpCode, HttpStatus, Param } from '@nestjs/common';
import { AuthService } from './auth.service';
import { z } from 'zod';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiResponse } from '@nestjs/swagger';

const LoginSchema = z.object({ email: z.string().email(), password: z.string() });
const ChangePasswordSchema = z.object({
  currentPassword: z.string().min(1),
  newPassword: z.string().min(8),
});
const TwoFactorVerifySchema = z.object({ code: z.string().length(6) });

@ApiTags('Authentication')
@Controller('api/v1/auth')
export class AuthController {
  constructor(private auth: AuthService) { }

  @Post('login')
  @ApiOperation({ summary: 'User login with email and password' })
  @ApiResponse({ status: 200, description: 'Login successful' })
  @ApiResponse({ status: 401, description: 'Invalid credentials' })
  async login(@Body() body: any, @Req() req: any) {
    const parsed = LoginSchema.parse(body);
    const ip = req.ip || req.connection?.remoteAddress;
    const userAgent = req.headers['user-agent'];
    return this.auth.login(parsed.email, parsed.password, { ip, userAgent });
  }

  @Post('refresh')
  @ApiOperation({ summary: 'Refresh access token using refresh token' })
  async refresh(@Body() body: any) {
    const { userId, token } = body;
    return this.auth.refresh(userId, token);
  }

  @Post('logout')
  @HttpCode(HttpStatus.OK)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Logout user and invalidate session' })
  async logout(@Body() body: any, @Req() req: any) {
    const { userId, refreshToken } = body;
    const ip = req.ip || req.connection?.remoteAddress;
    const userAgent = req.headers['user-agent'];
    return this.auth.logout(userId, refreshToken, { ip, userAgent });
  }

  @Post('change-password')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Change user password' })
  @ApiResponse({ status: 200, description: 'Password changed successfully' })
  @ApiResponse({ status: 400, description: 'Invalid current password' })
  async changePassword(@Body() body: any, @Req() req: any) {
    const parsed = ChangePasswordSchema.parse(body);
    const userId = req.user?.id || body.userId; // from JWT or body
    return this.auth.changePassword(
      userId,
      parsed.currentPassword,
      parsed.newPassword,
    );
  }

  @Get('login-history/:userId')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get login history for a user' })
  async getLoginHistory(@Param('userId') userId: string) {
    return this.auth.getLoginHistory(parseInt(userId));
  }

  // =================== 2FA ENDPOINTS ===================

  @Post('2fa/setup')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Setup two-factor authentication' })
  async setup2FA(@Body() body: any) {
    const { userId, email } = body;
    return this.auth.setup2FA(userId, email);
  }

  @Post('2fa/verify-setup')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Verify 2FA setup with TOTP code' })
  async verify2FASetup(@Body() body: any) {
    const parsed = TwoFactorVerifySchema.parse({ code: body.code });
    const { userId } = body;
    return this.auth.verify2FASetup(userId, parsed.code);
  }

  @Post('2fa/verify')
  @ApiOperation({ summary: 'Verify 2FA code during login' })
  async verify2FA(@Body() body: any) {
    const parsed = TwoFactorVerifySchema.parse({ code: body.code });
    const { userId } = body;
    return this.auth.verify2FA(userId, parsed.code);
  }

  @Post('2fa/disable')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Disable two-factor authentication' })
  async disable2FA(@Body() body: any) {
    const { userId, code } = body;
    return this.auth.disable2FA(userId, code);
  }

  @Get('2fa/status/:userId')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Check if 2FA is enabled for a user' })
  async get2FAStatus(@Param('userId') userId: string) {
    return this.auth.get2FAStatus(parseInt(userId));
  }

  @Post('2fa/backup-codes')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Generate new backup codes' })
  async generateBackupCodes(@Body() body: any) {
    const { userId } = body;
    return this.auth.generateBackupCodes(userId);
  }
}
