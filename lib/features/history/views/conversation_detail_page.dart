import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/history_controller.dart';

class ConversationDetailPage extends GetView<HistoryController> {
  const ConversationDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل المحادثة'),
      ),
      body: const Center(
        child: Text('تفاصيل المحادثة'),
      ),
    );
  }
}
