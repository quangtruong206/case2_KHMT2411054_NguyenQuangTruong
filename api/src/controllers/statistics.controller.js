
const mongoose = require('mongoose');
const Task = require('../models/task.model');
const TaskShare = require('../models/taskShare.model');

// Lấy ID người dùng đăng nhập
const getUserId = (req) => {
  const data = req.userData || req.user || {};
  return data.userId || data.id || data._id;
};

// 1. Thống kê công việc theo trạng thái
exports.getTaskStatistics = async (req, res) => {
  try {
    const userId = getUserId(req);

    if (!userId || !mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(401).json({
        message: 'Thông tin người dùng không hợp lệ',
      });
    }

    // Lấy các công việc được chia sẻ cho người dùng
    const sharedTaskIds = await TaskShare.distinct('taskId', {
      userId,
    });

    const tasks = await Task.find({
      $or: [
        { createdBy: userId },
        { assigneeIds: userId },
        { primaryAssigneeId: userId },
        { _id: { $in: sharedTaskIds } },
      ],
    });

    const statistics = {
      total: tasks.length,
      todo: tasks.filter(task => task.status === 'todo').length,
      in_progress: tasks.filter(
        task => task.status === 'in_progress'
      ).length,
      completed: tasks.filter(
        task => task.status === 'completed'
      ).length,
    };

    return res.status(200).json({
      message: 'Thống kê công việc thành công',
      statistics,
    });
  } catch (error) {
    console.error('Lỗi thống kê công việc:', error);
    return res.status(500).json({
      message: 'Không thể thống kê công việc',
    });
  }
};

// 2. Thống kê công việc được giao và đang phụ trách
exports.getAssignmentStatistics = async (req, res) => {
  try {
    const userId = getUserId(req);

    if (!userId || !mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(401).json({
        message: 'Thông tin người dùng không hợp lệ',
      });
    }

    const [assignedTasks, responsibleTasks] = await Promise.all([
      Task.find({ assigneeIds: userId }),
      Task.find({ primaryAssigneeId: userId }),
    ]);

    return res.status(200).json({
      message: 'Thống kê phân công thành công',
      statistics: {
        assigned: assignedTasks.length,
        responsible: responsibleTasks.length,
      },
      assignedTasks,
      responsibleTasks,
    });
  } catch (error) {
    console.error('Lỗi thống kê phân công:', error);
    return res.status(500).json({
      message: 'Không thể thống kê phân công công việc',
    });
  }
};

// 3. Thống kê công việc sắp đến hạn và quá hạn
exports.getDeadlineStatistics = async (req, res) => {
  try {
    const userId = getUserId(req);

    if (!userId || !mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(401).json({
        message: 'Thông tin người dùng không hợp lệ',
      });
    }

    const now = new Date();

    // Tính từ đầu ngày hôm nay
    const today = new Date(now);
    today.setHours(0, 0, 0, 0);

    // Trong vòng 7 ngày tới
    const nextSevenDays = new Date(today);
    nextSevenDays.setDate(nextSevenDays.getDate() + 7);

    // Lấy các công việc được chia sẻ cho người dùng
    const sharedTaskIds = await TaskShare.distinct('taskId', {
      userId,
    });

    const userTasks = {
      $or: [
        { createdBy: userId },
        { assigneeIds: userId },
        { primaryAssigneeId: userId },
        { _id: { $in: sharedTaskIds } },
      ],
    };

    const [overdueTasks, upcomingTasks] = await Promise.all([
      Task.find({
        ...userTasks,
        dueDate: { $ne: null, $lt: today },
        status: { $ne: 'completed' },
      }).sort({ dueDate: 1 }),

      Task.find({
        ...userTasks,
        dueDate: {
          $gte: today,
          $lte: nextSevenDays,
        },
        status: { $ne: 'completed' },
      }).sort({ dueDate: 1 }),
    ]);

    return res.status(200).json({
      message: 'Thống kê thời hạn công việc thành công',
      statistics: {
        overdue: overdueTasks.length,
        upcoming: upcomingTasks.length,
      },
      overdueTasks,
      upcomingTasks,
    });
  } catch (error) {
    console.error('Lỗi thống kê thời hạn:', error);
    return res.status(500).json({
      message: 'Không thể thống kê thời hạn công việc',
    });
  }
};
