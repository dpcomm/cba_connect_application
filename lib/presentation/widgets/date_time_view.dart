import 'package:flutter/material.dart';

class DateTimeView extends StatelessWidget {
  final String destination;
  final TextEditingController dateController;
  final TextEditingController hourController;
  final TextEditingController minuteController;

  const DateTimeView({
    super.key,
    required this.destination,
    required this.dateController,
    required this.hourController,
    required this.minuteController,
  });

  InputDecoration getDecoration(String hint) {
    final bool isHome = destination == 'home';

    OutlineInputBorder outline = OutlineInputBorder(
      borderSide: BorderSide(color: Colors.grey.shade400),
      borderRadius: BorderRadius.circular(14),
    );

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey),
      filled: true,
      fillColor: Colors.white,
      border: outline,
      enabledBorder: outline,
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFF7F19FB), width: 1.8),
        borderRadius: BorderRadius.circular(14),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isHome = destination == 'home';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 날짜 / 시간 제목
        Row(
          children: const [
            Expanded(
              child: Text('날짜', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            SizedBox(width: 24),
            Expanded(
              child: Text('시간', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 날짜 / 시간 영역
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 날짜 영역
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  // 이미 입력된 텍스트가 있으면 파싱, 없으면 현재 시각
                  final initial = DateTime.tryParse(dateController.text) ?? DateTime.now();
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: initial,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    dateController.text =
                    '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                  }
                },
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: dateController,
                    decoration: getDecoration('날짜 입력 / 캘린더 연동'),
                    validator: (v) => (v == null || v.isEmpty) ? '날짜를 선택하세요' : null,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),

            // 시간 영역
            Expanded(
              child: Row(
                children: [
                  // 시 입력란
                  Expanded(
                    child: TextFormField(
                      controller: hourController,
                      keyboardType: TextInputType.number,
                      decoration: getDecoration('00'),
                      readOnly: false,
                      style: TextStyle(color: null),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '시',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 분 입력란
                  Expanded(
                    child: TextFormField(
                      controller: minuteController,
                      keyboardType: TextInputType.number,
                      decoration: getDecoration('00'),
                      readOnly: false,
                      style: TextStyle(color:  null),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '분',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '※ 시간은 24시 기준으로 입력해주세요.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
      ],
    );
  }
}