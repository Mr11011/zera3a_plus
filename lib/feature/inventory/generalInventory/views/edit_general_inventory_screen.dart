import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/colors.dart';
import '../controlller/general_inventory_cubit.dart';
import '../controlller/general_inventory_states.dart';
import '../data/inventory_product_model.dart';

class EditProductScreen extends StatefulWidget {
  final InventoryProduct product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _itemNameController;
  late String _selectedCategory;
  late String _selectedUnit;

  final _units = ['كيلو', "جرام", 'لتر', "سم", 'شيكارة', 'وحدة'];

  @override
  void initState() {
    super.initState();
    // Pre-populate the form with the product's existing data
    _itemNameController = TextEditingController(text: widget.product.itemName);
    _selectedCategory = widget.product.category;
    _selectedUnit = widget.product.unit;
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Create a map of the data to be updated
      final updatedData = {
        'itemName': _itemNameController.text.trim(),
        'category': _selectedCategory,
        'unit': _selectedUnit,
      };

      // Call the cubit function to update the product
      context.read<GeneralInventoryCubit>().updateProductDetails(
            productId: widget.product.id,
            updatedData: updatedData,
          );
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
          title: Text('تعديل بيانات الصنف',
              style: TextStyle(
                  color: AppColor.darkGreen, fontWeight: FontWeight.bold)),
          backgroundColor: AppColor.beige,
          elevation: 0,
        ),
        bottomNavigationBar: _buildSaveButton(),
        body: BlocListener<GeneralInventoryCubit, GeneralInventoryStates>(
          listener: (context, state) {
            if (state is GeneralInventoryItemUpdated) {
              // Pop twice to go back to the main product list after editing
              Navigator.of(context)
                ..pop()
                ..pop();
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
                        controller: _itemNameController,
                        labelText: 'اسم الصنف',
                        icon: Icons.label_outline,
                      ),
                      const SizedBox(height: 16),
                      _buildUnitDropdown(),
                      const SizedBox(height: 24),
                      _buildCategorySelector(),
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

  // --- WIDGET HELPERS ---

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon, color: AppColor.green.withValues(alpha: 0.7)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColor.green, width: 2),
        ),
      ),
      validator: (value) =>
          (value?.trim().isEmpty ?? true) ? 'يرجى ملء هذا الحقل' : null,
    );
  }

  Widget _buildUnitDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedUnit,
      items: _units.map((String unit) {
        return DropdownMenuItem<String>(
          value: unit,
          child: Text(unit),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            _selectedUnit = newValue;
          });
        }
      },
      decoration: InputDecoration(
        labelText: 'وحدة القياس',
        prefixIcon: Icon(Icons.straighten,
            color: AppColor.green.withValues(alpha: 0.7)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCategoryChip('تسميد', _selectedCategory == 'تسميد'),
        const SizedBox(width: 16),
        _buildCategoryChip('رش', _selectedCategory == 'رش'),
      ],
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected) {
    return ChoiceChip(
      checkmarkColor: Colors.white,
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedCategory = label),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColor.green,
        fontWeight: FontWeight.bold,
      ),
      selectedColor: AppColor.green,
      backgroundColor: AppColor.green.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? AppColor.green
              : AppColor.green.withValues(alpha: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
