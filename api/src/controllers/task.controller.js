
const Task = require('../models/task.model');

// Lấy ID người dùng từ token đăng nhập
const getUserId = (req) => {
  const data = req.userData || req.user || {};
  return data.userId || data.id || data._id;
};

// 1. Lấy danh sách công việc
exports.getTasks = async (req, res) => {
  try {
    const userId = getUserId(req);

    const { status, priority, q, sortBy, order } = req.query;

    const filter = { createdBy: userId };

    if (status) {
      filter.status = status;
    }

    if (priority) {
      filter.priority = priority;
    }

    if (q) {
      filter.title = { $regex: q, $options: 'i' };
    }

    const allowedSortFields = [
      'dueDate',
      'priority',
      'createdAt',
    ];

    const field = allowedSortFields.includes(sortBy)
      ? sortBy
      : 'createdAt';

    const direction = order === 'asc' ? 1 : -1;

    const tasks = await Task.find(filter)
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

    const task = await Task.findOne({
      _id: req.params.id,
      createdBy: userId,
    });

    if (!task) {
      return res.status(404).json({
        message: 'Không tìm thấy công việc',
      });
    }

    return res.status(200).json(task);
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

    const task = await Task.findOneAndUpdate(
      {
        _id: req.params.id,
        createdBy: userId,
      },
      updateData,
      {
        new: true,
        runValidators: true,
      }
    );

    if (!task) {
      return res.status(404).json({
        message: 'Không tìm thấy công việc',
      });
    }

    return res.status(200).json({
      message: 'Cập nhật công việc thành công',
      task,
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
    const { status } = req.body;

    const validStatuses = [
      'todo',
      'in_progress',
      'completed',
    ];

    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        message: 'Trạng thái không hợp lệ',
      });
    }

    const task = await Task.findOneAndUpdate(
      {
        _id: req.params.id,
        createdBy: userId,
      },
      { status },
      {
        new: true,
        runValidators: true,
      }
    );

    if (!task) {
      return res.status(404).json({
        message: 'Không tìm thấy công việc',
      });
    }

    return res.status(200).json({
      message: 'Cập nhật trạng thái thành công',
      task,
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

    const task = await Task.findOneAndDelete({
      _id: req.params.id,
      createdBy: userId,
    });

    if (!task) {
      return res.status(404).json({
        message: 'Không tìm thấy công việc',
      });
    }

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
