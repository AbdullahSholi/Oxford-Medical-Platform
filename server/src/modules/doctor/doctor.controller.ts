import { Request, Response } from 'express';
import { DoctorService } from './doctor.service';
import { ApiResponse } from '../../shared/utils/api-response';

export class DoctorController {
    constructor(private service: DoctorService) { }

    getProfile = async (req: Request, res: Response): Promise<void> => {
        const doctor = await this.service.getProfile(req.user!.id);
        ApiResponse.success(res, { data: doctor });
    };

    updateProfile = async (req: Request, res: Response): Promise<void> => {
        const doctor = await this.service.updateProfile(req.user!.id, req.body);
        ApiResponse.success(res, { data: doctor, message: 'Profile updated' });
    };

    getAddresses = async (req: Request, res: Response): Promise<void> => {
        const addresses = await this.service.getAddresses(req.user!.id);
        ApiResponse.success(res, { data: addresses });
    };

    createAddress = async (req: Request, res: Response): Promise<void> => {
        const address = await this.service.createAddress(req.user!.id, req.body);
        ApiResponse.created(res, address);
    };

    updateAddress = async (req: Request, res: Response): Promise<void> => {
        const address = await this.service.updateAddress(req.params.id as string, req.user!.id, req.body);
        ApiResponse.success(res, { data: address, message: 'Address updated' });
    };

    deleteAddress = async (req: Request, res: Response): Promise<void> => {
        await this.service.deleteAddress(req.params.id as string, req.user!.id);
        ApiResponse.noContent(res);
    };
}
