const mongoose = require('mongoose');
const Notification = require('../models/notification.model');

// Lấy ID người dùng đang đăng nhập
const getUserId = (req) => {
  return req.userData?.userId || req.user?.userId || req.user?._id;
};

// Lấy danh sách thông báo
exports.getNotifications = async (req, res) => {
  try {
    const userId = getUserId(req);

    const notifications = await Notification.find({
      recipient: userId,
    })
      .populate('sender', 'fullName name email')
      .sort({ createdAt: -1 })
      .limit(100);

    return res.status(200).json({
      message: 'Lấy danh sách thông báo thành công',
      notifications,
    });
  } catch (error) {
    console.error('Get notifications error:', error);
    return res.status(500).json({
      message: 'Không thể lấy danh sách thông báo',
    });
  }
};

// Đếm số thông báo chưa đọc
exports.getUnreadCount = async (req, res) => {
  try {
    const userId = getUserId(req);

    const count = await Notification.countDocuments({
      recipient: userId,
      isRead: false,
    });

    return res.status(200).json({ unreadCount: count });
  } catch (error) {
    console.error('Get unread count error:', error);
    return res.status(500).json({
      message: 'Không thể đếm thông báo chưa đọc',
    });
  }
};

// Đánh dấu một thông báo đã đọc
exports.markAsRead = async (req, res) => {
  try {
    const userId = getUserId(req);
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ message: 'ID thông báo không hợp lệ' });
    }

    const notification = await Notification.findOneAndUpdate(
      { _id: id, recipient: userId },
      { isRead: true },
      { new: true }
    );

    if (!notification) {
      return res.status(404).json({
        message: 'Không tìm thấy thông báo',
      });
    }

    return res.status(200).json({
      message: 'Đã đánh dấu thông báo đã đọc',
      notification,
    });
  } catch (error) {
    console.error('Mark notification as read error:', error);
    return res.status(500).json({
      message: 'Không thể cập nhật thông báo',
    });
  }
};

// Đánh dấu tất cả thông báo đã đọc
exports.markAllAsRead = async (req, res) => {
  try {
    const userId = getUserId(req);

    const result = await Notification.updateMany(
      { recipient: userId, isRead: false },
      { $set: { isRead: true } }
    );

    return res.status(200).json({
      message: 'Đã đánh dấu tất cả thông báo đã đọc',
      modifiedCount: result.modifiedCount,
    });
  } catch (error) {
    console.error('Mark all notifications as read error:', error);
    return res.status(500).json({
      message: 'Không thể cập nhật thông báo',
    });
  }
};

// Xóa một thông báo
exports.deleteNotification = async (req, res) => {
  try {
    const userId = getUserId(req);
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ message: 'ID thông báo không hợp lệ' });
    }

    const notification = await Notification.findOneAndDelete({
      _id: id,
      recipient: userId,
    });

    if (!notification) {
      return res.status(404).json({
        message: 'Không tìm thấy thông báo',
      });
    }

    return res.status(200).json({
      message: 'Xóa thông báo thành công',
    });
  } catch (error) {
    console.error('Delete notification error:', error);
    return res.status(500).json({
      message: 'Không thể xóa thông báo',
    });
  }
};