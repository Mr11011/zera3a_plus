import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' show NumberFormat, DateFormat;
import 'package:zera3a/core/di.dart';
import 'package:zera3a/core/utils/colors.dart';
import '../controller/cash_flow_cubit.dart';
import '../controller/cash_flow_states.dart';
import '../model/cash_flow_model.dart';

class CashFlowScreen extends StatelessWidget {
  const CashFlowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<CashFlowCubit>()..fetchTransactions(),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: AppColor.beige.withValues(alpha: 0.3),
          body: BlocListener<CashFlowCubit, CashFlowState>(
            listener: (context, state) {
              if (state is CashFlowSuccess) {
                context.read<CashFlowCubit>().fetchTransactions();
              }
            },
            child: BlocBuilder<CashFlowCubit, CashFlowState>(
              builder: (context, state) {
                if (state is CashFlowLoading || state is CashFlowInitial) {
                  return Center(
                      child: CircularProgressIndicator(color: AppColor.green));
                }

                if (state is CashFlowError) {
                  return _buildErrorWidget(context, state.message);
                }

                if (state is CashFlowLoaded) {
                  return RefreshIndicator(
                    onRefresh: () =>
                        context.read<CashFlowCubit>().fetchTransactions(),
                    color: AppColor.green,
                    child: Column(
                      children: [
                        _buildSummaryDashboard(
                          context,
                          state.totalIncome,
                          state.totalExpenses,
                          state.netBalance,
                        ),
                        Expanded(
                          child: state.transactions.isEmpty
                              ? _buildEmptyStateWidget()
                              : _buildTransactionsList(state.transactions),
                        ),
                      ],
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          floatingActionButton: Builder(
            builder: (buttonContext) {
              return _buildFloatingActionButtons(buttonContext);
            },
          ),
        ),
      ),
    );
  }

  // --- UI WIDGETS ---

  Widget _buildSummaryDashboard(
      BuildContext context, double income, double expenses, double balance) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      // color: Colors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                  child: _buildSummaryItem(
                      'إجمالي الدخل', income, AppColor.green)),
              Expanded(
                child: _buildSummaryItem(
                    'إجمالي المصروفات', expenses, AppColor.medBrown),
              ),
            ],
          ),
          const Divider(height: 24),
          Text('الرصيد الصافي',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            '${NumberFormat.decimalPattern('ar').format(balance)} جنيه',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: balance >= 0 ? AppColor.darkGreen : AppColor.medBrown,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, double amount, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
        const SizedBox(height: 4),
        Text(
          '${NumberFormat.decimalPattern('ar').format(amount)} جنيه',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsList(List<TransactionModel> transactions) {
    return ListView.separated(
      itemCount: transactions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        final isIncome = transaction.type == TransactionType.income;
        final color = isIncome ? Colors.purpleAccent : Colors.red;
        final icon = isIncome ? Icons.arrow_upward : Icons.arrow_downward;

        return Card(
          elevation: 1,
          color: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: 0.1),
              foregroundColor: color,
              child: Icon(icon),
            ),
            title: Text(
              transaction.description,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              DateFormat('d MMMM yyyy', 'ar').format(transaction.date),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            trailing: SizedBox(
              child: Column(
                children: [
                  // view category if exists
                  if (transaction.category.isNotEmpty)
                    Expanded(
                      child: Text(
                        transaction.category,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Text(
                      '${NumberFormat.decimalPattern('ar').format(transaction.amount.abs())} جنيه',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            onTap: () {
              _showEditTransactionSheet(context, transaction);
            },
            onLongPress: () {
              _showDeleteConfirmationDialog(context, transaction);
            },
          ),
        );
      },
    );
  }

  Widget _buildFloatingActionButtons(BuildContext context) {
    void showAddTransactionSheet(TransactionType type) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) {
          return BlocProvider.value(
            value: context.read<CashFlowCubit>(),
            child: _AddTransactionSheet(type: type),
          );
        },
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton.extended(
          heroTag: 'add_expense',
          onPressed: () => showAddTransactionSheet(TransactionType.expense),
          label: const Text('مصروفات', style: TextStyle(color: Colors.white)),
          icon: const Icon(Icons.remove, color: Colors.white),
          backgroundColor: AppColor.medBrown,
        ),
        const SizedBox(width: 16),
        FloatingActionButton.extended(
          heroTag: 'add_income',
          onPressed: () => showAddTransactionSheet(TransactionType.income),
          label: const Text('دخل', style: TextStyle(color: Colors.white)),
          icon: const Icon(Icons.add, color: Colors.white),
          backgroundColor: AppColor.green,
        ),
      ],
    );
  }

  void _showEditTransactionSheet(
      BuildContext context, TransactionModel transaction) {
    final cubit =
        context.read<CashFlowCubit>(); // Get cubit before showing sheet

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return BlocProvider.value(
          value: cubit,
          child: _EditTransactionSheet(transaction: transaction),
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(
      BuildContext context, TransactionModel transaction) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تأكيد الحذف'),
            content: Text(
                'هل أنت متأكد من رغبتك في حذف "${transaction.description}"؟'),
            actions: [
              TextButton(
                child: const Text('إلغاء'),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
              ),
              TextButton(
                child: const Text('حذف', style: TextStyle(color: Colors.red)),
                onPressed: () {
                  context
                      .read<CashFlowCubit>()
                      .deleteTransaction(transactionId: transaction.id);
                  Navigator.of(dialogContext).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyStateWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, color: Colors.grey, size: 70),
          SizedBox(height: 16),
          Text(
            textAlign: TextAlign.center,
            'لا توجد معاملات مالية بعد',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          Text(
            textAlign: TextAlign.center,
            'إضغط على أزرار الإضافة لبدء التسجيل',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: AppColor.medBrown, size: 50),
          const SizedBox(height: 16),
          Text(message,
              style: TextStyle(color: AppColor.medBrown, fontSize: 18)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
              size: 25,
            ),
            style: ElevatedButton.styleFrom(backgroundColor: AppColor.green),
            onPressed: () {
              context.read<CashFlowCubit>().fetchTransactions();
            },
            label: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                  textAlign: TextAlign.center,
                  'إعادة المحاولة',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          )
        ],
      ),
    );
  }
}

class _AddTransactionSheet extends StatefulWidget {
  final TransactionType type;

  const _AddTransactionSheet({required this.type});

  @override
  State<_AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<_AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      context.read<CashFlowCubit>().addTransaction(
            description: _descriptionController.text.trim(),
            amount: double.parse(_amountController.text),
            type: widget.type,
            date: _selectedDate,
            category: _categoryController.text.trim(),
          );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: widget.type == TransactionType.income
                  ? AppColor.green
                  : AppColor.medBrown,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = widget.type == TransactionType.income;
    final primaryColor = isIncome ? AppColor.green : AppColor.medBrown;
    final title = isIncome ? 'إضافة دخل جديد' : 'إضافة مصروفات جديدة';
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return BlocListener<CashFlowCubit, CashFlowState>(
      listener: (context, state) {
        if (state is CashFlowSuccess) {
          Navigator.of(context).pop();
        } else if (state is CashFlowError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColor.medBrown,
            ),
          );
        }
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.only(
              left: 16, right: 16, top: 16, bottom: bottomPadding + 16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                _buildTextField(
                  controller: _descriptionController,
                  labelText: 'الوصف (مثال: بيع محصول، صيانة مضخة)',
                  icon: Icons.description_outlined,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _amountController,
                  labelText: 'المبلغ',
                  icon: Icons.monetization_on_outlined,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _categoryController,
                  labelText: 'الفئة (مثال: محاصيل، خدمات، صيانة)',
                  icon: Icons.category_outlined,
                ),
                const SizedBox(height: 16),
                _buildDatePicker(),
                const SizedBox(height: 24),
                _buildSaveButton(primaryColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String labelText,
      required IconData icon,
      TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon:
            Icon(icon, color: AppColor.darkGreen.withValues(alpha: 0.7)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColor.darkGreen, width: 2),
        ),
      ),
      keyboardType: keyboardType,
      validator: (value) =>
          (value?.trim().isEmpty ?? true) ? 'يرجى ملء هذا الحقل' : null,
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: "التاريخ",
          prefixIcon: Icon(Icons.calendar_today_outlined,
              color: AppColor.darkGreen.withValues(alpha: 0.7)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(DateFormat('d MMMM yyyy', 'ar').format(_selectedDate)),
      ),
    );
  }

  Widget _buildSaveButton(Color color) {
    return SizedBox(
      width: double.infinity,
      child: BlocBuilder<CashFlowCubit, CashFlowState>(
        builder: (context, state) {
          return ElevatedButton(
            onPressed: state is CashFlowLoading ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: state is CashFlowLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(color: Colors.white))
                : const Text('حفظ', style: TextStyle(color: Colors.white)),
          );
        },
      ),
    );
  }
}

class _EditTransactionSheet extends StatefulWidget {
  final TransactionModel transaction;

  const _EditTransactionSheet({required this.transaction});

  @override
  State<_EditTransactionSheet> createState() => _EditTransactionSheetState();
}

class _EditTransactionSheetState extends State<_EditTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  late TextEditingController _categoryController;
  late DateTime _selectedDate;
  late TransactionType _selectedType;

  @override
  void initState() {
    super.initState();
    _descriptionController =
        TextEditingController(text: widget.transaction.description);
    _amountController =
        TextEditingController(text: widget.transaction.amount.abs().toString());
    _categoryController =
        TextEditingController(text: widget.transaction.category);
    _selectedDate = widget.transaction.date;
    _selectedType = widget.transaction.type;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  /// --- FIX: Convert enum to string before sending to cubit ---
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final updatedData = {
        'description': _descriptionController.text.trim(),
        'amount': double.parse(_amountController.text),
        'category': _categoryController.text.trim(),
        'date': _selectedDate,
        // Convert the enum to a string for Firestore
        'type': _selectedType == TransactionType.income ? 'income' : 'expense',
      };

      context.read<CashFlowCubit>().updateTransaction(
            transactionId: widget.transaction.id,
            updatedData: updatedData,
          );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _selectedType == TransactionType.income
                  ? AppColor.green
                  : AppColor.medBrown,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = _selectedType == TransactionType.income
        ? AppColor.green
        : AppColor.medBrown;
    final title = 'تعديل المعاملة';
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return BlocListener<CashFlowCubit, CashFlowState>(
      listener: (context, state) {
        if (state is CashFlowSuccess) {
          Navigator.of(context).pop();
        } else if (state is CashFlowError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColor.medBrown,
            ),
          );
        }
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.only(
              left: 16, right: 16, top: 16, bottom: bottomPadding + 16),
          // --- FIX: Wrap content in SingleChildScrollView to prevent overflow ---
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildTypeSelector(),
                  const SizedBox(height: 24),
                  _buildTextField(
                    controller: _descriptionController,
                    labelText: 'الوصف',
                    icon: Icons.description_outlined,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _amountController,
                    labelText: 'المبلغ',
                    icon: Icons.monetization_on_outlined,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _categoryController,
                    labelText: 'الفئة',
                    icon: Icons.category_outlined,
                  ),
                  const SizedBox(height: 16),
                  _buildDatePicker(),
                  const SizedBox(height: 24),
                  _buildSaveButton(primaryColor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return ToggleButtons(
      isSelected: [
        _selectedType == TransactionType.income,
        _selectedType == TransactionType.expense,
      ],
      onPressed: (index) {
        setState(() {
          _selectedType =
              index == 0 ? TransactionType.income : TransactionType.expense;
        });
      },
      borderRadius: BorderRadius.circular(12.0),
      selectedBorderColor: _selectedType == TransactionType.income
          ? AppColor.green
          : AppColor.medBrown,
      selectedColor: Colors.white,
      fillColor: _selectedType == TransactionType.income
          ? AppColor.green
          : AppColor.medBrown,
      color: _selectedType == TransactionType.income
          ? AppColor.green
          : AppColor.medBrown,
      constraints: BoxConstraints(
        minHeight: 45.0,
        minWidth: (MediaQuery.of(context).size.width - 80) / 2,
      ),
      children: const [
        Text('دخل', style: TextStyle(fontWeight: FontWeight.bold)),
        Text('مصروفات', style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String labelText,
      required IconData icon,
      TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon:
            Icon(icon, color: AppColor.darkGreen.withValues(alpha: 0.7)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColor.darkGreen, width: 2),
        ),
      ),
      keyboardType: keyboardType,
      validator: (value) =>
          (value?.trim().isEmpty ?? true) ? 'يرجى ملء هذا الحقل' : null,
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: "التاريخ",
          prefixIcon: Icon(Icons.calendar_today_outlined,
              color: AppColor.darkGreen.withValues(alpha: 0.7)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(DateFormat('d MMMM yyyy', 'ar').format(_selectedDate)),
      ),
    );
  }

  Widget _buildSaveButton(Color color) {
    return SizedBox(
      width: double.infinity,
      child: BlocBuilder<CashFlowCubit, CashFlowState>(
        builder: (context, state) {
          return ElevatedButton(
            onPressed: state is CashFlowLoading ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: state is CashFlowLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(color: Colors.white))
                : const Text('حفظ التعديلات',
                    style: TextStyle(color: Colors.white)),
          );
        },
      ),
    );
  }
}
