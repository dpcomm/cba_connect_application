import 'package:cba_connect_application/presentation/login/login_view_model.dart';
import 'package:cba_connect_application/presentation/main/pages/home/carpool_edit_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kakao_map_native/kakao_map_native_view.dart';
import 'package:cba_connect_application/presentation/main/pages/home/address_search_view.dart';
import 'package:cba_connect_application/presentation/main/pages/home/registration_view_model.dart'; 
import 'package:cba_connect_application/presentation/widgets/date_time_view.dart';
import 'package:cba_connect_application/repositories/carpool_repository.dart'; // CarpoolRoom, UpdateCarpoolInfoDto 필요
import 'package:cba_connect_application/models/carpool_room.dart';
import 'package:cba_connect_application/dto/update_carpool_info_dto.dart';
import 'package:cba_connect_application/core/color.dart';

class CarpoolEditView extends ConsumerStatefulWidget {
  final int carpoolId; // 수정할 카풀의 ID
  final String destinationType; // 'retreat' 또는 'home'

  const CarpoolEditView({
    super.key,
    required this.carpoolId,
    required this.destinationType, // 기존 destination을 destinationType으로 명확하게 변경
  });

  @override
  ConsumerState<CarpoolEditView> createState() => _CarpoolEditViewState();
}

class _CarpoolEditViewState extends ConsumerState<CarpoolEditView> {
  final _formKey = GlobalKey<FormState>();
  final _carInfoCtrl = TextEditingController(); // 차량 정보
  final _originCtrl = TextEditingController(); // 출발지 주소 (비활성화)
  final _destinationCtrl = TextEditingController(); // 도착지 주소 (비활성화)
  final _originDetailedCtrl = TextEditingController(); // 출발지 상세 주소 (수정 가능)
  final _destinationDetailedCtrl = TextEditingController(); // 도착지 상세 주소 (수정 가능)
  final _noteCtrl = TextEditingController(); // 메모 (수정 가능)

  // 날짜/시간 컨트롤러
  final _dateController = TextEditingController();
  final _hourController = TextEditingController();
  final _minuteController = TextEditingController();

  // 위도 경도는 수정 불가능하므로 초기값만 사용
  double? _originLat, _originLng;
  double? _destLat, _destLng;
  int _capacity = 1; // 인원 (비활성화)

  final GlobalKey<KakaoMapNativeViewState> _mapKey = GlobalKey();

  CarpoolRoom? _currentCarpool; // 현재 수정할 카풀 정보를 저장

  @override
  void initState() {
    super.initState();
    _loadCarpoolData();
  }

  Future<void> _loadCarpoolData() async {
    try {
      final CarpoolRepository carpoolRepository = ref.read(carpoolRepositoryProvider);
      final CarpoolRoom? carpool = await carpoolRepository.getCarpoolById(widget.carpoolId);

      if (carpool != null) {
        setState(() {
          _currentCarpool = carpool;
          _carInfoCtrl.text = carpool.carInfo;
          _capacity = carpool.seatsTotal;
          _noteCtrl.text = carpool.note;

          // 날짜/시간 설정
          _dateController.text = DateFormat('yyyy-MM-dd').format(carpool.departureTime);
          _hourController.text = carpool.departureTime.hour.toString().padLeft(2, '0');
          _minuteController.text = carpool.departureTime.minute.toString().padLeft(2, '0');

          // 출발지/도착지 주소 설정 (비활성화 필드)
          _originCtrl.text = carpool.origin;
          _destinationCtrl.text = carpool.destination;

          // 상세 주소 설정 (수정 가능 필드)
          _originDetailedCtrl.text = carpool.originDetailed;
          _destinationDetailedCtrl.text = carpool.destinationDetailed;

          // 위도 경도 설정 (지도 초기 위치용, 수정 불가)
          _originLat = carpool.originLat;
          _originLng = carpool.originLng;
          _destLat = carpool.destLat;
          _destLng = carpool.destLng;

          // 지도 초기 위치 설정
          // widget.destinationType에 따라 지도의 중심을 어디로 할지 결정
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (widget.destinationType == 'retreat' && _originLat != null && _originLng != null) {
              _mapKey.currentState?.moveCamera(latitude: _originLat!, longitude: _originLng!);
            } else if (widget.destinationType == 'home' && _destLat != null && _destLng != null) {
              _mapKey.currentState?.moveCamera(latitude: _destLat!, longitude: _destLng!);
            }
          });
        });
      } else {
        throw Exception('카풀 정보를 찾을 수 없습니다.');
      }
    } catch (e) {
      print('카풀 정보 로딩 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
          content: Text(
            '카풀 정보를 불러오는데 실패했습니다.',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _carInfoCtrl.dispose();
    _originCtrl.dispose();
    _destinationCtrl.dispose();
    _originDetailedCtrl.dispose();
    _destinationDetailedCtrl.dispose();
    _noteCtrl.dispose();
    _dateController.dispose();
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final loginState = ref.watch(loginViewModelProvider); // 드라이버 ID는 변경 불가하므로 사용 안 함

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: const BackButton(),
        title: const Text(
          '카풀 수정',
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ListView(
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '내 차 정보 (차종/색깔/번호)',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  _buildInputField(
                    controller: _carInfoCtrl,
                    hint: '(셀토스/흰색/00가0000)',
                    enabled: true, // 차량 정보는 수정 가능
                  ),
                  const SizedBox(height: 20),

                  // 수용 가능한 인원 - 비활성화
                  const Text(
                    '수용 가능한 인원',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.grey.shade200, // 비활성화 시 배경색
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // - 버튼 (비활성화)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400, // 비활성화된 색상
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(14),
                              bottomLeft: Radius.circular(14),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          child: const Icon(
                            Icons.remove,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),

                        // 가운데 숫자
                        Text(
                          '$_capacity',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.normal, color: Colors.black54),
                        ),

                        // + 버튼 (비활성화)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400, // 비활성화된 색상
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(14),
                              bottomRight: Radius.circular(14),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 날짜 및 시간 (수정 가능)
                  DateTimeView(
                    destination: widget.destinationType, // destinationType 사용
                    dateController: _dateController,
                    hourController: _hourController,
                    minuteController: _minuteController,
                  ),
                  const SizedBox(height: 20),

                  // 출발지 (주소 고정, 비활성화)
                  const Text(
                    '출발지 (픽업위치)',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  _buildInputField(
                    controller: _originCtrl,
                    hint: '', // 힌트 필요없음 (데이터로 채워지므로)
                    enabled: false, // 주소는 수정 불가
                  ),
                  const SizedBox(height: 20),

                  // 도착지 (주소 고정, 비활성화)
                  const Text(
                    '도착지',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  _buildInputField(
                    controller: _destinationCtrl,
                    hint: '', // 힌트 필요없음 (데이터로 채워지므로)
                    enabled: false, // 주소는 수정 불가
                  ),
                  const SizedBox(height: 20),

                  Container(
                    width: double.infinity,
                    height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[200],
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final w = constraints.maxWidth;
                        final h = constraints.maxHeight;
                        double mapLat = 37.5047862285253; // 기본값
                        double mapLng = 126.902051702019; // 기본값

                        // destinationType에 따라 지도의 중심을 다르게 설정
                        if (widget.destinationType == 'retreat' && _originLat != null && _originLng != null) {
                          mapLat = _originLat!;
                          mapLng = _originLng!;
                        } else if (widget.destinationType == 'home' && _destLat != null && _destLng != null) {
                          mapLat = _destLat!;
                          mapLng = _destLng!;
                        }

                        return KakaoMapNativeView(
                          key: _mapKey,
                          width: w,
                          height: h,
                          latitude: mapLat,
                          longitude: mapLng,
                          zoomLevel: 17,
                          mapType: 'map',
                          overlay: 'hill_shading',
                        );
                      }
                    )
                  ),

                  const SizedBox(height: 40),

                  // 상세 주소 (출발지 또는 도착지 상세)
                  Row(
                    children: [
                      Text(
                        widget.destinationType == 'retreat' ? '출발지 상세 주소' : '도착지 상세 주소',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '*카풀리스트에 표시될 위치를 입력하세요',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _buildInputField(
                    controller: widget.destinationType == 'retreat' ? _originDetailedCtrl : _destinationDetailedCtrl,
                    hint: '신도림역 1번 출구 앞',
                    enabled: true, // 상세 주소는 수정 가능
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    '메모',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  _buildInputField(
                      controller: _noteCtrl,
                      hint: '시간 엄수, 도착하면 전화주세요 등',
                      enabled: true, // 메모는 수정 가능
                  ),
                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          if (_currentCarpool == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                backgroundColor: Colors.red,
                                padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                                content: Text(
                                  '카풀 정보를 불러오지 못하여 수정할 수 없습니다.',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            );
                            return;
                          }

                          String message;

                          // 출발 시간
                          final hour = int.tryParse(_hourController.text) ?? 0;
                          final minute = int.tryParse(_minuteController.text) ?? 0;
                          final date = DateFormat('yyyy-MM-dd').parse(_dateController.text);
                          final departureTime = DateTime.utc(
                            date.year,
                            date.month,
                            date.day,
                            hour,
                            minute,
                          );

                          // 상세 주소 결정
                          String? finalOriginDetailed = null;
                          String? finalDestinationDetailed = null;

                          if (widget.destinationType == 'retreat') {
                            finalOriginDetailed = _originDetailedCtrl.text;
                            finalDestinationDetailed = _currentCarpool!.destinationDetailed; // 기존 도착지 상세 유지
                          } else { // 'home'
                            finalOriginDetailed = _currentCarpool!.originDetailed; // 기존 출발지 상세 유지
                            finalDestinationDetailed = _destinationDetailedCtrl.text;
                          }

                          final updatedDto = UpdateCarpoolInfoDto(
                            carpoolId: _currentCarpool!.id,
                            carInfo: _carInfoCtrl.text,
                            departureTime: departureTime,
                            originDetailed: finalOriginDetailed,
                            destinationDetailed: finalDestinationDetailed,
                            note: _noteCtrl.text,
                          );

                          // 카풀 정보 업데이트 API 호출
                          try {
                            await ref.read(carpoolEditViewModelProvider.notifier).editCarpool(updatedDto);
                            final state = ref.read(carpoolEditViewModelProvider);
                            if (state.status == CarpoolEditStatus.success) {
                              message = '카풀 수정이 완료되었습니다.';
                              Navigator.pop(context, true);
                            } else {
                              message = '카풀 수정에 실패하였습니다.';
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: const Color(0xFF7F19FB),
                                padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                                content: Text(
                                  message,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            );
                          } catch (e) {
                            // API 호출 중 예외 발생 시
                            message = '카풀 수정 중 오류가 발생했습니다: $e';
                            print('카풀 수정 오류: $e'); // 디버깅을 위한 로그 출력
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: Colors.red, // 오류 발생 시 빨간색 스낵바
                                padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                                content: Text(
                                  message,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: secondaryColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32)),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Text(
                        '수정하기',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 비활성화 가능하도록 enabled 파라미터 추가
  Widget _buildInputField({
    TextEditingController? controller,
    String? hint,
    bool readOnly = false,
    VoidCallback? onTap,
    bool enabled = true, // 기본값 true로 설정
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      enabled: enabled,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: enabled ? Colors.black38 : Colors.black54), // 비활성화 시 힌트 색상 변경
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(14),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(14),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: secondaryColor, width: 1.8,),
          borderRadius: BorderRadius.circular(14),
        ),
        // 비활성화 시 배경색
        filled: !enabled,
        fillColor: !enabled ? Colors.grey.shade200 : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: (v) =>
      (enabled && (v == null || v.isEmpty)) ? '값을 입력해 주세요' : null, // 활성화된 필드에만 유효성 검사
    );
  }
}