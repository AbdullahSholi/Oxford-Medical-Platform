import { Request, Response } from 'express';
import { ReviewService } from './review.service';
import { ApiResponse } from '../../shared/utils/api-response';

export class ReviewController {
    constructor(private service: ReviewService) { }

    create = async (req: Request, res: Response): Promise<void> => {
        const review = await this.service.createReview(req.user!.id, req.body);
        ApiResponse.created(res, review);
    };

    update = async (req: Request, res: Response): Promise<void> => {
        const review = await this.service.updateReview(req.user!.id, req.params.id as string, req.body);
        ApiResponse.success(res, { data: review, message: 'Review updated' });
    };

    remove = async (req: Request, res: Response): Promise<void> => {
        await this.service.deleteReview(req.user!.id, req.params.id as string);
        ApiResponse.noContent(res);
    };
}
