
const User = require('../models/user.model');

exports.searchUsers = async (req, res) => {
  try {
    const keyword = (req.query.q || '').trim();

    if (keyword.length < 2) {
      return res.status(200).json([]);
    }

    const escaped = keyword.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const regex = new RegExp(escaped, 'i');

    const users = await User.find({
      $or: [
        { fullName: regex },
        { name: regex },
        { email: regex },
      ],
    })
      .select('_id fullName name email')
      .limit(20)
      .lean();

    return res.status(200).json(users);
  } catch (error) {
    console.error('Lỗi tìm kiếm người dùng:', error);
    return res.status(500).json({
      message: 'Không thể tìm kiếm người dùng',
    });
  }
};
