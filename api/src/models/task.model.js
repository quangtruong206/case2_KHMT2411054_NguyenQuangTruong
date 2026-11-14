
const mongoose = require('mongoose');

const taskSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: true,
      trim: true,
    },

    description: {
      type: String,
      default: '',
    },

    // Người tạo công việc
    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },

    // Danh sách người được giao
  assigneeIds: [
  {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
  },
],

primaryAssigneeId: {
  type: mongoose.Schema.Types.ObjectId,
  ref: 'User',
  default: null,
},

    // Ngày bắt đầu
    startDate: {
      type: Date,
      default: null,
    },

    // Hạn hoàn thành
    dueDate: {
      type: Date,
      default: null,
    },

    // Mức độ ưu tiên
    priority: {
      type: String,
      enum: ['low', 'medium', 'high'],
      default: 'medium',
    },

    // Trạng thái công việc
    status: {
      type: String,
      enum: ['todo', 'in_progress', 'completed'],
      default: 'todo',
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('Task', taskSchema);
