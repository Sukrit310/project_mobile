// ฟอร์มตั้ง/แก้ไขวงเงินของเดือนเดียว ตรวจค่าและรอผลบันทึกก่อนปิดกล่องข้อความ
import 'dart:async';

import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../models/budget_model.dart';
import '../services/budget_repository.dart';
import '../utils/date_formatter.dart';
import '../utils/transaction_validation.dart';

/// รับ repository ผ่านพารามิเตอร์ จึงใช้ฟอร์มเดียวกันกับ Firebase และโหมดตัวอย่าง
class BudgetEditorDialog extends StatefulWidget {
  const BudgetEditorDialog({
    super.key,
    required this.month,
    required this.repository,
    this.initialBudget,
  });

  final DateTime month;
  final BudgetRepository repository;
  final BudgetModel? initialBudget;

  @override
  State<BudgetEditorDialog> createState() => _BudgetEditorDialogState();
}

class _BudgetEditorDialogState extends State<BudgetEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final amount = widget.initialBudget?.limitSatang ?? 0;
    // ประกอบข้อความจากจำนวนเต็มโดยตรง เช่น 1001 สตางค์เป็น 10.01 บาท
    _amountController = TextEditingController(
      text: amount > 0
          ? '${amount ~/ 100}.${(amount % 100).toString().padLeft(2, '0')}'
          : '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  /// ใช้เดือนของฟอร์มเดิมตลอดการบันทึก การลองซ้ำจึงอ้างอิงเอกสารเดือนเดิม
  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final budget = BudgetModel(
      month: widget.month,
      limitSatang: parseBahtToSatang(_amountController.text)!,
    );
    // จำ dialog route ที่เริ่มคำสั่งไว้ เพราะอาจมี route ใหม่เปิดทับระหว่างรอเครือข่าย
    final dialogRoute = ModalRoute.of<bool>(context)!;
    final navigator = Navigator.of(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.saveBudget(budget);
      if (!mounted || !dialogRoute.isActive) return;
      if (dialogRoute.isCurrent) {
        navigator.pop(true);
      } else {
        // ปิดเฉพาะ dialog เดิม โดยเก็บหน้าที่เปิดทับไว้ให้ผู้ใช้ดูต่อ
        navigator.removeRoute<bool>(dialogRoute, true);
      }
    } on TimeoutException {
      _showError(
        'ยังยืนยันการบันทึกไม่ได้ งบประมาณอาจถูกบันทึกแล้ว ตรวจสอบการเชื่อมต่อและข้อมูลล่าสุดก่อนลองอีกครั้ง',
      );
    } catch (_) {
      _showError(
        'บันทึกงบประมาณไม่สำเร็จ ตรวจสอบการเชื่อมต่อและสิทธิ์ แล้วลองอีกครั้ง',
      );
    }
  }

  void _showError(String message) {
    // ผลลัพธ์อาจกลับมาหลังหน้าจอถูกถอดออก จึงตรวจ mounted ก่อนเปลี่ยน state
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = message;
    });
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      scrollable: true,
      // ผูกเดือนกับสัญลักษณ์ปฏิทิน เพื่อสื่อขอบเขตวงเงินโดยไม่เพิ่มหัวข้อซ้ำ
      icon: const Icon(Icons.account_balance_wallet_outlined),
      iconColor: AppColors.primary,
      title: Text(
        (widget.initialBudget?.limitSatang ?? 0) > 0
            ? 'แก้ไขงบประมาณ'
            : 'ตั้งงบประมาณ',
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.mintSurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.calendar_month_outlined, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      formatThaiMonth(widget.month),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              key: const Key('budget-amount'),
              controller: _amountController,
              enabled: !_saving,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'วงเงิน (บาท)',
                hintText: 'เช่น 5000.00',
                errorMaxLines: 4,
              ),
              validator: validateTransactionAmount,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 12),
            const Text(
              'กรอกจำนวนเงินมากกว่า 0 ทศนิยมไม่เกิน 2 ตำแหน่ง โดยไม่ใส่จุลภาค',
              style: TextStyle(color: AppColors.muted, fontSize: 14),
            ),
            if (_saving) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(
                semanticsLabel: 'กำลังบันทึกงบประมาณ',
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Semantics(
                liveRegion: true,
                // ข้อผิดพลาดใช้พื้นสีอ่อน โดยไม่รบกวนค่าที่ผู้ใช้กรอกไว้
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.expenseSurface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.expense),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('ยกเลิก'),
        ),
        FilledButton(
          key: const Key('budget-save'),
          onPressed: _saving ? null : _save,
          child: const Text('บันทึกงบประมาณ'),
        ),
      ],
    ),
  );
}
