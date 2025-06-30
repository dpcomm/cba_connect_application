import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cba_connect_application/presentation/main/pages/setting//setting_view_model.dart';
import 'package:cba_connect_application/core/color.dart';
import 'package:flutter/services.dart';

class SettingView extends ConsumerStatefulWidget{
  const SettingView({super.key});

  @override
  ConsumerState<SettingView> createState() => _SettingViewState();
}

class _SettingViewState extends ConsumerState<SettingView> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    
    final settingViewModel = ref.watch(settingViewModelProvider.notifier);
    final settingState = ref.watch(settingViewModelProvider);

    const Color activeTextColor = text900Color;
    const Color inactiveTextColor = text700Color;
    const Color editButtonColor = grayColor;
    const Color editingButtonColor = secondaryColor;

    // 각 필드의 TextField와 수정 버튼을 감싸는 위젯을 생성하는 헬퍼 함수
    Widget _buildEditableField({
      required String label,
      required TextEditingController controller,
      required bool isEditing,
      required VoidCallback onToggleEdit,
      TextInputType keyboardType = TextInputType.text,
      String hintText = '', // 힌트 텍스트 추가
      List<TextInputFormatter>? inputFormatters,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: text900Color,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: isEditing, // isEditing 상태에 따라 활성화/비활성화
                  keyboardType: keyboardType,
                  style: TextStyle(
                    fontSize: 18,
                    color: isEditing ? activeTextColor : inactiveTextColor, // 수정 모드에 따라 색상 변경
                    fontWeight: FontWeight.w500, // 텍스트 굵기 조정
                  ),
                  inputFormatters: inputFormatters,
                  decoration: InputDecoration(
                    hintText: hintText, // 힌트 텍스트 설정
                    hintStyle: TextStyle(color: inactiveTextColor.withOpacity(0.6)), // 힌트 텍스트 색상
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                        color: isEditing ? activeTextColor : inactiveTextColor,
                        width: 1.0,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: isEditing ? Colors.grey[400]! : Colors.grey[200]!, // 비활성화 시 연하게
                        width: 1.0,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: secondaryColor, // 활성화 시 강조
                        width: 1.0,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // 수정 버튼
              TextButton(
                onPressed: onToggleEdit,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: Colors.white,
                      width: 1,
                    ),
                  ),
                ),
                child: Text(
                  isEditing ? '저장' : '수정', // 버튼 텍스트 변경
                  style: TextStyle(
                    color: isEditing ? editingButtonColor : editButtonColor, // 버튼 색상 변경
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(
            color: Colors.grey[400],
            thickness: 1.0,
            height: 1, 
            indent: 0, 
            endIndent: 0, 
          ), 
          const SizedBox(height: 16),
        ],
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 16, // 좌측 여백
        title: Row(
          mainAxisSize: MainAxisSize.min, // Row의 크기를 자식 위젯에 맞게 최소화
          children: [
            Icon(Icons.settings),
            SizedBox(width: 8), // 아이콘과 텍스트 사이 간격
            Text(
              '설정',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '내 정보 수정',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 30),

            // 이름 수정 필드
            _buildEditableField(
              label: '이름',
              controller: settingViewModel.userNameController,
              isEditing: settingState.isEditingName,
              onToggleEdit: () => settingViewModel.toggleNameEditMode(context),
              hintText: '이름을 입력해주세요',
            ),

            // 전화번호 수정 필드
            _buildEditableField(
              label: '전화번호',
              controller: settingViewModel.phoneController,
              isEditing: settingState.isEditingPhone,
              onToggleEdit: () => settingViewModel.togglePhoneEditMode(context),
              keyboardType: TextInputType.phone,
              hintText: '전화번호를 입력해주세요',
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly, // 숫자만 입력 받도록
                LengthLimitingTextInputFormatter(11), // 최대 11자리 제한
                PhoneInputFormatter(), // 커스텀 포맷터 적용
              ],
            ),

            // 차 정보 수정 필드
            _buildEditableField(
              label: '차 정보',
              controller: settingViewModel.carInfoController,
              isEditing: settingState.isEditingCarInfo,
              onToggleEdit: () => settingViewModel.toggleCarInfoEditMode(context),
              hintText: '차종/색깔/번호',
            ),

            // 알림 설정 토글 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'PUSH 알림 설정',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: IconButton(
                    onPressed: () => settingViewModel.toggleFcmEnabled(),
                    icon: Icon(
                      settingState.fcmEnabled
                          ? Icons.notifications
                          : Icons.notifications_off,
                      color: settingState.fcmEnabled ? secondaryColor : Colors.grey,
                      size: 28,
                    ),
                    tooltip: settingState.fcmEnabled ? '알림 끄기' : '알림 켜기',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(
              color: Colors.grey[400],
              thickness: 1.0,
              height: 1,
              indent: 0,
              endIndent: 0,
            ),
            const SizedBox(height: 40),

            // 로그아웃 버튼
            Center(
              child: TextButton(
                onPressed: () => settingViewModel.handleLogout(context),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
                child: const Text('로그아웃'),
              ),
            ),
            const SizedBox(height: 12),

            // 계정삭제 버튼
            Center(
              child: TextButton(
                onPressed: () => settingViewModel.handleDeleteUser(context),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
                child: const Text('계정 삭제'),
              ),
            ),
          ],
        ),
      ),  
    );
  }
}

