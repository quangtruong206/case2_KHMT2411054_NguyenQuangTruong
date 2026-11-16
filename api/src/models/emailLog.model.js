
const mongoose = require('mongoose');

const emailLogSchema = new mongoose.Schema(
  {
    taskId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Task',
      default: null,
    },

    recipientUserId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },

    recipientEmail: {
      type: String,
      required: true,
      trim: true,
      lowercase: true,
    },

    eventType: {
      type: String,
      required: true,
      enum: [
        'task_assigned',
        'task_shared',
        'task_updated',
        'task_completed',
        'task_reminder',
      ],
    },

    subject: {
      type: String,
      required: true,
    },

    status: {
      type: String,
      enum: ['pending', 'sent', 'failed'],
      default: 'pending',
      index: true,
    },

    attempts: {
      type: Number,
      default: 0,
    },

    errorMessage: {
      type: String,
      default: '',
    },

    sentAt: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

emailLogSchema.index({ taskId: 1, createdAt: -1 });
emailLogSchema.index({ recipientEmail: 1, createdAt: -1 });

module.exports = mongoose.model('EmailLog', emailLogSchema);
