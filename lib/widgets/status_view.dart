// หน้าสถานะการเชื่อมต่อที่ใช้ซ้ำได้ พร้อมปุ่มลองใหม่และการกระทำเสริม

import 'package:flutter/material.dart';

/// แสดงสาเหตุและทางเลือกเมื่อข้อมูลยังไม่พร้อม เช่น ลองเชื่อมต่อใหม่หรือเข้าโหมดทดลอง
class StatusView extends StatelessWidget {
  const StatusView({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
    this.secondaryAction,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;
  final Widget? secondaryAction;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_outlined, size: 48),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                if (onRetry != null)
                  FilledButton(
                    onPressed: onRetry,
                    child: const Text('ลองอีกครั้ง'),
                  ),
                if (secondaryAction != null) ...[
                  const SizedBox(height: 12),
                  secondaryAction!,
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
