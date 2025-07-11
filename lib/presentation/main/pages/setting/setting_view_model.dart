import 'package:cba_connect_application/core/color.dart';
import 'package:cba_connect_application/main.dart';
import 'package:cba_connect_application/presentation/login/login_view_model.dart';
import 'package:cba_connect_application/repositories/fcm_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:cba_connect_application/repositories/user_repository.dart';
import 'package:cba_connect_application/datasources/user_data_source.dart';
import 'package:cba_connect_application/core/custom_exception.dart';
import 'package:cba_connect_application/dto/update_user_dto.dart';
import 'package:cba_connect_application/core/secure_storage.dart';
import 'package:cba_connect_application/core/provider.dart';
import 'package:cba_connect_application/dto/delete_fcm_token_dto.dart';
import 'package:cba_connect_application/dto/regist_fcm_dto.dart';


enum SettingStatus { initial, loading, success, error }

class SettingState {
  final SettingStatus status;
  final String? message;
  final bool isEditingName;
  final bool isEditingPhone;
  final bool isEditingCarInfo;
  final bool fcmEnabled;
  final String currentCarInfo;

  const SettingState({
    this.status = SettingStatus.initial,
    this.message,
    this.isEditingName = false,
    this.isEditingPhone = false,
    this.isEditingCarInfo = false,
    this.fcmEnabled = true, // 기본값 : 수신 상태
    this.currentCarInfo = '',
  });

  // 상태를 복사하여 새로운 상태를 생성하는 헬퍼 메서드
  SettingState copyWith({
    SettingStatus? status,
    String? message,
    bool? isEditingName,
    bool? isEditingPhone,
    bool? isEditingCarInfo,
    bool? fcmEnabled,
    String? currentCarInfo,
  }) {
    return SettingState(
      status: status ?? this.status,
      message: message ?? this.message,
      isEditingName: isEditingName ?? this.isEditingName,
      isEditingPhone: isEditingPhone ?? this.isEditingPhone,
      isEditingCarInfo: isEditingCarInfo ?? this.isEditingCarInfo,
      fcmEnabled: fcmEnabled ?? this.fcmEnabled,
      currentCarInfo: currentCarInfo ?? this.currentCarInfo,
    );
  }
}

class SettingViewModel extends StateNotifier<SettingState> {
  final Ref _ref;
  final UserRepository _userRepository;
  late SharedPreferences _prefs;

  final TextEditingController userNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController carInfoController = TextEditingController();

  final bool _fcmEnabled = true; // 기본값 (옵션)
  bool get fcmEnabled => _fcmEnabled;

  // ViewModel 생성자에서 Ref를 주입받아 다른 Provider에 접근
  SettingViewModel(this._ref, this._userRepository) : super(const SettingState()) {
    _initializeUserSettings(); // ViewModel이 생성될 때 사용자 설정 정보를 초기화
  }

  // 사용자 정보 초기화
  void _initializeUserSettings() async {

    _prefs = await SharedPreferences.getInstance();

    // 1 & 2. 이름, 전화번호 <- 로그인 정보
    final loginState = _ref.read(loginViewModelProvider);
    if (loginState.user != null) {
      userNameController.text = loginState.user!.name;
      phoneController.text = loginState.user!.phone;
    } else {
      userNameController.text = '';
      phoneController.text = '';
    }

    // 3. 차 정보 <- SharedPreferences
    final String? carInfoString = _prefs.getString('car_info_${loginState.user?.id}');
    if (carInfoString != null && carInfoString.isNotEmpty) {
      carInfoController.text = carInfoString;
      state = state.copyWith(currentCarInfo: carInfoString);
    } else {
      carInfoController.text = '';
      state = state.copyWith(currentCarInfo: '');
    }

    // 4. FCM 설정 상태 불러오기 + 상태에 반영
    final fcm = await SecureStorage.read(key: 'notification-config-now');
    final fcmEnabled = fcm == null ? true : (fcm == 'on');
    state = state.copyWith(fcmEnabled: fcmEnabled);
  }

  /// 이름을 수정 모드로 토글하고, 수정 완료 시 이름 저장
  void toggleNameEditMode(BuildContext context) {
    if (state.isEditingName) {
      _saveName(userNameController.text, context);
    }
    state = state.copyWith(isEditingName: !state.isEditingName, status: SettingStatus.initial);
  }

  /// 전화번호를 수정 모드로 토글하고, 수정 완료 시 전화번호 저장
  void togglePhoneEditMode(BuildContext context) {
    if (state.isEditingPhone) {
      _savePhone(phoneController.text, context);
    }
    state = state.copyWith(isEditingPhone: !state.isEditingPhone, status: SettingStatus.initial);
  }

  /// 차 정보를 수정 모드로 토글하고, 수정 완료 시 차 정보 저장
  void toggleCarInfoEditMode(BuildContext context) {
    if (state.isEditingCarInfo) {
      saveCarInfo(carInfoController.text, context);
    }
    state = state.copyWith(isEditingCarInfo: !state.isEditingCarInfo, status: SettingStatus.initial);
  }

  /// FCM 알림 설정 토글하고, 설정을 SecureStorage에 저장
  Future<void> toggleFcmEnabled() async {
    final newValue = !state.fcmEnabled;
    state = state.copyWith(fcmEnabled: newValue);
    
    // SecureStorage에 저장
    final storageValue = newValue ? 'on' : 'off';
    await SecureStorage.write(key: 'notification-config', value: storageValue);

    final loginState = _ref.read(loginViewModelProvider);
    final userId = loginState.user?.id;

    final repository = _ref.read(fcmRepositoryProvider);    
    final token = await SecureStorage.read(key: 'firebase-token');

    
    if (storageValue == 'on') {
      if (token != null) { await repository.registToken(RegistFcmDto(userId: userId!, token: token, platform: "ios")); }      
    } else if (storageValue == 'off') {
      if (token != null) { await repository.deleteToken(DeleteFcmTokenDto(token: token)); }
    }


  }

  /// 이름 저장
  Future<void> _saveName(String nameText, BuildContext context) async {

    final loginViewModelNotifier = _ref.read(loginViewModelProvider.notifier);
    final currentUserId = loginViewModelNotifier.state.user?.id;
    
    if (currentUserId == null) {
      state = state.copyWith(status: SettingStatus.error, message: '사용자 정보를 찾을 수 없습니다.');
      _showErrorDialog(context, state.message!);
      return;
    }

    final UpdateUserNamelDto dto = UpdateUserNamelDto(id: currentUserId, name: nameText);
    state = state.copyWith(status: SettingStatus.loading);

    try {
        await _userRepository.updateUserName(dto);
        loginViewModelNotifier.updateUserNameInState(dto.name); 

        state = state.copyWith(status: SettingStatus.success, message: '이름이 "${dto.name}"(으)로 수정되었습니다.');
        _showSnackBar(context, state.message!);
      } on NetworkException catch (e) {
        state = state.copyWith(status: SettingStatus.error, message: '네트워크 오류: ${e.message}');
        _showErrorDialog(context, state.message!);
      } on CustomException catch (e) { 
        state = state.copyWith(status: SettingStatus.error, message: e.message);
        _showErrorDialog(context, state.message!);
      } catch (e) { 
        state = state.copyWith(status: SettingStatus.error, message: '이름 저장 중 알 수 없는 오류가 발생했습니다: ${e.toString()}');
        print('이름 저장 중 오류 발생: $e');
        _showErrorDialog(context, state.message!);
      }
    }

  /// 전화번호 저장
  Future<void> _savePhone(String phoneText, BuildContext context) async {

    final loginViewModelNotifier = _ref.read(loginViewModelProvider.notifier);
    final currentUserId = loginViewModelNotifier.state.user?.id;
    
    if (currentUserId == null) {
      state = state.copyWith(status: SettingStatus.error, message: '사용자 정보를 찾을 수 없습니다.');
      _showErrorDialog(context, state.message!);
      return;
    }

    // String cleanedPhone = phoneText.replaceAll('-', '');
    final UpdateUserPhoneDto dto = UpdateUserPhoneDto(id: currentUserId, phone: phoneText); // 기존 DB 데이터 형식에 맞춤(010-XXXX-XXXX)

    state = state.copyWith(status: SettingStatus.loading);

    try {
      await _userRepository.updateUserPhone(dto);
      loginViewModelNotifier.updateUserPhoneInState(dto.phone); 

      state = state.copyWith(status: SettingStatus.success, message: '전화번호가 "${dto.phone}"(으)로 수정되었습니다.');
      _showSnackBar(context, state.message!);
    } on NetworkException catch (e) {
      state = state.copyWith(status: SettingStatus.error, message: '네트워크 오류: ${e.message}');
      _showErrorDialog(context, state.message!);
    } on CustomException catch (e) {
      state = state.copyWith(status: SettingStatus.error, message: e.message);
      _showErrorDialog(context, state.message!);
    } catch (e) {
      state = state.copyWith(status: SettingStatus.error, message: '전화번호 저장 중 알 수 없는 오류가 발생했습니다: ${e.toString()}');
      print('전화번호 저장 중 오류 발생: $e');
      _showErrorDialog(context, state.message!);
    }
  }

  /// 차 정보를 저장하는 로직 (SharedPreferences에 String으로 저장)
  Future<void> saveCarInfo(String carInfoString, BuildContext context, {bool showSnackBar = true}) async {
    final loginState = _ref.read(loginViewModelProvider);
    print('차 정보 저장: $carInfoString');

    state = state.copyWith(status: SettingStatus.loading);

    try {
      await _prefs.setString('car_info_${loginState.user?.id}', carInfoString);
      state = state.copyWith(status: SettingStatus.success, message: '차 정보가 "${carInfoString}"(으)로 수정되었습니다.', currentCarInfo: carInfoString,);
      carInfoController.text = carInfoString;

      if (showSnackBar) {
        _showSnackBar(context, state.message!);
      }
    } on CustomException catch (e) {
      state = state.copyWith(status: SettingStatus.error, message: e.message);
      if (showSnackBar) {
        _showErrorDialog(context, state.message!);
      }
    } catch (e) {
      state = state.copyWith(status: SettingStatus.error, message: '차 정보 저장에 실패했습니다: ${e.toString()}');
      print('차 정보 저장 중 오류 발생: $e');
      if (showSnackBar) {
        _showErrorDialog(context, state.message!);
      }
    }
  }

  Future<void> handleLogout(BuildContext context, {bool showSnackBar = true}) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('아니오'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('예'),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    try {
      // _showSnackBar(context, '로그아웃 되었습니다.');
      await SecureStorage.delete(key: 'access-token');
      await SecureStorage.delete(key: 'refresh-token');

      AppRoot.resetProviders();

      Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
    } on CustomException catch (e) {
      state = state.copyWith(status: SettingStatus.error, message: e.message);
      if (showSnackBar) _showErrorDialog(context, state.message!);
    } catch (e) {
      state = state.copyWith(
        status: SettingStatus.error,
        message: '로그아웃 중 오류가 발생했습니다: ${e.toString()}',
      );
      if (showSnackBar) _showErrorDialog(context, state.message!);
    }
  }

  Future<void> handleDeleteUser(BuildContext context, {bool showSnackBar = true}) async {
    final shouldDeleteUser = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('계정 삭제'),
        content: const Text('정말 계정을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('아니오'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('예, 삭제합니다'),
          ),
        ],
      ),
    );

    if (shouldDeleteUser != true) return;

    try {
      state = state.copyWith(status: SettingStatus.loading);

      final loginViewModelNotifier = _ref.read(loginViewModelProvider.notifier);
      final currentUserId = loginViewModelNotifier.state.user?.id;

      if (currentUserId == null) {
        state = state.copyWith(status: SettingStatus.error, message: '로그인된 사용자 정보를 찾을 수 없어 계정을 삭제할 수 없습니다.');
        if (showSnackBar) _showErrorDialog(context, state.message!);
        return;
      }

      await _userRepository.deleteUser(currentUserId);

      await SecureStorage.delete(key: 'access-token');
      await SecureStorage.delete(key: 'refresh-token');
      await _prefs.remove('car_info_$currentUserId');

      AppRoot.resetProviders();

      Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);

      state = state.copyWith(status: SettingStatus.success);

    } on CustomException catch (e) {
      state = state.copyWith(status: SettingStatus.error, message: e.message);
      if (showSnackBar) _showErrorDialog(context, '계정 삭제 중 오류 발생: ${state.message!}');
    } catch (e) {
      state = state.copyWith(
        status: SettingStatus.error,
        message: '예상치 못한 오류로 계정 삭제에 실패했습니다: ${e.toString()}',
      );
      if (showSnackBar) _showErrorDialog(context, state.message!);
    }
  }

  // 성공 시 스낵바 표시 헬퍼 함수
  void _showSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: secondaryColor,
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
        content: Text(
          message,
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }

  // 에러 시 다이얼로그 표시 헬퍼 함수
  void _showErrorDialog(BuildContext context, String message) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('오류'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    userNameController.dispose();
    phoneController.dispose();
    carInfoController.dispose();
    super.dispose();
  }
}

class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    final cleanText = text.replaceAll(RegExp(r'[^0-9]'), ''); // 숫자만 남김

    // 최대 11자리 (010-XXXX-XXXX)
    if (cleanText.length > 11) {
      return oldValue;
    }

    final buffer = StringBuffer();
    for (int i = 0; i < cleanText.length; i++) {
      buffer.write(cleanText[i]);
      // 010-XXXX-XXXX 형식
      if (cleanText.length > 3 && i == 2 || cleanText.length > 7 && i == 6) {
        buffer.write('-');
      }
    }

    final formattedText = buffer.toString();
    return newValue.copyWith(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

final userDataSourceProvider = Provider<UserDataSource>(
      (ref) => UserDataSourceImpl(),
);

final userRepositoryProvider = Provider<UserRepository>(
      (ref) => UserRepositoryImpl(ref.read(userDataSourceProvider)),
);

final settingViewModelProvider = StateNotifierProvider<SettingViewModel, SettingState>(
  (ref) => SettingViewModel(ref, ref.read(userRepositoryProvider)),
);