const Task = require('../models/task.model');

// Hàm lấy User ID an toàn từ mọi trường hợp đặt tên Token
const getUserId = (req) => {
  const data = req.userData || req.user || {};
  return data.userId || data.id || data._id;
};

// 1. Lấy danh sách công việc
exports.getTasks = async (req, res) => {
  try {
    const userId = getUserId(req);
    const tasks = await Task.find({ user: userId }).sort({ createdAt: -1 });
    console.log(`[GET TASKS] User ID: ${userId} | Số lượng task: ${tasks.length}`);
    return res.status(200).json(tasks);
  } catch (error) {
    console.error('Lỗi Get Tasks:', error);
    return res.status(500).json({ message: 'Lỗi khi lấy danh sách công việc' });
  }
};

// 2. Tạo công việc mới
exports.createTask = async (req, res) => {
  try {
    const { title, description } = req.body;
    if (!title) {
      return res.status(400).json({ message: 'Vui lòng nhập tên công việc' });
    }

    const userId = getUserId(req);
    const task = await Task.create({
      user: userId,
      title,
      description
    });
    console.log(`[CREATE TASK] Đã tạo thành công cho User ID: ${userId} | Task ID: ${task._id}`);
    return res.status(201).json({ message: 'Tạo công việc thành công', task });
  } catch (error) {
    console.error('Lỗi Create Task:', error);
    return res.status(500).json({ message: 'Lỗi khi tạo công việc' });
  }
};

// 3. Cập nhật công việc
exports.updateTask = async (req, res) => {
  try {
    const userId = getUserId(req);
    const task = await Task.findOneAndUpdate(
      { _id: req.params.id, user: userId },
      req.body,
      { new: true }
    );
    if (!task) {
      return res.status(404).json({ message: 'Không tìm thấy công việc' });
    }
    return res.status(200).json({ message: 'Cập nhật thành công', task });
  } catch (error) {
    return res.status(500).json({ message: 'Lỗi khi cập nhật công việc' });
  }
};

// 4. Xóa công việc
exports.deleteTask = async (req, res) => {
  try {
    const userId = getUserId(req);
    const task = await Task.findOneAndDelete({ _id: req.params.id, user: userId });
    if (!task) {
      return res.status(404).json({ message: 'Không tìm thấy công việc' });
    }
    return res.status(200).json({ message: 'Xóa công việc thành công' });
  } catch (error) {
    return res.status(500).json({ message: 'Lỗi khi xóa công việc' });
  }
};