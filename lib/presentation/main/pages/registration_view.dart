import 'package:flutter/material.dart';

class RegistrationView extends StatefulWidget {
  final String destination;

  const RegistrationView({super.key, required this.destination});

  @override
  State<RegistrationView> createState() => _RegistrationViewState();
}

class _RegistrationViewState extends State<RegistrationView> {
  final _formKey = GlobalKey<FormState>();
  int _capacity = 1;

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
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
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
                    '이름',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  _buildInputField(hint: '이름을 입력하세요'),
                  const SizedBox(height: 20),

                  const Text(
                    '내 차 정보',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  _buildInputField(hint: '차종 / 색깔 / 번호를 입력하세요'),
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
                    '만날 장소 (지하철 역, 큰 건물)',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  _buildInputField(hint: 'ex) 신도림역 2번 출구 앞'),
                  const SizedBox(height: 20),

                  const Text(
                    '연락처',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  _buildInputField(hint: '010-0000-0000'),
                  const SizedBox(height: 20),

                  const Text(
                    '메모',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  _buildInputField(hint: '시간 엄수, 도착하면 전화주세요 등'),
                  const SizedBox(height: 30),

                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_on,
                              size: 40, color:const Color(0xFF7F19FB)),
                          SizedBox(height: 8),
                          Text(
                            '픽업 장소 선택',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '(맴버들에게는 클릭한 위치로 보여집니다.)',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final message = '[${widget.destination}으로] 카풀 등록이 완료되었습니다.';

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

  Widget _buildInputField({String? hint}) {
    return TextFormField(
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.black38),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '값을 입력해 주세요';
        }
        return null;
      },
    );
  }
}