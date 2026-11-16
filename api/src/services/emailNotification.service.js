const EmailLog = require('../models/emailLog.model');
const { sendEmail } = require('./email.service');

const EVENT_CONTENT = {
  task_assigned: {
    title: 'Bạn được phân công công việc mới',
    subject: '[TaskManager] Bạn được phân công công việc mới',
  },
  task_shared: {
    title: 'Bạn được chia sẻ công việc',
    subject: '[TaskManager] Có công việc được chia sẻ với bạn',
  },
  task_updated: {
    title: 'Công việc đã được cập nhật',
    subject: '[TaskManager] Công việc đã được cập nhật',
  },
  task_completed: {
    title: 'Công việc đã hoàn thành',
    subject: '[TaskManager] Công việc đã hoàn thành',
  },
  task_reminder: {
    title: 'Nhắc nhở thời hạn công việc',
    subject: '[TaskManager] Nhắc nhở công việc sắp đến hạn',
  },
};

const escapeHtml = (value) =>
  String(value ?? '').replace(/[&<>"']/g, (char) => ({
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#39;',
  })[char]);

async function sendTaskEmail({ task, recipient, eventType }) {
  let emailLog = null;

  try {
    const event = EVENT_CONTENT[eventType];

    if (!event) {
      throw new Error(`Loại email không hợp lệ: ${eventType}`);
    }

    if (!task || !task._id) {
      throw new Error('Không tìm thấy thông tin công việc');
    }

    if (!recipient || !recipient.email) {
      throw new Error('Người nhận không có địa chỉ email');
    }

    const recipientEmail = String(recipient.email).trim().toLowerCase();
    const recipientName = recipient.fullName || recipient.name || 'Bạn';
    const taskTitle = task.title || 'Công việc không có tiêu đề';

    emailLog = await EmailLog.create({
      taskId: task._id,
      recipientUserId: recipient._id || null,
      recipientEmail,
      eventType,
      subject: event.subject,
      status: 'pending',
      attempts: 1,
    });

    const text = [
      `Xin chào ${recipientName},`,
      '',
      event.title,
      `Công việc: ${taskTitle}`,
      task.description ? `Mô tả: ${task.description}` : '',
      '',
      'Đây là email tự động từ hệ thống TaskManager.',
    ].filter(Boolean).join('\n');

    const html = `
      <div style="font-family:Arial,sans-serif;line-height:1.6">
        <h2>${escapeHtml(event.title)}</h2>
        <p>Xin chào ${escapeHtml(recipientName)},</p>
        <p><strong>Công việc:</strong> ${escapeHtml(taskTitle)}</p>
        ${task.description ? `<p><strong>Mô tả:</strong> ${escapeHtml(task.description)}</p>` : ''}
        <p>Đây là email tự động từ hệ thống TaskManager.</p>
      </div>
    `;

    await sendEmail({
      to: recipientEmail,
      subject: event.subject,
      text,
      html,
    });

    emailLog.status = 'sent';
    emailLog.sentAt = new Date();
    emailLog.errorMessage = '';
    await emailLog.save();

    console.log(`Email sent: ${eventType} -> ${recipientEmail}`);
    return true;
  } catch (error) {
    if (emailLog) {
      try {
        emailLog.status = 'failed';
        emailLog.errorMessage = String(error.message || error).slice(0, 1000);
        await emailLog.save();
      } catch (logError) {
        console.error('Không thể cập nhật EmailLog:', logError.message);
      }
    }

    console.error('Gửi email thất bại:', error.message);
    return false;
  }
}

module.exports = {
  sendTaskEmail,
};