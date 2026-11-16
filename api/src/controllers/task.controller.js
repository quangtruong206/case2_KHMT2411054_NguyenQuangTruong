
const mongoose = require('mongoose');

const Task = require('../models/task.model');
const User = require('../models/user.model');
const TaskShare = require('../models/taskShare.model');
const Notification = require('../models/notification.model');
const getUserId = (req) => {
  const data = req.userData || req.user || {};
  return data.userId || data.id || data._id;
};

const validId = (id) => mongoose.Types.ObjectId.isValid(id);

const sameId = (a, b) => String(a) === String(b);

const getShare = (taskId, userId) => {
  return TaskShare.findOne({ taskId, userId });
};

const getTaskAccess = async (taskId, userId) => {
  if (!validId(taskId)) {
    return { task: null, role: null };
  }

  const task = await Task.findById(taskId);

  if (!task) {
    return { task: null, role: null };
  }

  if (sameId(task.createdBy, userId)) {
    return { task, role: 'owner' };
  }

  if ((task.assigneeIds || []).some(id => sameId(id, userId))) {
    return { task, role: 'assignee' };
  }

  const share = await getShare(taskId, userId);

  if (share) {
    return { task, role: share.permission, share };
  }

  return { task: null, role: null };
};

const canEdit = (role) => {
  return ['owner', 'assignee', 'editor'].includes(role);
};
// Tạo thông báo cho những người liên quan đến công việc
const createTaskNotifications = async ({
  task,
  senderId,
  recipientIds,
  type,
  title,
  message,
}) => {
  try {
    const uniqueRecipients = [
      ...new Set(
        recipientIds
          .filter(Boolean)
          .map(id => String(id))
          .filter(id => !sameId(id, senderId))
      ),
    ];

    if (uniqueRecipients.length === 0) return;

    await Notification.insertMany(
      uniqueRecipients.map(recipientId => ({
        recipient: recipientId,
        sender: senderId,
        task: task._id,
        type,
        title,
        message,
      }))
    );
  } catch (error) {
    // Không để lỗi thông báo làm thất bại thao tác công việc
    console.error('Lỗi tạo thông báo:', error);
  }
};

// Lấy danh sách người liên quan đến công việc
const getTaskRecipientIds = async (task) => {
  const shares = await TaskShare.find({
    taskId: task._id,
  }).select('userId');

  return [
    task.createdBy,
    ...(task.assigneeIds || []),
    ...shares.map(share => share.userId),
  ];
};

// 1. Lấy danh sách công việc
exports.getTasks = async (req, res) => {
  try {
    const userId = getUserId(req);
    const { status, priority, q, sortBy, order } = req.query;

    const shares = await TaskShare.find({ userId }).select('taskId');
    const sharedTaskIds = shares.map(item => item.taskId);

    const filter = {
      $or: [
        { createdBy: userId },
        { assigneeIds: userId },
        { _id: { $in: sharedTaskIds } },
      ],
    };

    if (status) filter.status = status;
    if (priority) filter.priority = priority;

    if (q) {
      const escaped = q.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      filter.title = { $regex: escaped, $options: 'i' };
    }

    const allowedSortFields = ['dueDate', 'priority', 'createdAt'];
    const field = allowedSortFields.includes(sortBy)
      ? sortBy
      : 'createdAt';

    const direction = order === 'asc' ? 1 : -1;

    const tasks = await Task.find(filter)
      .populate('createdBy', 'fullName name email')
      .populate('assigneeIds', 'fullName name email')
      .populate('primaryAssigneeId', 'fullName name email')
      .sort({ [field]: direction });

    return res.status(200).json(tasks);
  } catch (error) {
    console.error('Lỗi lấy danh sách:', error);
    return res.status(500).json({
      message: 'Lỗi khi lấy danh sách công việc',
    });
  }
};

// 2. Tạo công việc
exports.createTask = async (req, res) => {
  try {
    const userId = getUserId(req);
    const {
      title,
      description,
      startDate,
      dueDate,
      priority,
      status,
    } = req.body;

    if (!title || !title.trim()) {
      return res.status(400).json({
        message: 'Vui lòng nhập tên công việc',
      });
    }

    const task = await Task.create({
      title: title.trim(),
      description: description || '',
      createdBy: userId,
      startDate: startDate || null,
      dueDate: dueDate || null,
      priority: priority || 'medium',
      status: status || 'todo',
      assigneeIds: [],
      primaryAssigneeId: null,
    });

    return res.status(201).json({
      message: 'Tạo công việc thành công',
      task,
    });
  } catch (error) {
    console.error('Lỗi tạo công việc:', error);
    return res.status(500).json({
      message: 'Lỗi khi tạo công việc',
    });
  }
};

// 3. Xem chi tiết công việc
exports.getTaskById = async (req, res) => {
  try {
    const userId = getUserId(req);
    const { task, role } = await getTaskAccess(req.params.id, userId);

    if (!task) {
      return res.status(404).json({
        message: 'Không tìm thấy công việc hoặc bạn không có quyền truy cập',
      });
    }

    const populatedTask = await Task.findById(task._id)
      .populate('createdBy', 'fullName name email')
      .populate('assigneeIds', 'fullName name email')
      .populate('primaryAssigneeId', 'fullName name email');

    const shares = await TaskShare.find({ taskId: task._id })
      .populate('userId', 'fullName name email')
      .populate('sharedBy', 'fullName name email');

    return res.status(200).json({
      task: populatedTask,
      role,
      shares,
    });
  } catch (error) {
    console.error('Lỗi xem chi tiết:', error);
    return res.status(500).json({
      message: 'Lỗi khi xem chi tiết công việc',
    });
  }
};

// 4. Cập nhật công việc
exports.updateTask = async (req, res) => {
  try {
    const userId = getUserId(req);
    const { task, role } = await getTaskAccess(req.params.id, userId);

    if (!task) {
      return res.status(404).json({
        message: 'Không tìm thấy công việc',
      });
    }

    if (!canEdit(role)) {
      return res.status(403).json({
        message: 'Bạn chỉ có quyền xem công việc này',
      });
    }

    const allowedFields = [
      'title',
      'description',
      'startDate',
      'dueDate',
      'priority',
      'status',
    ];

    const updateData = {};

    for (const field of allowedFields) {
      if (req.body[field] !== undefined) {
        updateData[field] = req.body[field];
      }
    }

    if (updateData.title !== undefined && !String(updateData.title).trim()) {
      return res.status(400).json({
        message: 'Tên công việc không được để trống',
      });
    }

    if (updateData.title !== undefined) {
      updateData.title = String(updateData.title).trim();
    }
const updatedTask = await Task.findByIdAndUpdate(
  task._id,
  updateData,
  { new: true, runValidators: true }
);

// Chỉ gửi thông báo nếu có nội dung thực sự thay đổi
if (Object.keys(updateData).length > 0) {
  const recipientIds = await getTaskRecipientIds(task);

  const statusChanged =
    updateData.status !== undefined &&
    updateData.status !== task.status;

  await createTaskNotifications({
    task,
    senderId: userId,
    recipientIds,
    type: statusChanged ? 'task_status_changed' : 'task_updated',
    title: statusChanged
      ? 'Trạng thái công việc đã thay đổi'
      : 'Công việc vừa được cập nhật',
    message: statusChanged
      ? `Trạng thái công việc "${task.title}" đã được thay đổi thành ${updateData.status}`
      : `Công việc "${task.title}" vừa được cập nhật`,
  });
}

return res.status(200).json({
      message: 'Cập nhật công việc thành công',
      task: updatedTask,
    });
  } catch (error) {
    console.error('Lỗi cập nhật:', error);
    return res.status(500).json({
      message: 'Lỗi khi cập nhật công việc',
    });
  }
};

// 5. Cập nhật trạng thái
exports.updateTaskStatus = async (req, res) => {
  try {
    const userId = getUserId(req);
    const { task, role } = await getTaskAccess(req.params.id, userId);
    const { status } = req.body;

    const validStatuses = ['todo', 'in_progress', 'completed'];

    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        message: 'Trạng thái không hợp lệ',
      });
    }

    if (!task) {
      return res.status(404).json({
        message: 'Không tìm thấy công việc',
      });
    }

    if (!canEdit(role)) {
      return res.status(403).json({
        message: 'Bạn không có quyền thay đổi trạng thái',
      });
    }

    const oldStatus = task.status;

const updatedTask = await Task.findByIdAndUpdate(
  task._id,
  { status },
  { new: true, runValidators: true }
);

// Chỉ gửi thông báo khi trạng thái thực sự thay đổi
if (oldStatus !== status) {
  const recipientIds = await getTaskRecipientIds(task);

  await createTaskNotifications({
    task,
    senderId: userId,
    recipientIds,
    type: 'task_status_changed',
    title: 'Trạng thái công việc đã thay đổi',
    message: `Công việc "${task.title}" đã chuyển sang trạng thái ${status}`,
  });
}

return res.status(200).json({
      message: 'Cập nhật trạng thái thành công',
      task: updatedTask,
    });
  } catch (error) {
    console.error('Lỗi cập nhật trạng thái:', error);
    return res.status(500).json({
      message: 'Lỗi khi cập nhật trạng thái',
    });
  }
};

// 6. Xóa công việc
exports.deleteTask = async (req, res) => {
  try {
    const userId = getUserId(req);
    const { task, role } = await getTaskAccess(req.params.id, userId);

    if (!task) {
      return res.status(404).json({
        message: 'Không tìm thấy công việc',
      });
    }

    if (role !== 'owner') {
      return res.status(403).json({
        message: 'Chỉ người tạo công việc mới được xóa',
      });
    }

    await Task.findByIdAndDelete(task._id);
    await TaskShare.deleteMany({ taskId: task._id });

    return res.status(200).json({
      message: 'Xóa công việc thành công',
    });
  } catch (error) {
    console.error('Lỗi xóa công việc:', error);
    return res.status(500).json({
      message: 'Lỗi khi xóa công việc',
    });
  }
};

// 7. Phân công người thực hiện
exports.assignUsers = async (req, res) => {
  try {
    const userId = getUserId(req);
    const { task, role } = await getTaskAccess(req.params.id, userId);

    if (!task) {
      return res.status(404).json({
        message: 'Không tìm thấy công việc',
      });
    }

    if (role !== 'owner') {
      return res.status(403).json({
        message: 'Chỉ người tạo mới được phân công công việc',
      });
    }

    const { assigneeIds = [], primaryAssigneeId = null } = req.body;

    if (!Array.isArray(assigneeIds)) {
      return res.status(400).json({
        message: 'Danh sách người được giao không hợp lệ',
      });
    }

    const uniqueIds = [...new Set(assigneeIds.map(String))];

    if (uniqueIds.some(id => !validId(id))) {
      return res.status(400).json({
        message: 'Có ID người dùng không hợp lệ',
      });
    }

    if (
      primaryAssigneeId &&
      !uniqueIds.includes(String(primaryAssigneeId))
    ) {
      return res.status(400).json({
        message: 'Người phụ trách chính phải nằm trong danh sách được giao',
      });
    }

    const usersCount = await User.countDocuments({
      _id: { $in: uniqueIds },
    });

    if (usersCount !== uniqueIds.length) {
      return res.status(400).json({
        message: 'Một hoặc nhiều người dùng không tồn tại',
      });
    }

    // Chỉ thông báo cho người mới được phân công
const oldAssigneeIds = (task.assigneeIds || []).map(id => String(id));

const newAssigneeIds = uniqueIds.filter(
  id => !oldAssigneeIds.includes(String(id))
);

task.assigneeIds = uniqueIds;
task.primaryAssigneeId = primaryAssigneeId || null;

await task.save();

// Tạo thông báo cho người mới được giao việc
await createTaskNotifications({
  task,
  senderId: userId,
  recipientIds: newAssigneeIds,
  type: 'task_assigned',
  title: 'Bạn được phân công công việc mới',
  message: `Bạn vừa được phân công công việc: ${task.title}`,
});

    const updatedTask = await Task.findById(task._id)
      .populate('assigneeIds', 'fullName name email')
      .populate('primaryAssigneeId', 'fullName name email');

    return res.status(200).json({
      message: 'Phân công công việc thành công',
      task: updatedTask,
    });
  } catch (error) {
    console.error('Lỗi phân công:', error);
    return res.status(500).json({
      message: 'Không thể phân công công việc',
    });
  }
};

// 8. Xem danh sách người được chia sẻ
exports.getTaskShares = async (req, res) => {
  try {
    const userId = getUserId(req);
    const { task } = await getTaskAccess(req.params.id, userId);

    if (!task) {
      return res.status(404).json({
        message: 'Không tìm thấy công việc',
      });
    }

    const shares = await TaskShare.find({ taskId: task._id })
      .populate('userId', 'fullName name email')
      .populate('sharedBy', 'fullName name email');

    return res.status(200).json(shares);
  } catch (error) {
    console.error('Lỗi lấy danh sách chia sẻ:', error);
    return res.status(500).json({
      message: 'Không thể lấy danh sách chia sẻ',
    });
  }
};

// 9. Chia sẻ công việc
exports.shareTask = async (req, res) => {
  try {
    const userId = getUserId(req);
    const { task, role } = await getTaskAccess(req.params.id, userId);

    if (!task) {
      return res.status(404).json({
        message: 'Không tìm thấy công việc',
      });
    }

    if (role !== 'owner') {
      return res.status(403).json({
        message: 'Chỉ người tạo mới được chia sẻ công việc',
      });
    }

    const { userId: targetUserId, permission = 'viewer' } = req.body;

    if (!targetUserId || !validId(targetUserId)) {
      return res.status(400).json({
        message: 'ID người được chia sẻ không hợp lệ',
      });
    }

    if (sameId(targetUserId, task.createdBy)) {
      return res.status(400).json({
        message: 'Không cần chia sẻ công việc cho chính người tạo',
      });
    }

    if (!['viewer', 'editor'].includes(permission)) {
      return res.status(400).json({
        message: 'Quyền chia sẻ không hợp lệ',
      });
    }

    const targetUser = await User.findById(targetUserId);

    if (!targetUser) {
      return res.status(404).json({
        message: 'Không tìm thấy người dùng',
      });
    }
     const existingShare = await TaskShare.findOne({
  taskId: task._id,
  userId: targetUserId,
});
    const share = await TaskShare.findOneAndUpdate(
      { taskId: task._id, userId: targetUserId },
      {
        taskId: task._id,
        userId: targetUserId,
        sharedBy: userId,
        permission,
      },
      { new: true, upsert: true, runValidators: true }
    )
      .populate('userId', 'fullName name email')
      .populate('sharedBy', 'fullName name email');
// Chỉ gửi thông báo khi chia sẻ lần đầu
if (!existingShare) {
  await createTaskNotifications({
    task,
    senderId: userId,
    recipientIds: [targetUserId],
    type: 'task_shared',
    title: 'Bạn được chia sẻ công việc',
    message: `Bạn vừa được chia sẻ công việc: ${task.title}`,
  });
}
    return res.status(200).json({
      message: 'Chia sẻ công việc thành công',
      share,
    });
  } catch (error) {
    console.error('Lỗi chia sẻ:', error);
    return res.status(500).json({
      message: 'Không thể chia sẻ công việc',
    });
  }
};

// 10. Thay đổi quyền chia sẻ
exports.updateSharePermission = async (req, res) => {
  try {
    const userId = getUserId(req);
    const { task, role } = await getTaskAccess(req.params.id, userId);

    if (!task) {
      return res.status(404).json({
        message: 'Không tìm thấy công việc',
      });
    }

    if (role !== 'owner') {
      return res.status(403).json({
        message: 'Chỉ người tạo mới được thay đổi quyền chia sẻ',
      });
    }

    const { permission } = req.body;

    if (!['viewer', 'editor'].includes(permission)) {
      return res.status(400).json({
        message: 'Quyền phải là viewer hoặc editor',
      });
    }

    const existingShare = await TaskShare.findOne({
  taskId: task._id,
  userId: req.params.userId,
});

if (!existingShare) {
  return res.status(404).json({
    message: 'Không tìm thấy thông tin chia sẻ',
  });
}

const oldPermission = existingShare.permission;

const share = await TaskShare.findByIdAndUpdate(
  existingShare._id,
  { permission },
  { new: true, runValidators: true }
).populate('userId', 'fullName name email');

// Chỉ thông báo khi quyền thực sự thay đổi
if (oldPermission !== permission) {
  await createTaskNotifications({
    task,
    senderId: userId,
    recipientIds: [existingShare.userId],
    type: 'share_permission_changed',
    title: 'Quyền truy cập công việc đã thay đổi',
    message: `Quyền của bạn đối với công việc "${task.title}" đã được đổi thành ${permission === 'editor' ? 'Editor' : 'Viewer'}`,
  });
}

    if (!share) {
      return res.status(404).json({
        message: 'Không tìm thấy thông tin chia sẻ',
      });
    }

    return res.status(200).json({
      message: 'Cập nhật quyền thành công',
      share,
    });
  } catch (error) {
    console.error('Lỗi cập nhật quyền:', error);
    return res.status(500).json({
      message: 'Không thể cập nhật quyền chia sẻ',
    });
  }
};

// 11. Thu hồi quyền chia sẻ
exports.removeTaskShare = async (req, res) => {
  try {
    const userId = getUserId(req);
    const { task, role } = await getTaskAccess(req.params.id, userId);

    if (!task) {
      return res.status(404).json({
        message: 'Không tìm thấy công việc',
      });
    }

    if (role !== 'owner') {
      return res.status(403).json({
        message: 'Chỉ người tạo mới được thu hồi quyền chia sẻ',
      });
    }

    const deleted = await TaskShare.findOneAndDelete({
      taskId: task._id,
      userId: req.params.userId,
    });

    if (!deleted) {
      return res.status(404).json({
        message: 'Không tìm thấy thông tin chia sẻ',
      });
    }

    return res.status(200).json({
      message: 'Đã thu hồi quyền chia sẻ',
    });
  } catch (error) {
    console.error('Lỗi thu hồi chia sẻ:', error);
    return res.status(500).json({
      message: 'Không thể thu hồi quyền chia sẻ',
    });
  }
};
