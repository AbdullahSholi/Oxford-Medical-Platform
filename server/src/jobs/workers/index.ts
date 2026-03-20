// ═══════════════════════════════════════════════════════════
// MedOrder — Worker Entry Point
// Starts all BullMQ workers for background job processing
// Run: npm run worker  (separate from API server)
// ═══════════════════════════════════════════════════════════

import { logger } from '../../config/logger';

// Import workers (they self-register on import)
import './notification.worker';
import './order.worker';

logger.info('🏭 All BullMQ workers started');
logger.info('   Workers: notifications, orders');
logger.info('   Press Ctrl+C to stop');

// Graceful shutdown
process.on('SIGTERM', () => {
    logger.info('SIGTERM received — shutting down workers');
    process.exit(0);
});

process.on('SIGINT', () => {
    logger.info('SIGINT received — shutting down workers');
    process.exit(0);
});
