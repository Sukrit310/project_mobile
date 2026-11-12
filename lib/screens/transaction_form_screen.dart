// ฟอร์มเพิ่มและแก้ไขรายการ: ตรวจข้อมูล รักษาความแม่นยำของเงิน และรอผลการบันทึก

import 'dart:async';

import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../models/money_transaction.dart';
import '../services/transaction_repository.dart';
import '../utils/categories.dart';
import '../utils/transaction_validation.dart';

/// รับ ID ที่จองไว้และ callback บันทึก จึงใช้ฟอร์มเดียวได้กับทั้งข้อมูลจริงและทดลอง
class TransactionFormScreen extends StatefulWidget {
  const TransactionFormScreen({
    super.key,
    required this.transactionId,
    required this.onSave,
    this.initialDate,
    this.initialTransaction,
    this.initialType = TransactionType.expense,
  });

  final String transactionId;
  final Future<void> Function(MoneyTransaction) onSave;
  final DateTime? initialDate;
  final MoneyTransaction? initialTransaction;
  final TransactionType initialType;

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

/// เก็บค่าฟอร์มไว้จนบันทึกสำเร็จ ทำให้ข้อผิดพลาดหรือลองใหม่ไม่ทำข้อมูลที่พิมพ์หาย
class _TransactionFormScreenState extends State<TransactionFormScreen> {
  // Form รวม validator ของชื่อและจำนวนเงิน ส่วน controller เก็บข้อความที่ผู้ใช้กำลังแก้
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  var _type = TransactionType.expense;
  var _category = TransactionCategory.food;
  late DateTime _date;
  var _saving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    final transaction = widget.initialTransaction;
    // โหมดแก้ไขเติมค่าที่บันทึกไว้ โดยแยกบาท/สตางค์ด้วยจำนวนเต็มและคงเวลารายการเดิม
    if (transaction != null) {
      _titleController.text = transaction.title;
      final satang = transaction.amountSatang;
      _amountController.text =
          '${satang ~/ 100}.${(satang % 100).toString().padLeft(2, '0')}';
      _type = transaction.type;
      _category = transaction.category;
      _date = transaction.date;
      return;
    }
    _type = widget.initialType;
    _category = categoriesForType(_type).first;
    final now = DateTime.now();
    final initial = widget.initialDate ?? now;
    final initialDay = DateUtils.dateOnly(initial);
    _date = initialDay.isAfter(DateUtils.dateOnly(now))
        ? _onCalendarDay(initial, now)
        : initialDay.isBefore(DateTime(1900))
        ? _onCalendarDay(initial, DateTime(1900))
        : initial;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  /// เปลี่ยนเฉพาะวันปฏิทิน โดยคงเวลา เศษวินาที และสถานะ UTC ของรายการ
  DateTime _onCalendarDay(DateTime time, DateTime day) {
    if (time.isUtc) {
      return DateTime.utc(
        day.year,
        day.month,
        day.day,
        time.hour,
        time.minute,
        time.second,
        time.millisecond,
        time.microsecond,
      );
    }
    return DateTime(
      day.year,
      day.month,
      day.day,
      time.hour,
      time.minute,
      time.second,
      time.millisecond,
      time.microsecond,
    );
  }

  /// จำกัดวันในตัวเลือกวันที่ แต่ไม่แก้วันเดิมหากผู้ใช้ยกเลิก โดยเฉพาะข้อมูลเก่านอกช่วง
  Future<void> _chooseDate() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    final today = DateUtils.dateOnly(DateTime.now());
    final firstDate = DateTime(1900);
    final currentDay = DateUtils.dateOnly(_date);
    final pickerDay = currentDay.isAfter(today)
        ? today
        : currentDay.isBefore(firstDate)
        ? firstDate
        : currentDay;
    final selected = await showDatePicker(
      context: context,
      initialDate: pickerDay,
      firstDate: firstDate,
      lastDate: today,
      helpText: 'เลือกวันที่ทำรายการ',
      cancelText: 'ยกเลิก',
      confirmText: 'เลือก',
    );
    // หลังปิด date picker ตรวจว่ายังมี State และยังไม่เริ่มบันทึกก่อนเปลี่ยนค่า
    if (selected == null || !mounted || _saving) return;
    setState(() => _date = _onCalendarDay(_date, selected));
  }

  /// ตรวจทุกช่องก่อนสร้างโมเดล และปิดการกดซ้ำจน callback ยืนยันผลหรือแจ้งข้อผิดพลาด
  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final transaction = MoneyTransaction(
      // ใช้ ID เดิมทั้งการแก้ไขและการลองใหม่ เพื่อไม่เพิ่มเอกสารซ้ำเมื่อเครือข่ายตอบช้า
      id: widget.initialTransaction?.id ?? widget.transactionId,
      title: _titleController.text.trim(),
      amountSatang: parseBahtToSatang(_amountController.text)!,
      type: _type,
      category: _category,
      date: _date,
    );
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      await widget.onSave(transaction);
      // งานอาจเสร็จหลังหน้าถูกปิดแล้ว จึงตรวจ mounted ก่อนแก้ UI หรือ pop route
      if (!mounted) return;
      setState(() => _saving = false);
      Navigator.of(context).pop(true);
    } on TransactionNotFoundException {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = 'ไม่พบรายการนี้แล้ว กรุณากลับไปตรวจสอบประวัติ';
      });
    } on TimeoutException {
      // timeout เป็นผลที่ยังยืนยันไม่ได้ จึงเก็บข้อมูลไว้ให้ลองซ้ำด้วย ID เดิม
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = 'ไม่สามารถยืนยันการบันทึกได้ กรุณาลองอีกครั้งโดยไม่ต้องเพิ่มรายการใหม่';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = 'บันทึกไม่สำเร็จ กรุณาตรวจสอบการเชื่อมต่อแล้วลองอีกครั้ง';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = <TransactionCategory>{
      ...categoriesForType(_type),
      // เก็บหมวดหมู่เดิมที่ถูกต้องตามโมเดล แม้ไม่ได้อยู่ในตัวเลือกของรายการใหม่
      _category,
    };
    // ระหว่างบันทึกล็อกทั้งการย้อนกลับและช่องกรอก เพื่อไม่ให้ค่าที่ส่งกับ UI คลาดกัน
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.initialTransaction == null ? 'เพิ่มรายการ' : 'แก้ไขรายการ',
          ),
          automaticallyImplyLeading: false,
          leading: Navigator.of(context).canPop()
              ? IconButton(
                  tooltip: 'กลับ',
                  onPressed: _saving
                      ? null
                      : () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back),
                )
              : null,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                // แสดงคำแนะนำหลังมีการใช้งานช่องกรอก และตรวจซ้ำทุกช่องก่อนบันทึก
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // เน้นจำนวนเงินและประเภทก่อน แล้วค่อยกรอกรายละเอียดรายการด้านล่าง
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.outline),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'ประเภทรายการ',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                for (final type in TransactionType.values)
                                  ChoiceChip(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    avatar: Icon(
                                      type == TransactionType.income
                                          ? Icons.south_west_rounded
                                          : Icons.north_east_rounded,
                                      size: 18,
                                      color: type == TransactionType.income
                                          ? AppColors.income
                                          : AppColors.expense,
                                    ),
                                    label: Text(
                                      type == TransactionType.income
                                          ? 'รายรับ'
                                          : 'รายจ่าย',
                                    ),
                                    selected: _type == type,
                                    // ใช้สีพื้นและสถานะ selected แทนเครื่องหมายถูกที่ทับไอคอนลูกศร
                                    showCheckmark: false,
                                    onSelected: _saving
                                        ? null
                                        : (selected) {
                                            if (!selected || _type == type) {
                                              return;
                                            }
                                            setState(() {
                                              _type = type;
                                              _category = categoriesForType(
                                                type,
                                              ).first;
                                            });
                                          },
                                  ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              key: const Key('transaction-amount'),
                              controller: _amountController,
                              enabled: !_saving,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              textInputAction: TextInputAction.next,
                              validator: validateTransactionAmount,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: _type == TransactionType.income
                                    ? AppColors.income
                                    : AppColors.expense,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'จำนวนเงิน (บาท)',
                                prefixText: '฿ ',
                                hintText: '0.00',
                                helperText:
                                    'มากกว่า 0 บาท · ทศนิยมไม่เกิน 2 ตำแหน่ง',
                                helperMaxLines: 3,
                                errorMaxLines: 5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // หมวดหมู่มีไอคอนและสถานะเลือกชัดเจน กดได้โดยไม่ต้องเปิดเมนู
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.outline),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              key: const Key('transaction-title'),
                              controller: _titleController,
                              enabled: !_saving,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _save(),
                              validator: validateTransactionTitle,
                              decoration: const InputDecoration(
                                labelText: 'ชื่อรายการ',
                                hintText: 'เช่น ค่าอาหารกลางวัน',
                                errorMaxLines: 4,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'หมวดหมู่',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              key: const Key('transaction-category'),
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final category in categories)
                                  ChoiceChip(
                                    key: ValueKey(
                                      'transaction-category-${category.name}',
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 10,
                                    ),
                                    avatar: Icon(
                                      _categoryIcon(category),
                                      size: 20,
                                      color: AppColors.primary,
                                    ),
                                    label: Text(
                                      transactionCategoryLabel(category),
                                    ),
                                    showCheckmark: false,
                                    selected: _category == category,
                                    onSelected: _saving
                                        ? null
                                        : (selected) {
                                            if (selected) {
                                              setState(
                                                () => _category = category,
                                              );
                                            }
                                          },
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              key: const Key('transaction-date'),
                              onPressed: _saving ? null : _chooseDate,
                              style: OutlinedButton.styleFrom(
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              icon: const Icon(Icons.calendar_month_outlined),
                              label: Text(
                                'วันที่: ${_date.day}/${_date.month}/${_date.year}',
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_saveError != null) ...[
                        const SizedBox(height: 16),
                        Semantics(
                          liveRegion: true,
                          // รักษาข้อความผิดพลาดไว้ใกล้คำสั่งบันทึก พร้อมพื้นสีอ่อนให้อ่านง่าย
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.expenseSurface,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              _saveError!,
                              style: const TextStyle(color: AppColors.expense),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        key: const Key('transaction-save'),
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        child: Text(
                          _saving
                              ? 'กำลังบันทึก…'
                              : widget.initialTransaction == null
                              ? 'บันทึกรายการ'
                              : 'บันทึกการแก้ไข',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

IconData _categoryIcon(TransactionCategory category) => switch (category) {
  TransactionCategory.food => Icons.restaurant_rounded,
  TransactionCategory.salary => Icons.payments_outlined,
  TransactionCategory.housing => Icons.home_outlined,
  TransactionCategory.other => Icons.grid_view_rounded,
};
