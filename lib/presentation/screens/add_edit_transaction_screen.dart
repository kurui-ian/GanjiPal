import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pesatrack_core/pesatrack_core.dart';

import '../../core/constants/app_colors.dart';
import '../providers/app_state.dart';

class AddEditTransactionScreen extends StatefulWidget {
  final AppState appState;
  final TransactionModel? initialTransaction;

  const AddEditTransactionScreen({
    super.key,
    required this.appState,
    this.initialTransaction,
  });

  @override
  State<AddEditTransactionScreen> createState() =>
      _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends State<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _amountController;
  late TextEditingController _counterpartyController;
  late TextEditingController _phoneController;
  late TextEditingController _descriptionController;

  late TransactionType _selectedType;
  late FinancialClassification _selectedClassification;
  late String _selectedCategoryId;
  late DateTime _selectedDateTime;

  @override
  void initState() {
    super.initState();
    final tx = widget.initialTransaction;

    _amountController = TextEditingController(
      text: tx != null ? (tx.amountCents / 100.0).toStringAsFixed(2) : '',
    );
    _counterpartyController = TextEditingController(
      text: tx?.counterpartyName ?? '',
    );
    _phoneController = TextEditingController(text: tx?.counterpartyPhone ?? '');
    _descriptionController = TextEditingController(text: tx?.description ?? '');

    _selectedType = tx?.transactionType ?? TransactionType.buyGoods;
    _selectedClassification =
        tx?.classification ?? FinancialClassification.expense;
    _selectedCategoryId = tx?.categoryId ?? 'food_groceries';
    _selectedDateTime = tx?.timestamp ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _counterpartyController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onTypeChanged(TransactionType type) {
    setState(() {
      _selectedType = type;
      switch (type) {
        case TransactionType.sendMoney:
          _selectedClassification = FinancialClassification.transfer;
          _selectedCategoryId = 'transfers';
          break;
        case TransactionType.receiveMoney:
          _selectedClassification = FinancialClassification.income;
          _selectedCategoryId = 'income';
          break;
        case TransactionType.withdrawAgent:
        case TransactionType.withdrawAtm:
          _selectedClassification = FinancialClassification.withdrawal;
          _selectedCategoryId = 'cash_withdrawals';
          break;
        case TransactionType.deposit:
          _selectedClassification = FinancialClassification.deposit;
          _selectedCategoryId = 'other';
          break;
        case TransactionType.airtime:
          _selectedClassification = FinancialClassification.expense;
          _selectedCategoryId = 'airtime_data';
          break;
        case TransactionType.buyGoods:
        case TransactionType.payBill:
        default:
          _selectedClassification = FinancialClassification.expense;
          _selectedCategoryId = 'food_groceries';
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialTransaction != null
              ? 'Edit Transaction'
              : 'Add Transaction',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Amount Input
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount (KSh)',
                prefixText: 'KSh ',
                hintText: '0.00',
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty)
                  return 'Please enter an amount';
                final clean = val.replaceAll(',', '').trim();
                final num = double.tryParse(clean);
                if (num == null || num <= 0)
                  return 'Enter a valid positive number';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Transaction Type Selector
            DropdownButtonFormField<TransactionType>(
              value: _selectedType,
              decoration: const InputDecoration(labelText: 'Transaction Type'),
              items: const [
                DropdownMenuItem(
                  value: TransactionType.buyGoods,
                  child: Text('Buy Goods / Till'),
                ),
                DropdownMenuItem(
                  value: TransactionType.payBill,
                  child: Text('PayBill Payment'),
                ),
                DropdownMenuItem(
                  value: TransactionType.sendMoney,
                  child: Text('Send Money'),
                ),
                DropdownMenuItem(
                  value: TransactionType.receiveMoney,
                  child: Text('Received Money'),
                ),
                DropdownMenuItem(
                  value: TransactionType.withdrawAgent,
                  child: Text('Agent Withdrawal'),
                ),
                DropdownMenuItem(
                  value: TransactionType.withdrawAtm,
                  child: Text('ATM Withdrawal'),
                ),
                DropdownMenuItem(
                  value: TransactionType.deposit,
                  child: Text('Cash Deposit'),
                ),
                DropdownMenuItem(
                  value: TransactionType.airtime,
                  child: Text('Airtime Purchase'),
                ),
              ],
              onChanged: (val) {
                if (val != null) _onTypeChanged(val);
              },
            ),
            const SizedBox(height: 16),

            // Category Selector
            DropdownButtonFormField<String>(
              value: _selectedCategoryId,
              decoration: const InputDecoration(labelText: 'Category'),
              items: widget.appState.categories.map((c) {
                return DropdownMenuItem(value: c.id, child: Text(c.name));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCategoryId = val);
              },
            ),
            const SizedBox(height: 16),

            // Counterparty Name
            TextFormField(
              controller: _counterpartyController,
              decoration: const InputDecoration(
                labelText: 'Merchant / Recipient Name',
                hintText: 'e.g. Naivas Supermarket, John Doe',
              ),
            ),
            const SizedBox(height: 16),

            // Phone Number
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number (Optional)',
                hintText: 'e.g. 0712345678',
              ),
            ),
            const SizedBox(height: 16),

            // Date and Time Picker
            InkWell(
              onTap: _pickDateTime,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Transaction Date & Time',
                  suffixIcon: Icon(Icons.calendar_today, size: 20),
                ),
                child: Text(dateFormat.format(_selectedDateTime)),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Notes / Description (Optional)',
                hintText: 'e.g. Weekly grocery shopping',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 32),

            // Save Button
            FilledButton(
              onPressed: _saveTransaction,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Save Transaction',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final amountDouble = double.parse(
      _amountController.text.replaceAll(',', '').trim(),
    );
    final amountCents = (amountDouble * 100).round();
    final category = widget.appState.categories.firstWhere(
      (c) => c.id == _selectedCategoryId,
    );

    final success = await widget.appState.addManualTransaction(
      amountCents: amountCents,
      type: _selectedType,
      classification: _selectedClassification,
      categoryId: category.id,
      categoryName: category.name,
      timestamp: _selectedDateTime,
      counterpartyName: _counterpartyController.text.trim().isNotEmpty
          ? _counterpartyController.text.trim()
          : null,
      counterpartyPhone: _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : null,
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction saved successfully')),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Duplicate transaction prevented')),
        );
      }
    }
  }
}
