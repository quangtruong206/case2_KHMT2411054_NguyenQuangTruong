const express = require('express');
const router = express.Router();

const taskController = require('../controllers/task.controller');
const authMiddleware = require('../middlewares/auth.middleware');

router.use(authMiddleware);

// Danh sách và tạo công việc
router.get('/', taskController.getTasks);
router.post('/', taskController.createTask);

// Phân công
router.put('/:id/assignees', taskController.assignUsers);

// Chia sẻ và quản lý quyền
router.get('/:id/shares', taskController.getTaskShares);
router.post('/:id/shares', taskController.shareTask);
router.patch('/:id/shares/:userId', taskController.updateSharePermission);
router.delete('/:id/shares/:userId', taskController.removeTaskShare);

// Chi tiết và thao tác công việc
router.get('/:id', taskController.getTaskById);
router.put('/:id', taskController.updateTask);
router.patch('/:id/status', taskController.updateTaskStatus);
router.delete('/:id', taskController.deleteTask);

module.exports = router;