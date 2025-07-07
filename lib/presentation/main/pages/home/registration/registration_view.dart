import 'package:cba_connect_application/presentation/login/login_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kakao_map_native/kakao_map_native_view.dart';
import 'package:cba_connect_application/dto/create_carpool_dto.dart';
import 'package:cba_connect_application/presentation/main/pages/home/address_search/address_search_view.dart';
import 'package:cba_connect_application/presentation/main/pages/home/registration/registration_view_model.dart';
import 'package:cba_connect_application/presentation/widgets/date_time_view.dart';
import 'package:cba_connect_application/repositories/carpool_repository.dart';
import 'package:cba_connect_application/presentation/main/pages/setting//setting_view_model.dart';

class RegistrationView extends ConsumerStatefulWidget {
  final String destination;
  const RegistrationView({super.key, required this.destination});

  @override
  ConsumerState<RegistrationView> createState() => _RegistrationViewState();
}

class _RegistrationViewState extends ConsumerState<RegistrationView> {
  final _formKey = GlobalKey<FormState>();
  final _carInfoCtrl      = TextEditingController(); // 차량 정보
  final _addressCtrl      = TextEditingController(); // 만날 장소
  final _detailAddressCtrl= TextEditingController(); // 상세 주소
  final _noteCtrl         = TextEditingController(); // 메모

  // 날짜/시간 컨트롤러 추가
  final destination   = TextEditingController();
  final _dateController   = TextEditingController();
  final _hourController   = TextEditingController();
  final _minuteController = TextEditingController();

  double? _lat, _lng; // 위도 경도
  int _capacity = 1; // 인원

  final GlobalKey<KakaoMapNativeViewState> _mapKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      final settingViewModel = ref.read(settingViewModelProvider.notifier);
      final defaultCarInfo = settingViewModel.carInfoController.text;
      if (defaultCarInfo.isNotEmpty) {
        _carInfoCtrl.text = defaultCarInfo;
        // 필요시 setState(() {}); // UI 반영 문제 시 사용
      }
    });
  }

  @override
  void dispose() {
    _carInfoCtrl.dispose();
    _addressCtrl.dispose();
    _detailAddressCtrl.dispose();
    _noteCtrl.dispose();
    // 지도 해제 플러그인 작성해야함.
    // _mapKey.dispose();

    _dateController.dispose(); //날짜/시간 컨트롤러
    _hourController.dispose(); //날짜/시간 컨트롤러
    _minuteController.dispose(); //날짜/시간 컨트롤러

    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginViewModelProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: const BackButton(),
        title: const Text(
          '카풀 등록',
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
                    hint: '셀토스/흰색/00가0000'
                  ),
                  const SizedBox(height: 20),

                  //수용 가능한 인원
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
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [

                        // - 버튼 (왼쪽 둥근 모서리)
                        InkWell(
                          onTap: () {
                            if (_capacity > 1) setState(() => _capacity--);
                          },
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black,
                              border: Border.all(color: Colors.black),
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
                        ),

                        // 가운데 숫자
                        Text(
                          '$_capacity',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
                        ),

                        // + 버튼 (오른쪽 둥근 모서리)
                        InkWell(
                          onTap: () {
                            setState(() => _capacity++);
                          },
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black,
                              border: Border.all(color: Colors.black),
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
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  //날짜 및 시간
                  DateTimeView(
                    destination: widget.destination,
                    dateController: _dateController,
                    hourController: _hourController,
                    minuteController: _minuteController,
                  ),
                  const SizedBox(height: 20),


                  //출발지
                  const Text(
                    '출발지 (픽업위치)',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 6),

                    // 수련회장으로
                    if (widget.destination == 'retreat')
                      _buildInputFieldWithIcon(
                        controller: _addressCtrl,
                        hint: '서울특별시 영등포구 도림로 307',
                        readOnly: true,
                        onTap: () async {
                          final result = await showAddressSearchBottomSheet(context);
                          if (result != null) {
                            setState(() {
                              _addressCtrl.text = result.address;
                              _lat = result.lat;
                              _lng = result.lng;
                            });
                            _mapKey.currentState?.moveCamera(latitude: result.lat, longitude: result.lng);
                          }
                        },
                      )

                    // 집으로
                    else
                      TextFormField(
                        initialValue: '경기도 양주시 광적면 현석로 313-44', // 수련회장 주소
                        enabled: false,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade400,
                          hintStyle: TextStyle(color: Colors.white),
                          suffixIcon: Icon(Icons.search, color: Colors.white),
                          disabledBorder: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                        ),
                        style: TextStyle(color: Colors.white),
                      ),
                    const SizedBox(height: 20),

                  //도착지
                  const Text(
                    '도착지',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 6),

                    //수련회장으로
                    if (widget.destination == 'retreat')
                      TextFormField(
                        initialValue: '경기도 양주시 광적면 현석로 313-44', // 수련회장 주소
                        enabled: false,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade400,
                          hintStyle: TextStyle(color: Colors.white),
                          disabledBorder: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                        ),
                        style: TextStyle(color: Colors.white),
                      )

                    //집으로
                    else
                      _buildInputFieldWithIcon(
                        controller: _addressCtrl,
                        hint: '서울특별시 영등포구 도림로 307',
                        readOnly: true,
                        onTap: () async {
                          final result = await showAddressSearchBottomSheet(context);
                          if (result != null) {
                            setState(() {
                              _addressCtrl.text = result.address;
                              _lat = result.lat;
                              _lng = result.lng;
                            });
                            _mapKey.currentState?.moveCamera(latitude: result.lat, longitude: result.lng);
                          }
                        },
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
                            return KakaoMapNativeView(
                              key: _mapKey,
                              width: w,
                              height: h,
                              latitude: 37.5047862285253,
                              longitude: 126.902051702019,
                              zoomLevel: 17,
                              mapType: 'map',
                              overlay: 'hill_shading',
                            );
                          }
                      )
                  ),

                  const SizedBox(height: 40),

                  Row(
                    children: const [
                      Text(
                        '상세 주소',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
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
                    controller: _detailAddressCtrl,
                    hint: '신도림역 1번 출구 앞',
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
                      maxLines: 3,
                  ),
                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {

                          final settingViewModel = ref.read(settingViewModelProvider.notifier);
                          await settingViewModel.saveCarInfo(_carInfoCtrl.text, context, showSnackBar: false);

                          final hour   = int.tryParse(_hourController.text) ?? 0;
                          final minute = int.tryParse(_minuteController.text) ?? 0;
                          final date = DateFormat('yyyy-MM-dd').parse(_dateController.text);

                          final departureTime = DateTime.utc(
                            date.year, date.month, date.day,
                            hour, minute,
                          );

                          String origin, detailedOrigin, destination;
                          double originLat, originLng, destLat, destLng;

                          const String RETREAT_ADDRESS = '경기도 양주시 광적면 현석로 313-44';
                          const double RETREAT_LAT = 37.833038818526134;
                          const double RETREAT_LNG = 126.94192401531457;

                          if (widget.destination == 'retreat') {
                            origin = _addressCtrl.text;
                            detailedOrigin = _detailAddressCtrl.text;
                            originLat = _lat!;
                            originLng = _lng!;
                            destination = RETREAT_ADDRESS;
                            destLat = RETREAT_LAT;
                            destLng = RETREAT_LNG;
                          } else {
                            origin = RETREAT_ADDRESS;
                            detailedOrigin = '';
                            originLat = RETREAT_LAT;
                            originLng = RETREAT_LNG;
                            destination = _addressCtrl.text;
                            destLat = _lat!;
                            destLng = _lng!;
                          }

                          final dto = CreateCarpoolDto(
                            driverId: loginState.user!.id,
                            carInfo: _carInfoCtrl.text,
                            departureTime: departureTime,
                            origin: origin,
                            originDetailed: detailedOrigin,
                            destination: destination,
                            seatsTotal: _capacity,
                            note: _noteCtrl.text,
                            originLat: originLat,
                            originLng: originLng,
                            destLat: destLat,
                            destLng: destLng,
                          );

                          await ref.read(registrationViewModelProvider.notifier).createCarpool(dto);
                          final state = ref.read(registrationViewModelProvider);
                          final message = state.status == RegistrationStatus.success
                              ? '카풀 등록이 완료되었습니다.'
                              : '카풀 등록에 실패하였습니다.';

                          if (state.status == RegistrationStatus.success) {
                            Navigator.pop(context);
                          }

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF7F19FB),
                              padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                              content: Text(message, style: const TextStyle(fontSize: 16)),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7F19FB),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32)),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Text(
                        '등록하기',
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

  Widget _buildInputField({
    TextEditingController? controller,
    String? hint,
    bool readOnly = false,
    VoidCallback? onTap,
    int? maxLines,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: maxLines ?? 1,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade400), // 기본 border
          borderRadius: BorderRadius.circular(14),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade400), // 평상시
          borderRadius: BorderRadius.circular(14),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF7F19FB), width: 1.8,), // 포커스 시
          borderRadius: BorderRadius.circular(14),
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: (v) =>
      (v == null || v.isEmpty) ? '값을 입력해 주세요' : null,
    );
  }
}

Widget _buildInputFieldWithIcon({
  TextEditingController? controller,
  String? hint,
  bool readOnly = false,
  VoidCallback? onTap,
  Icon? suffixIcon,
}) {
  return TextFormField(
    controller: controller,
    readOnly: readOnly,
    onTap: onTap,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black38),
      border: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(14),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(14),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF7F19FB), width: 1.8,),
        borderRadius: BorderRadius.circular(14),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      suffixIcon: Icon(Icons.search, color: Colors.grey),
    ),
    validator: (v) => (v == null || v.isEmpty) ? '값을 입력해 주세요' : null,
  );
}