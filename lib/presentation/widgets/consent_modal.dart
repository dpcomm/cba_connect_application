import 'package:flutter/material.dart';

class ConsentModal extends StatelessWidget {
  final VoidCallback onConfirm;

  const ConsentModal({Key? key, required this.onConfirm}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 24),
          // Icon
          Icon(
            Icons.error_outline,
            size: 48,
            color: theme.primaryColor,
          ),
          const SizedBox(height: 16),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              '앱에서 사용하는 권한 및 동의를 안내드립니다.',
              style: theme.textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildItem(
                  title: '푸시 알림 권한',
                  required: true,
                  description: '채팅 알림을 받기 위해 필요합니다.',
                  theme: theme,
                ),
                const SizedBox(height: 12),
                _buildItem(
                  title: '로그 수집 동의',
                  required: true,
                  description: '채팅 기록 및 활동 로그를 저장하여 신고 기능 및 이용자 수를 받기 위해 필요합니다.',
                  theme: theme,
                ),
                const SizedBox(height: 12),
                _buildItem(
                  title: '개인정보 수집·제공 동의',
                  required: true,
                  description: '서비스 이용을 위해 이름, 연락처 등 개인정보를 수집·이용·제공합니다.',
                  theme: theme,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),

          // Confirm button
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onConfirm,
              style: TextButton.styleFrom(
                backgroundColor: theme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                ),
              ),
              child: Text(
                '확인했어요',
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem({
    required String title,
    required bool required,
    required String description,
    required ThemeData theme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ', style: TextStyle(fontSize: 20)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium!
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    required ? '(필수)' : '(선택)',
                    style: theme.textTheme.bodySmall!
                        .copyWith(color: required ? Colors.red : Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
