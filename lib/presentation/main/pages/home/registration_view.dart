import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_map_native/kakao_map_native_view.dart';
import 'package:cba_connect_application/dto/create_carpool_dto.dart';
import 'package:cba_connect_application/presentation/main/pages/home/address_search_view.dart';
import 'package:cba_connect_application/presentation/main/pages/home/registration_view_model.dart';
import 'package:cba_connect_application/repositories/carpool_repository.dart';

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
  double? _lat, _lng; // 위도 경도
  int _capacity = 1; // 인원

  final GlobalKey<KakaoMapNativeViewState> _mapKey = GlobalKey();

  @override
  void dispose() {
    _carInfoCtrl.dispose();
    _addressCtrl.dispose();
    _detailAddressCtrl.dispose();
    _noteCtrl.dispose();
    // 지도 해제 플러그인 작성해야함.
    // _mapKey.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    '내 차 정보',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  _buildInputField(
                    controller: _carInfoCtrl,
                    hint: '차종 / 색깔 / 번호를 입력하세요'
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    '수용 가능한 인원',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
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
                              color: Colors.grey.shade400,
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                bottomLeft: Radius.circular(16),
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
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                              color: Colors.grey.shade400,
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(16),
                                bottomRight: Radius.circular(16),
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

                  const Text(
                    '주소 (만날 장소)',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  _buildInputField(
                    controller: _addressCtrl,
                    hint: 'ex) 서울특별시 영등포구 도림로 307',
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

                  const Text(
                    '상세 주소',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  _buildInputField(
                    controller: _detailAddressCtrl,
                    hint: 'ex) 복음관 앞'
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    '메모',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  _buildInputField(
                    controller: _noteCtrl,
                    hint: '시간 엄수, 도착하면 전화주세요 등'
                  ),
                  const SizedBox(height: 30),

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

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          if (!_formKey.currentState!.validate()) return;
                          String message;

                          const String RETREAT_ADDRESS = '경기도 양주시 광적면 현석로 313-44';
                          const double RETREAT_LAT = 37.833038818526134;
                          const double RETREAT_LNG = 126.94192401531457;

                          /** DB 수정을 origin_address, destination_address, */
                          /** detailed_origin, detailed_destination 4개로 정할 예정. */
                          /** 하단 요청부는 이후 수정. */
                          /** 만날 시간은 Datetime으로 지정해야 함.  */
                          String origin;
                          String detailedOrigin;
                          String destination;
                          double originLat, originLng;
                          double destinationLat, destinationLng;

                          // 집으로 가는 경우는 origin이 유저설정, originDetailed O, detailedOrigin X
                          if (widget.destination == 'retreat') {
                            origin = _addressCtrl.text;
                            detailedOrigin = _detailAddressCtrl.text;
                            originLat = _lat!;
                            originLng = _lng!;

                            destination = RETREAT_ADDRESS;
                            destinationLat = RETREAT_LAT;
                            destinationLng = RETREAT_LNG;
                          }
                          // 수련회장에 가는 경우에는 origin이 수련회장, originDetailed O, DetailedDestination X
                          else {
                            origin = RETREAT_ADDRESS;
                            detailedOrigin = "";
                            originLat = RETREAT_LAT;
                            originLng = RETREAT_LNG;

                            destination = _addressCtrl.text;
                            destinationLat = _lat!;
                            destinationLng = _lng!;
                          }

                          final dto = CreateCarpoolDto(
                            driverId: 1,
                            carInfo: _carInfoCtrl.text,
                            origin: origin,
                            originDetailed: detailedOrigin,
                            destination: destination,
                            seatsTotal: _capacity,
                            note: _noteCtrl.text,
                            originLat: originLat,
                            originLng: originLng,
                            destLat: destinationLat,
                            destLng: destinationLng
                          );

                          await ref.read(registrationViewModelProvider.notifier).createCarpool(dto);
                          final state = ref.read(registrationViewModelProvider);
                          if (state.status == RegistrationStatus.success) {
                            message = '카풀 등록이 완료되었습니다.';
                            Navigator.pop(context);
                          } else {
                            message = '카풀 등록에 실패하였습니다.';
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
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: (v) =>
      (v == null || v.isEmpty) ? '값을 입력해 주세요' : null,
    );
  }
}