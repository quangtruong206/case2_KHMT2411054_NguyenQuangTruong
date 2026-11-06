
const User = require('../models/user.model');
const bcrypt = require('bcryptjs');

exports.register = async (req, res) => {
  try {
    const fullName = String(
      req.body?.fullName || ''
    ).trim();

    const email = String(
      req.body?.email || ''
    ).trim().toLowerCase();

    const password = String(
      req.body?.password || ''
    );

    // Kiểm tra họ tên
    if (!fullName) {
      return res.status(400).json({
        message: 'Vui lòng nhập họ tên'
      });
    }

    // Kiểm tra email
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

    if (!emailRegex.test(email)) {
      return res.status(400).json({
        message: 'Email không hợp lệ'
      });
    }

    // Kiểm tra mật khẩu
    if (password.length < 8) {
      return res.status(400).json({
        message: 'Mật khẩu phải có ít nhất 8 ký tự'
      });
    }

    // Kiểm tra email đã tồn tại
    const existingUser = await User.findOne({
      email
    });

    if (existingUser) {
      return res.status(409).json({
        message: 'Email đã được đăng ký'
      });
    }

    // Băm mật khẩu
    const passwordHash = await bcrypt.hash(
      password,
      12
    );

    // Tạo tài khoản
    const user = await User.create({
      fullName,
      email,
      passwordHash
    });

    // Trả kết quả không bao gồm mật khẩu
    return res.status(201).json({
      message: 'Đăng ký tài khoản thành công',

      user: {
        id: user._id,
        fullName: user.fullName,
        email: user.email,
        createdAt: user.createdAt
      }
    });

  } catch (error) {
    console.error('REGISTER ERROR:', error);

    if (error.code === 11000) {
      return res.status(409).json({
        message: 'Email đã được đăng ký'
      });
    }

    return res.status(500).json({
      message: 'Lỗi máy chủ khi đăng ký tài khoản'
    });
  }
};
