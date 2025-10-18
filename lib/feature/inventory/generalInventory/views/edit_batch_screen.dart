import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:zera3a/core/utils/colors.dart';
import '../controlller/general_inventory_cubit.dart';
import '../controlller/general_inventory_states.dart';
import '../data/inventory_product_model.dart';
import '../data/purchase_batch_model.dart';

class EditPurchaseBatchScreen extends StatefulWidget {
  final InventoryProduct product;
  final PurchaseBatch batch;

  const EditPurchaseBatchScreen(
      {super.key, required this.product, required this.batch});

  @override
  State<EditPurchaseBatchScreen> createState() =>
      _EditPurchaseBatchScreenState();
}

class _EditPurchaseBatchScreenState extends State<EditPurchaseBatchScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _vendorController;
  late TextEditingController _originController;
  late TextEditingController _initialQuantityController;
  late TextEditingController _currentQuantityController;
  late TextEditingController _totalCostController;
  late DateTime _purchaseDate;

  @override
  void initState() {
    super.initState();
    // Pre-populate the form with the existing batch data
    _vendorController = TextEditingController(text: widget.batch.vendor);
    _originController = TextEditingController(text: widget.batch.origin);
    _initialQuantityController =
        TextEditingController(text: widget.batch.initialQuantity.toString());
    _currentQuantityController =
        TextEditingController(text: widget.batch.currentQuantity.toString());
    _totalCostController =
        TextEditingController(text: widget.batch.totalCost.toString());
    _purchaseDate = widget.batch.purchaseDate;
  }

  @override
  void dispose() {
    _vendorController.dispose();
    _originController.dispose();
    _initialQuantityController.dispose();
    _currentQuantityController.dispose();
    _totalCostController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Create a map of the data to be updated
      final updatedData = {
        'vendor': _vendorController.text.trim(),
        'origin': _originController.text.trim(),
        'purchaseDate': _purchaseDate,
        'initialQuantity':
            double.tryParse(_initialQuantityController.text) ?? 0,
        'currentQuantity':
            double.tryParse(_currentQuantityController.text) ?? 0,
        'totalCost': double.tryParse(_totalCostController.text) ?? 0,
      };

      // Call the cubit function to update the batch
      context.read<GeneralInventoryCubit>().updatePurchaseBatch(
            productId: widget.product.id,
            batchId: widget.batch.id,
            updatedData: updatedData,
          );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColor.green,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _purchaseDate) {
      setState(() {
        _purchaseDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColor.beige.withValues(alpha: 0.2),
        appBar: AppBar(
          iconTheme: IconThemeData(color: AppColor.green),
          title: Text('تعديل بيانات الشحنة',
              style: TextStyle(
                  color: AppColor.darkGreen, fontWeight: FontWeight.bold)),
          backgroundColor: AppColor.beige,
          elevation: 0,
        ),
        bottomNavigationBar: _buildSaveButton(),
        body: BlocListener<GeneralInventoryCubit, GeneralInventoryStates>(
          listener: (context, state) {
            if (state is GeneralInventorySuccess) {
              Navigator.of(context).pop();
            } else if (state is GeneralInventoryError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColor.medBrown,
                ),
              );
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Card(
                elevation: 2,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(
                        controller: _initialQuantityController,
                        labelText: 'الكمية المبدئية (${widget.product.unit})',
                        icon: Icons.unarchive_outlined,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _currentQuantityController,
                        labelText: 'الكمية الحالية (${widget.product.unit})',
                        icon: Icons.inventory_2_outlined,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _totalCostController,
                        labelText: 'التكلفة الإجمالية للشحنة',
                        icon: Icons.monetization_on_outlined,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _vendorController,
                        labelText: 'اسم المورد',
                        icon: Icons.store_mall_directory_outlined,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _originController,
                        labelText: 'بلد المنشأ',
                        icon: Icons.public_outlined,
                      ),
                      const SizedBox(height: 16),
                      _buildDatePicker(),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon, color: AppColor.green.withOpacity(0.7)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColor.green, width: 2),
        ),
      ),
      keyboardType: keyboardType,
      validator: (v) =>
          (v?.trim().isEmpty ?? true) ? 'يرجى ملء هذا الحقل' : null,
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: "تاريخ الشراء",
          prefixIcon: Icon(Icons.calendar_today_outlined,
              color: AppColor.green.withValues(alpha: 0.7)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(DateFormat('dd / MM /yyyy', 'ar').format(_purchaseDate)),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: AppColor.beige,
      child: BlocBuilder<GeneralInventoryCubit, GeneralInventoryStates>(
        builder: (context, state) {
          final isLoading = state is GeneralInventoryLoading;
          return ElevatedButton(
            onPressed: isLoading ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : const Text('حفظ التعديلات',
                    style: TextStyle(color: Colors.white)),
          );
        },
      ),
    );
  }
}
