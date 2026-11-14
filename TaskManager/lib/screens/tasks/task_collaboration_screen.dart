
import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../services/task_service.dart';

class TaskCollaborationScreen extends StatefulWidget {
  final Task task;

  const TaskCollaborationScreen({
    super.key,
    required this.task,
  });

  @override
  State<TaskCollaborationScreen> createState() =>
      _TaskCollaborationScreenState();
}

class _TaskCollaborationScreenState
    extends State<TaskCollaborationScreen> {
  final TaskService _service = TaskService();
  final TextEditingController _searchController =
  TextEditingController();

  late List<TaskUser> _assignees;
  String? _primaryAssigneeId;

  List<TaskUser> _searchResults = [];
  List<TaskShare> _shares = [];

  String _permission = 'viewer';
  String? _selectedShareUserId;

  bool _loading = false;
  bool _searching = false;

  bool get _isOwner => widget.task.role == 'owner';

  Color get _primary => Theme.of(context).colorScheme.primary;
  Color get _surface => Theme.of(context).colorScheme.surface;
  Color get _textColor => Theme.of(context).colorScheme.onSurface;
  Color get _mutedColor =>
      Theme.of(context).colorScheme.onSurfaceVariant;

  @override
  void initState() {
    super.initState();

    _assignees = List<TaskUser>.from(widget.task.assignees);
    _primaryAssigneeId = widget.task.primaryAssignee?.id;

    _loadShares();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadShares() async {
    try {
      final result = await _service.getTaskShares(widget.task.id);

      if (!mounted) return;

      setState(() {
        _shares = result;
      });
    } catch (e) {
      if (!mounted) return;
      _showMessage('Không thể tải danh sách chia sẻ: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _searchUsers() async {
    final keyword = _searchController.text.trim();

    if (keyword.length < 2) {
      _showMessage('Nhập ít nhất 2 ký tự để tìm kiếm');
      return;
    }

    setState(() {
      _searching = true;
    });

    try {
      final results = await _service.searchUsers(keyword);

      if (!mounted) return;

      final excludedIds = {
        if (widget.task.creator != null)
          widget.task.creator!.id,
        ..._assignees.map((e) => e.id),
        ..._shares.map((e) => e.userId),
      };

      setState(() {
        _searchResults = results
            .where((user) =>
        user.id.isNotEmpty &&
            !excludedIds.contains(user.id))
            .toList();
        _selectedShareUserId = null;
      });

      if (_searchResults.isEmpty) {
        _showMessage('Không tìm thấy người dùng phù hợp');
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Tìm kiếm thất bại: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _searching = false;
        });
      }
    }
  }

  Future<void> _saveAssignees() async {
    if (_primaryAssigneeId != null &&
        !_assignees.any(
              (user) => user.id == _primaryAssigneeId,
        )) {
      _showMessage(
        'Người phụ trách chính phải nằm trong danh sách phân công',
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await _service.assignUsers(
        widget.task.id,
        _assignees.map((e) => e.id).toList(),
        _primaryAssigneeId,
      );

      if (!mounted) return;

      _showMessage('Đã cập nhật phân công công việc');
    } catch (e) {
      if (mounted) {
        _showMessage('Phân công thất bại: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _shareTask() async {
    if (_selectedShareUserId == null) {
      _showMessage('Hãy chọn người cần chia sẻ');
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await _service.shareTask(
        widget.task.id,
        _selectedShareUserId!,
        _permission,
      );

      _searchController.clear();

      if (!mounted) return;

      setState(() {
        _searchResults = [];
        _selectedShareUserId = null;
      });

      await _loadShares();

      if (mounted) {
        _showMessage('Đã chia sẻ công việc thành công');
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Chia sẻ thất bại: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _changePermission(
      TaskShare share,
      String permission,
      ) async {
    try {
      await _service.updateSharePermission(
        widget.task.id,
        share.userId,
        permission,
      );

      await _loadShares();

      if (mounted) {
        _showMessage('Đã cập nhật quyền chia sẻ');
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Không thể cập nhật quyền: $e');
      }
    }
  }

  Future<void> _removeShare(TaskShare share) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Thu hồi chia sẻ'),
        content: Text(
          'Bạn có chắc muốn thu hồi quyền truy cập của '
              '${share.user.fullName.isEmpty ? share.user.email : share.user.fullName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Thu hồi'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.removeTaskShare(
        widget.task.id,
        share.userId,
      );

      await _loadShares();

      if (mounted) {
        _showMessage('Đã thu hồi quyền chia sẻ');
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Thu hồi thất bại: $e');
      }
    }
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: _primary, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionCard({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _userTile(
      TaskUser user, {
        required Widget trailing,
      }) {
    final displayName =
    user.fullName.isNotEmpty ? user.fullName : user.email;

    final initial =
    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: _primary.withValues(alpha: 0.13),
            child: Text(
              initial,
              style: TextStyle(
                color: _primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _mutedColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }

  Widget _buildTaskHeader() {
    final creator = widget.task.creator;
    final creatorName = creator == null
        ? 'Không rõ'
        : creator.fullName.isNotEmpty
        ? creator.fullName
        : creator.email;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            _primary,
            const Color(0xFF3978E8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.groups_rounded,
                color: Colors.white,
                size: 23,
              ),
              const SizedBox(width: 8),
              const Text(
                'KHÔNG GIAN CỘNG TÁC',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.task.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.person_outline,
                color: Colors.white70,
                size: 17,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Người tạo: $creatorName',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _headerStat(
                Icons.people_outline,
                '${_assignees.length}',
                'Phân công',
              ),
              const SizedBox(width: 22),
              _headerStat(
                Icons.share_outlined,
                '${_shares.length}',
                'Đã chia sẻ',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerStat(
      IconData icon,
      String value,
      String label,
      ) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 19),
        const SizedBox(width: 6),
        Text(
          '$value $label',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAssigneesCard() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'Người được phân công',
            Icons.people_alt_outlined,
          ),
          const SizedBox(height: 14),
          if (_assignees.isEmpty)
            _emptyState(
              Icons.person_off_outlined,
              'Chưa có người được phân công',
            ),
          ..._assignees.map((user) {
            return _userTile(
              user,
              trailing: _isOwner
                  ? IconButton(
                tooltip: 'Bỏ phân công',
                onPressed: () {
                  setState(() {
                    _assignees.removeWhere(
                          (e) => e.id == user.id,
                    );

                    if (_primaryAssigneeId == user.id) {
                      _primaryAssigneeId = null;
                    }
                  });
                },
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.redAccent,
                ),
              )
                  : const SizedBox.shrink(),
            );
          }),
          if (_isOwner) ...[
            const Divider(height: 28),
            const Text(
              'Người phụ trách chính',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _primaryAssigneeId,
              isExpanded: true,
              decoration: const InputDecoration(
                hintText: 'Chọn người phụ trách chính',
                prefixIcon: Icon(Icons.star_outline),
              ),
              items: _assignees.map((user) {
                return DropdownMenuItem(
                  value: user.id,
                  child: Text(
                    user.fullName.isNotEmpty
                        ? user.fullName
                        : user.email,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _primaryAssigneeId = value;
                });
              },
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _loading ? null : _saveAssignees,
                icon: _loading
                    ? const SizedBox(
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(Icons.save_outlined),
                label: const Text('Lưu phân công'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchCard() {
    if (!_isOwner) return const SizedBox.shrink();

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'Chia sẻ công việc',
            Icons.share_outlined,
          ),
          const SizedBox(height: 8),
          Text(
            'Tìm kiếm thành viên bằng tên hoặc địa chỉ email.',
            style: TextStyle(
              color: _mutedColor,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            onSubmitted: (_) => _searchUsers(),
            decoration: InputDecoration(
              hintText: 'Nhập tên hoặc email...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                tooltip: 'Tìm kiếm',
                onPressed: _searching ? null : _searchUsers,
                icon: const Icon(Icons.arrow_forward_rounded),
              ),
            ),
          ),
          if (_searching) ...[
            const SizedBox(height: 16),
            const Center(
              child: CircularProgressIndicator(),
            ),
          ],
          if (_searchResults.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Kết quả tìm kiếm',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),

    ..._searchResults.map((user) {
    final name = user.fullName.isNotEmpty
    ? user.fullName
        : user.email;

    final alreadyAssigned =
    _assignees.any((e) => e.id == user.id);

    return RadioListTile<String>(
    contentPadding: EdgeInsets.zero,
    value: user.id,
    groupValue: _selectedShareUserId,
    activeColor: _primary,
    title: Text(
    name,
    style: const TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 14,
    ),
    ),
    subtitle: Text(
    user.email,
    style: TextStyle(
    color: _mutedColor,
    fontSize: 12,
    ),
    ),
    secondary: IconButton(
    tooltip: alreadyAssigned
    ? 'Đã được phân công'
        : 'Thêm vào phân công',
    onPressed: alreadyAssigned
    ? null
        : () {
    setState(() {
    _assignees.add(user);
    });

    _showMessage(
    'Đã thêm $name vào danh sách phân công. Hãy lưu phân công.',
    );
    },
    icon: Icon(
    alreadyAssigned
    ? Icons.check_circle
        : Icons.person_add_alt_1,
    color: alreadyAssigned
    ? Colors.green
        : _primary,
    ),
    ),
    onChanged: (value) {
    setState(() {
    _selectedShareUserId = value;
    });
    },
    );
    }),

    if (_selectedShareUserId != null) ...[
            const Divider(height: 24),
            const Text(
              'Thiết lập quyền truy cập',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _permission,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.security_outlined),
                labelText: 'Quyền truy cập',
              ),
              items: const [
                DropdownMenuItem(
                  value: 'viewer',
                  child: Text('Viewer - Chỉ xem'),
                ),
                DropdownMenuItem(
                  value: 'editor',
                  child: Text('Editor - Được chỉnh sửa'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _permission = value;
                  });
                }
              },
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _loading ? null : _shareTask,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Chia sẻ công việc'),
              ),
            ),
          ],
        ],
     ]),
    );
  }

  Widget _buildSharesCard() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'Danh sách người được chia sẻ',
            Icons.supervisor_account_outlined,
          ),
          const SizedBox(height: 12),
          if (_shares.isEmpty)
            _emptyState(
              Icons.share_outlined,
              'Chưa chia sẻ công việc với ai',
            ),
          ..._shares.map((share) {
            return Column(
              children: [
                _userTile(
                  share.user,
                  trailing: _isOwner
                      ? SizedBox(
                    width: 116,
                    child: DropdownButtonFormField<String>(
                      initialValue: share.permission,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'viewer',
                          child: Text(
                            'Viewer',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'editor',
                          child: Text(
                            'Editor',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null &&
                            value != share.permission) {
                          _changePermission(share, value);
                        }
                      },
                    ),
                  )
                      : _permissionChip(share.permission),
                ),
                if (_isOwner)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _removeShare(share),
                      icon: const Icon(
                        Icons.person_remove_outlined,
                        size: 18,
                        color: Colors.redAccent,
                      ),
                      label: const Text(
                        'Thu hồi quyền',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                const Divider(height: 12),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _permissionChip(String permission) {
    final isEditor = permission == 'editor';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: (isEditor ? Colors.orange : Colors.blue)
            .withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isEditor ? 'Editor' : 'Viewer',
        style: TextStyle(
          color: isEditor ? Colors.orange : Colors.blue,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _emptyState(IconData icon, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(
            icon,
            size: 32,
            color: _mutedColor.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _mutedColor,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Phân công & chia sẻ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          _buildTaskHeader(),
          const SizedBox(height: 18),
          _buildAssigneesCard(),
          const SizedBox(height: 18),
          _buildSearchCard(),
          const SizedBox(height: 18),
          _buildSharesCard(),
        ],
      ),
    );
  }
}
