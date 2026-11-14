
const jwt = require('jsonwebtoken');

module.exports = (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader) {
      return res.status(401).json({
        message: 'Chưa đăng nhập hoặc thiếu token'
      });
    }

    const token = authHeader.split(' ')[1];

    if (!token) {
      return res.status(401).json({
        message: 'Token không hợp lệ'
      });
    }

    const decodedToken = jwt.verify(
      token,
      process.env.JWT_SECRET || 'supersecretkey'
    );

    req.userData = decodedToken;
    req.user = decodedToken;

    next();

  } catch (error) {
    console.log('Lỗi xác thực JWT:', error.message);

    return res.status(401).json({
      message: 'Token không hợp lệ hoặc đã hết hạn'
    });
  }
};
