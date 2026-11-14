const User = require('../models/user.model');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

// 1. ĐĂNG KÝ
exports.register = async (req, res) => {
  try {
    const { fullName, name, email, password } = req.body;
    const displayName = fullName || name;

    if (!displayName || !email || !password) {
      return res.status(400).json({ message: 'Vui lòng điền đầy đủ thông tin' });
    }

    const existingUser = await User.findOne({ email: email.toLowerCase() });
    if (existingUser) {
      return res.status(400).json({ message: 'Email đã được đăng ký' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const user = await User.create({
      fullName: displayName,
      name: displayName,
      email: email.toLowerCase(),
      passwordHash: hashedPassword,
    });

    return res.status(201).json({ message: 'Đăng ký thành công!', user: { id: user._id, email: user.email } });
  } catch (error) {
    return res.status(500).json({ message: 'Lỗi server khi đăng ký' });
  }
};

// 2. ĐĂNG NHẬP
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ message: 'Vui lòng nhập email và mật khẩu' });
    }

    const user = await User.findOne({ email: email.toLowerCase() });
    if (!user) {
      return res.status(400).json({ message: 'Email hoặc mật khẩu không đúng' });
    }

    const isMatch = await bcrypt.compare(password, user.passwordHash);
    if (!isMatch) {
      return res.status(400).json({ message: 'Email hoặc mật khẩu không đúng' });
    }

    const token = jwt.sign(
      { userId: user._id, email: user.email },
      process.env.JWT_SECRET || 'supersecretkey',
      { expiresIn: '7d' }
    );

    return res.status(200).json({ message: 'Đăng nhập thành công!', token });
  } catch (error) {
    return res.status(500).json({ message: 'Lỗi server khi đăng nhập' });
  }
};

// 3. XEM PROFILE
exports.getProfile = async (req, res) => {
  try {
    const user = await User.findById(req.userData.userId).select('-passwordHash');
    if (!user) return res.status(404).json({ message: 'Không tìm thấy tài khoản' });
    return res.status(200).json(user);
  } catch (error) {
    return res.status(500).json({ message: 'Lỗi khi lấy thông tin người dùng' });
  }
};

// 4. CẬP NHẬT PROFILE
exports.updateProfile = async (req, res) => {
  try {
    const fullName = String(req.body.fullName || '').trim();
    const email = String(req.body.email || '').trim().toLowerCase();

    if (!fullName || !email) {
      return res.status(400).json({ message: 'Vui lòng điền đầy đủ Họ tên và Email' });
    }

    const updatedUser = await User.findByIdAndUpdate(
      req.userData.userId,
      { fullName, name: fullName, email },
      { new: true }
    ).select('-passwordHash');
return res.status(200).json({ message: 'Cập nhật thông tin thành công', user: updatedUser });
  } catch (error) {
    return res.status(500).json({ message: 'Lỗi khi cập nhật thông tin' });
  }
};

// 5. ĐỔI MẬT KHẨU
exports.changePassword = async (req, res) => {
  try {
    const { oldPassword, newPassword } = req.body;

    if (!oldPassword || !newPassword) {
      return res.status(400).json({ message: 'Vui lòng nhập mật khẩu cũ và mật khẩu mới' });
    }
    if (newPassword.length < 6) {
      return res.status(400).json({ message: 'Mật khẩu mới phải từ 6 ký tự trở lên' });
    }

    const user = await User.findById(req.userData.userId);
    const isMatch = await bcrypt.compare(oldPassword, user.passwordHash);
    if (!isMatch) {
      return res.status(400).json({ message: 'Mật khẩu cũ không chính xác' });
    }

    user.passwordHash = await bcrypt.hash(newPassword, 10);
    await user.save();

    return res.status(200).json({ message: 'Đổi mật khẩu thành công!' });
  } catch (error) {
    return res.status(500).json({ message: 'Lỗi khi đổi mật khẩu' });
  }
};
