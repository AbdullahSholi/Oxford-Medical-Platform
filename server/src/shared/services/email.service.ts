// ═══════════════════════════════════════════════════════════
// MedOrder — Email Service (Nodemailer)
// Sends transactional emails: order confirmation, status updates, etc.
// ═══════════════════════════════════════════════════════════

import nodemailer from 'nodemailer';
import { env, isDevelopment } from '../../config/env';
import { logger } from '../../config/logger';

// Create transporter — uses Ethereal (test) in dev, SMTP/SendGrid in production
let transporter: nodemailer.Transporter;

async function getTransporter(): Promise<nodemailer.Transporter> {
    if (transporter) return transporter;

    if (isDevelopment && !env.SMTP_HOST && !env.SENDGRID_API_KEY) {
        // Use Ethereal for development (fake SMTP that captures emails)
        const testAccount = await nodemailer.createTestAccount();
        transporter = nodemailer.createTransport({
            host: 'smtp.ethereal.email',
            port: 587,
            secure: false,
            auth: { user: testAccount.user, pass: testAccount.pass },
        });
        logger.info(`📧 Email: using Ethereal test account (${testAccount.user})`);
    } else if (env.SMTP_HOST) {
        // Generic SMTP (Resend, Mailgun, Amazon SES, etc.)
        transporter = nodemailer.createTransport({
            host: env.SMTP_HOST,
            port: env.SMTP_PORT,
            secure: env.SMTP_PORT === 465,
            auth: { user: env.SMTP_USER, pass: env.SMTP_PASS },
        });
        logger.info(`📧 Email: using SMTP (${env.SMTP_HOST})`);
    } else if (env.SENDGRID_API_KEY) {
        transporter = nodemailer.createTransport({
            host: 'smtp.sendgrid.net',
            port: 587,
            auth: { user: 'apikey', pass: env.SENDGRID_API_KEY },
        });
        logger.info('📧 Email: using SendGrid');
    } else {
        // Fallback: log-only transport
        transporter = nodemailer.createTransport({ jsonTransport: true });
        logger.warn('📧 Email: no SMTP configured, emails will be logged only');
    }

    return transporter;
}

interface EmailOptions {
    to: string;
    subject: string;
    html: string;
    text?: string;
}

export async function sendEmail(options: EmailOptions): Promise<void> {
    try {
        const transport = await getTransporter();
        const info = await transport.sendMail({
            from: `"MedOrder" <${env.EMAIL_FROM}>`,
            to: options.to,
            subject: options.subject,
            html: options.html,
            text: options.text,
        });

        if (isDevelopment) {
            const previewUrl = nodemailer.getTestMessageUrl(info);
            if (previewUrl) {
                logger.info({ previewUrl }, '📧 Email preview available');
            }
        }

        logger.info({ to: options.to, subject: options.subject, messageId: info.messageId }, '📧 Email sent');
    } catch (error) {
        logger.error({ error, to: options.to, subject: options.subject }, '📧 Failed to send email');
    }
}

// ── Email Templates ──────────────────────────────────────

export function orderConfirmationEmail(data: {
    doctorName: string;
    orderNumber: string;
    items: Array<{ name: string; quantity: number; price: number }>;
    subtotal: number;
    deliveryFee: number;
    discount: number;
    total: number;
}): { subject: string; html: string } {
    const itemRows = data.items
        .map(
            (item) =>
                `<tr><td style="padding:8px;border-bottom:1px solid #eee">${item.name}</td><td style="padding:8px;border-bottom:1px solid #eee;text-align:center">${item.quantity}</td><td style="padding:8px;border-bottom:1px solid #eee;text-align:right">EGP ${item.price.toFixed(2)}</td></tr>`,
        )
        .join('');

    return {
        subject: `Order Confirmed - ${data.orderNumber}`,
        html: `
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width"></head>
<body style="font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;margin:0;padding:0;background:#f5f5f5">
<div style="max-width:600px;margin:20px auto;background:#fff;border-radius:12px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,0.08)">
  <div style="background:#1A73E8;padding:24px;text-align:center">
    <h1 style="color:#fff;margin:0;font-size:22px">Order Confirmed!</h1>
  </div>
  <div style="padding:24px">
    <p>Hello Dr. ${data.doctorName},</p>
    <p>Thank you for your order. Here's a summary:</p>
    <div style="background:#f8f9fa;border-radius:8px;padding:16px;margin:16px 0">
      <p style="margin:0;font-weight:600;color:#1A73E8">Order ${data.orderNumber}</p>
    </div>
    <table style="width:100%;border-collapse:collapse;margin:16px 0">
      <thead><tr style="background:#f8f9fa"><th style="padding:8px;text-align:left">Item</th><th style="padding:8px;text-align:center">Qty</th><th style="padding:8px;text-align:right">Price</th></tr></thead>
      <tbody>${itemRows}</tbody>
    </table>
    <div style="border-top:2px solid #eee;padding-top:12px;margin-top:8px">
      <div style="display:flex;justify-content:space-between;margin-bottom:4px"><span>Subtotal</span><span>EGP ${data.subtotal.toFixed(2)}</span></div>
      ${data.discount > 0 ? `<div style="display:flex;justify-content:space-between;margin-bottom:4px;color:#28a745"><span>Discount</span><span>-EGP ${data.discount.toFixed(2)}</span></div>` : ''}
      <div style="display:flex;justify-content:space-between;margin-bottom:4px"><span>Delivery</span><span>${data.deliveryFee > 0 ? `EGP ${data.deliveryFee.toFixed(2)}` : 'Free'}</span></div>
      <div style="display:flex;justify-content:space-between;font-weight:700;font-size:16px;margin-top:8px;padding-top:8px;border-top:2px solid #1A73E8"><span>Total</span><span>EGP ${data.total.toFixed(2)}</span></div>
    </div>
    <p style="color:#666;font-size:13px;margin-top:24px">You can track your order in the MedOrder app. We'll notify you when it's on its way.</p>
  </div>
  <div style="background:#f8f9fa;padding:16px;text-align:center;font-size:12px;color:#999">
    <p style="margin:0">MedOrder — Medical Supplies for Healthcare Professionals</p>
  </div>
</div>
</body>
</html>`,
    };
}

export function welcomeEmail(data: { doctorName: string }): { subject: string; html: string } {
    return {
        subject: 'Welcome to MedOrder!',
        html: `
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width"></head>
<body style="font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;margin:0;padding:0;background:#f5f5f5">
<div style="max-width:600px;margin:20px auto;background:#fff;border-radius:12px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,0.08)">
  <div style="background:#1A73E8;padding:32px;text-align:center">
    <h1 style="color:#fff;margin:0;font-size:24px">Welcome to MedOrder!</h1>
  </div>
  <div style="padding:24px">
    <p>Hello Dr. ${data.doctorName},</p>
    <p>Thank you for registering on MedOrder — the leading B2B medical supply platform for healthcare professionals.</p>
    <p>Your account is currently <strong>under review</strong>. Our team will verify your credentials and notify you once your account is approved.</p>
    <div style="background:#f8f9fa;border-radius:8px;padding:16px;margin:16px 0">
      <p style="margin:0;font-weight:600">What happens next?</p>
      <ul style="color:#666;padding-left:20px">
        <li>Our team reviews your license and credentials</li>
        <li>You'll receive an email once approved</li>
        <li>Start ordering medical supplies at competitive prices</li>
      </ul>
    </div>
    <p style="color:#666;font-size:13px">If you have any questions, reply to this email.</p>
  </div>
  <div style="background:#f8f9fa;padding:16px;text-align:center;font-size:12px;color:#999">
    <p style="margin:0">MedOrder — Medical Supplies for Healthcare Professionals</p>
  </div>
</div>
</body>
</html>`,
    };
}

export function accountApprovedEmail(data: { doctorName: string }): { subject: string; html: string } {
    return {
        subject: 'Your MedOrder Account is Approved!',
        html: `
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width"></head>
<body style="font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;margin:0;padding:0;background:#f5f5f5">
<div style="max-width:600px;margin:20px auto;background:#fff;border-radius:12px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,0.08)">
  <div style="background:#28a745;padding:32px;text-align:center">
    <h1 style="color:#fff;margin:0;font-size:24px">Account Approved!</h1>
  </div>
  <div style="padding:24px">
    <p>Hello Dr. ${data.doctorName},</p>
    <p>Great news! Your MedOrder account has been <strong style="color:#28a745">approved</strong>.</p>
    <p>You can now log in and start ordering medical supplies for your practice.</p>
    <div style="text-align:center;margin:24px 0">
      <a href="#" style="background:#1A73E8;color:#fff;padding:12px 32px;border-radius:8px;text-decoration:none;font-weight:600">Open MedOrder App</a>
    </div>
    <p style="color:#666;font-size:13px">Welcome aboard! We're excited to serve your practice.</p>
  </div>
  <div style="background:#f8f9fa;padding:16px;text-align:center;font-size:12px;color:#999">
    <p style="margin:0">MedOrder — Medical Supplies for Healthcare Professionals</p>
  </div>
</div>
</body>
</html>`,
    };
}

export function accountRejectedEmail(data: { doctorName: string; reason: string }): { subject: string; html: string } {
    return {
        subject: 'MedOrder Account Update',
        html: `
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width"></head>
<body style="font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;margin:0;padding:0;background:#f5f5f5">
<div style="max-width:600px;margin:20px auto;background:#fff;border-radius:12px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,0.08)">
  <div style="background:#dc3545;padding:32px;text-align:center">
    <h1 style="color:#fff;margin:0;font-size:24px">Account Review Update</h1>
  </div>
  <div style="padding:24px">
    <p>Hello Dr. ${data.doctorName},</p>
    <p>Unfortunately, we were unable to approve your MedOrder account at this time.</p>
    <div style="background:#fff3cd;border-radius:8px;padding:16px;margin:16px 0;border-left:4px solid #ffc107">
      <p style="margin:0;font-weight:600">Reason:</p>
      <p style="margin:8px 0 0;color:#666">${data.reason}</p>
    </div>
    <p>If you believe this was a mistake, please contact our support team with updated documentation.</p>
  </div>
  <div style="background:#f8f9fa;padding:16px;text-align:center;font-size:12px;color:#999">
    <p style="margin:0">MedOrder — Medical Supplies for Healthcare Professionals</p>
  </div>
</div>
</body>
</html>`,
    };
}

export function orderStatusUpdateEmail(data: {
    doctorName: string;
    orderNumber: string;
    status: string;
    statusMessage: string;
}): { subject: string; html: string } {
    const statusColors: Record<string, string> = {
        confirmed: '#28a745',
        processing: '#ffc107',
        shipped: '#17a2b8',
        delivered: '#28a745',
        cancelled: '#dc3545',
    };
    const color = statusColors[data.status] || '#1A73E8';

    return {
        subject: `Order ${data.orderNumber} — ${data.statusMessage}`,
        html: `
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width"></head>
<body style="font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;margin:0;padding:0;background:#f5f5f5">
<div style="max-width:600px;margin:20px auto;background:#fff;border-radius:12px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,0.08)">
  <div style="background:${color};padding:24px;text-align:center">
    <h1 style="color:#fff;margin:0;font-size:22px">${data.statusMessage}</h1>
  </div>
  <div style="padding:24px">
    <p>Hello Dr. ${data.doctorName},</p>
    <p>Your order <strong>${data.orderNumber}</strong> status has been updated.</p>
    <div style="background:#f8f9fa;border-radius:8px;padding:20px;margin:16px 0;text-align:center">
      <p style="margin:0;font-size:18px;font-weight:700;color:${color}">${data.status.replace(/_/g, ' ').toUpperCase()}</p>
    </div>
    <p style="color:#666;font-size:13px">Track your order in the MedOrder app for real-time updates.</p>
  </div>
  <div style="background:#f8f9fa;padding:16px;text-align:center;font-size:12px;color:#999">
    <p style="margin:0">MedOrder — Medical Supplies for Healthcare Professionals</p>
  </div>
</div>
</body>
</html>`,
    };
}
