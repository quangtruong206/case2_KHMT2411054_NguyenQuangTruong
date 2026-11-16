const express = require('express');
const router = express.Router();

const statisticsController = require('../controllers/statistics.controller');
const authMiddleware = require('../middlewares/auth.middleware');

// Yêu cầu đăng nhập
router.use(authMiddleware);

// Thống kê theo trạng thái
router.get('/tasks', statisticsController.getTaskStatistics);

// Thống kê công việc được giao và đang phụ trách
router.get('/assignments', statisticsController.getAssignmentStatistics);

// Thống kê công việc sắp đến hạn và quá hạn
router.get('/deadlines', statisticsController.getDeadlineStatistics);

module.exports = router;