import { Request, Response } from 'express';
import { AuthService } from './auth.service';
import { ApiResponse } from '../../shared/utils/api-response';

export class AuthController {
    constructor(private service: AuthService) {}

    register = async (req: Request, res: Response): Promise<void> => {
        const licenseUrl = ''; // TODO: handle file upload for license
        const result = await this.service.register(req.body, licenseUrl);
        ApiResponse.created(res, result.doctor, 'Registration successful. Your account is pending approval.');
    };

    login = async (req: Request, res: Response): Promise<void> => {
        const result = await this.service.login(req.body);
        ApiResponse.success(res, {
            data: {
                accessToken: result.tokens.accessToken,
                refreshToken: result.tokens.refreshToken,
                doctor: result.doctor,
            },
            message: 'Login successful',
        });
    };

    adminLogin = async (req: Request, res: Response): Promise<void> => {
        const { email, password } = req.body;
        const result = await this.service.adminLogin(email, password);
        ApiResponse.success(res, {
            data: {
                accessToken: result.tokens.accessToken,
                refreshToken: result.tokens.refreshToken,
                admin: result.admin,
            },
            message: 'Admin login successful',
        });
    };

    sendOtp = async (req: Request, res: Response): Promise<void> => {
        await this.service.sendOtp(req.body.email);
        ApiResponse.success(res, { message: 'If the email exists, an OTP has been sent' });
    };

    verifyOtp = async (req: Request, res: Response): Promise<void> => {
        const valid = await this.service.verifyOtp(req.body.email, req.body.otp);
        if (!valid) {
            ApiResponse.error(res, 400, 'INVALID_OTP', 'Invalid or expired OTP');
            return;
        }
        ApiResponse.success(res, { message: 'OTP verified successfully' });
    };

    resetPassword = async (req: Request, res: Response): Promise<void> => {
        await this.service.resetPassword(req.body);
        ApiResponse.success(res, { message: 'Password reset successful' });
    };

    refreshToken = async (req: Request, res: Response): Promise<void> => {
        const tokens = await this.service.refreshToken(req.body.refreshToken);
        ApiResponse.success(res, {
            data: {
                accessToken: tokens.accessToken,
                refreshToken: tokens.refreshToken,
            },
        });
    };

    logout = async (req: Request, res: Response): Promise<void> => {
        if (req.user) {
            await this.service.logout(req.user.tokenJti, req.user.id);
        }
        ApiResponse.success(res, { message: 'Logged out successfully' });
    };
}
