const express = require('express');
const router = express.Router();

const notificationController = require('../controllers/notification.controller');
const authMiddleware = require('../middlewares/auth.middleware');

router.use(authMiddleware);

// Danh sách thông báo
router.get('/', notificationController.getNotifications);

// Số thông báo chưa đọc
router.get('/unread-count', notificationController.getUnreadCount);

// Đánh dấu tất cả đã đọc
router.patch('/read-all', notificationController.markAllAsRead);

// Đánh dấu một thông báo đã đọc
router.patch('/:id/read', notificationController.markAsRead);

// Xóa thông báo
router.delete('/:id', notificationController.deleteNotification);

module.exports = router;