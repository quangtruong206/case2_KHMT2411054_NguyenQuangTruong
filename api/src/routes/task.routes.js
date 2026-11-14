
const express = require('express');
const router = express.Router();

const taskController = require('../controllers/task.controller');
const authMiddleware = require('../middlewares/auth.middleware');

// Tất cả API công việc đều yêu cầu đăng nhập
router.use(authMiddleware);

router.get('/', taskController.getTasks);
router.post('/', taskController.createTask);

router.get('/:id', taskController.getTaskById);
router.put('/:id', taskController.updateTask);
router.patch('/:id/status', taskController.updateTaskStatus);
router.delete('/:id', taskController.deleteTask);

module.exports = router;
