import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CompanyPicker {
  // static 함수로 만들면 클래스 인스턴스 생성 없이 바로 호출 가능합니다.
  static Future<String?> show(BuildContext context) async {
    return await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: const Text(
                  "업장 선택",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 2),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  // 'company' 컬렉션에서 ㄱ~ㅎ 순으로 정렬
                  stream: FirebaseFirestore.instance
                      .collection('company')
                      .orderBy('name', descending: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError)
                      return const Text("데이터를 불러올 수 없습니다.");
                    if (!snapshot.hasData)
                      return const Center(child: CircularProgressIndicator());

                    final docs = snapshot.data!.docs;

                    if (docs.isEmpty)
                      return const Center(child: Text("등록된 업장이 없습니다."));

                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final String name = (data['name'] ?? "")
                            .toString()
                            .trim();

                        return ListTile(
                          title: Text(
                            name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onTap: () {
                            // [핵심] 선택한 이름을 'pop'할 때 인자로 넘겨줌
                            Navigator.pop(
                              context,
                              name.trim(),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
