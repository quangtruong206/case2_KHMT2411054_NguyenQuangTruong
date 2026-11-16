const cron = require('node-cron');

const Task = require('../models/task.model');
const User = require('../models/user.model');
const TaskShare = require('../models/taskShare.model');
const EmailLog = require('../models/emailLog.model');
const { sendEmail } = require('./email.service');

let isRunning = false;

const escapeHtml = (value) =>
  String(value ?? '').replace(/[&<>"']/g, (char) => ({
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#39;',
  })[char]);

async function sendReminderEmail(task, recipient) {
  if (!recipient.email) {
    return;
  }

  const recipientEmail = String(recipient.email).trim().toLowerCase();
  const dueDate = new Date(task.dueDate);

  // Mỗi công việc, người nhận và thời hạn có một khóa riêng.
  const reminderKey =
    `${task._id}:${recipient._id}:${dueDate.getTime()}`;

  const subject = `[TaskManager] Nhắc nhở công việc sắp đến hạn: ${task.title}`;

  let emailLog;

  try {
    emailLog = await EmailLog.create({
      taskId: task._id,
      recipientUserId: recipient._id,
      recipientEmail,
      eventType: 'task_reminder',
      reminderKey,
      subject,
      status: 'pending',
      attempts: 1,
    });
  } catch (error) {
    if (error.code !== 11000) {
      throw error;
    }

    // Khóa đã tồn tại: không gửi lại nếu đã gửi hoặc đang xử lý.
    const existingLog = await EmailLog.findOne({ reminderKey });

    if (!existingLog || existingLog.status !== 'failed') {
      return;
    }

    // Chỉ cho phép một lần thử lại đối với bản ghi đang thất bại.
    emailLog = await EmailLog.findOneAndUpdate(
      {
        _id: existingLog._id,
        status: 'failed',
      },
      {
        $set: {
          status: 'pending',
          errorMessage: '',
        },
        $inc: {
          attempts: 1,
        },
      },
      { new: true }
    );

    if (!emailLog) {
      return;
    }
  }

  try {
    const recipientName =
      recipient.fullName || recipient.name || 'Bạn';

    const dueDateText = dueDate.toLocaleString('vi-VN', {
      timeZone: 'Asia/Ho_Chi_Minh',
    });

    const text = [
      `Xin chào ${recipientName},`,
      '',
      'Đây là email nhắc nhở về công việc sắp đến hạn.',
      `Công việc: ${task.title}`,
      task.description ? `Mô tả: ${task.description}` : '',
      `Hạn hoàn thành: ${dueDateText}`,
      `Trạng thái: ${task.status}`,
      '',
      'Vui lòng kiểm tra và hoàn thành công việc đúng hạn.',
      'Đây là email tự động từ hệ thống TaskManager.',
    ].filter(Boolean).join('\n');

    const html = `
      <div style="font-family:Arial,sans-serif;line-height:1.6">
        <h2>Nhắc nhở công việc sắp đến hạn</h2>
        <p>Xin chào ${escapeHtml(recipientName)},</p>
        <p>Công việc của bạn sắp đến hạn hoàn thành.</p>
        <p><strong>Công việc:</strong> ${escapeHtml(task.title)}</p>
        <p><strong>Mô tả:</strong> ${escapeHtml(task.description || 'Không có')}</p>
        <p><strong>Hạn hoàn thành:</strong> ${escapeHtml(dueDateText)}</p>
        <p><strong>Trạng thái:</strong> ${escapeHtml(task.status)}</p>
        <p>Vui lòng kiểm tra và hoàn thành công việc đúng hạn.</p>
        <p>Đây là email tự động từ hệ thống TaskManager.</p>
      </div>
    `;

    const result = await sendEmail({
      to: recipientEmail,
      subject,
      text,
      html,
    });

    if (
      result.rejected &&
      result.rejected.some(
        email => String(email).toLowerCase() === recipientEmail
      )
    ) {
      throw new Error('Máy chủ email từ chối địa chỉ người nhận.');
    }

    emailLog.status = 'sent';
    emailLog.sentAt = new Date();
    emailLog.errorMessage = '';
    await emailLog.save();

    console.log(`Reminder email sent: ${recipientEmail}`);
  } catch (error) {
    emailLog.status = 'failed';
    emailLog.errorMessage = String(error.message || error).slice(0, 1000);
    await emailLog.save();

    console.error(
      `Reminder email failed for ${recipientEmail}:`,
      error.message
    );
  }
}

async function runTaskReminders() {
  if (isRunning) {
    console.log('Reminder job is already running. Skipping.');
    return;
  }

  isRunning = true;

  try {
    const now = new Date();
    const next24Hours = new Date(
      now.getTime() + 24 * 60 * 60 * 1000
    );

    // Lấy công việc chưa hoàn thành có hạn trong 24 giờ tới.
    const tasks = await Task.find({
      dueDate: {
        $gt: now,
        $lte: next24Hours,
      },
      status: { $ne: 'completed' },
    });

    console.log(`Checking reminders: ${tasks.length} task(s).`);

    for (const task of tasks) {
      const shares = await TaskShare.find({
        taskId: task._id,
      }).select('userId');

      const recipientIds = [
        task.createdBy,
        ...(task.assigneeIds || []),
        ...shares.map(share => share.userId),
      ]
        .filter(Boolean)
        .map(id => String(id));

      // Loại bỏ người nhận trùng lặp.
      const uniqueRecipientIds = [...new Set(recipientIds)];

      if (uniqueRecipientIds.length === 0) {
        continue;
      }

      const recipients = await User.find({
        _id: { $in: uniqueRecipientIds },
      }).select('fullName name email');

      for (const recipient of recipients) {
        await sendReminderEmail(task, recipient);
      }
    }

    console.log('Reminder job completed.');
  } catch (error) {
    console.error('Reminder job error:', error.message);
  } finally {
    isRunning = false;
  }
}

function startReminderScheduler() {
  cron.schedule(
    '*/15 * * * *',
    () => {
      runTaskReminders();
    },
    {
      timezone: 'Asia/Ho_Chi_Minh',
    }
  );

  console.log('Task reminder scheduler started (every 15 minutes).');

  // Kiểm tra ngay khi server khởi động.
  runTaskReminders();
}

module.exports = {
  startReminderScheduler,
  runTaskReminders,
};