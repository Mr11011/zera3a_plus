import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zera3a/core/utils/colors.dart';
import '../../controller/general_workers_cubit.dart';
import '../../controller/general_workers_state.dart';

class AddContractorScreen extends StatefulWidget {
  const AddContractorScreen({super.key});

  @override
  State<AddContractorScreen> createState() => _AddContractorScreenState();
}

class _AddContractorScreenState extends State<AddContractorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contractorNameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _phoneController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void dispose() {
    _contractorNameController.dispose();
    _contactPersonController.dispose();
    _phoneController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final data = {
        'contractorName': _contractorNameController.text.trim(),
        'contactPerson': _contactPersonController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'pricePerDay': double.tryParse(_priceController.text) ?? 0.0,
      };
      context.read<GeneralWorkersCubit>().addContractor(data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColor.beige,
        appBar: AppBar(
          iconTheme: IconThemeData(color: AppColor.green),
          title: Text('إضافة مقاول جديد',
              style: TextStyle(
                  color: AppColor.darkGreen, fontWeight: FontWeight.bold)),
          backgroundColor: AppColor.beige,
          elevation: 0,
        ),
        bottomNavigationBar: _buildSaveButton(),
        body: BlocListener<GeneralWorkersCubit, GeneralWorkersState>(
          listener: (context, state) {
            if (state is WorkersSuccess) {
              Navigator.of(context).pop();
            } else if (state is WorkersError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.red),
              );
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Card(
                elevation: 2,
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _contractorNameController,
                        labelText: 'اسم شركة/مكتب المقاول',
                        icon: Icons.business,
                        // This field is required
                        validator: (v) => (v?.trim().isEmpty ?? true) ? 'يرجى ملء هذا الحقل' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _contactPersonController,
                        labelText: 'اسم الشخص المسؤول (اختياري)',
                        icon: Icons.person,
                        // This field is now optional
                        validator: null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _phoneController,
                        labelText: 'رقم الهاتف',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        // This field is required
                        validator: (v) => (v?.trim().isEmpty ?? true) ? 'يرجى ملء هذا الحقل' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _priceController,
                        labelText: 'سعر اليومية للعامل (جنيه)',
                        icon: Icons.monetization_on_outlined,
                        keyboardType: TextInputType.number,
                        // This field is required
                        validator: (v) => (v?.trim().isEmpty ?? true) ? 'يرجى ملء هذا الحقل' : null,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
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
      validator: validator,
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: AppColor.beige,
      child: BlocBuilder<GeneralWorkersCubit, GeneralWorkersState>(
        builder: (context, state) {
          final isLoading = state is WorkersLoading;
          return ElevatedButton(
            onPressed: isLoading ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: isLoading
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white))
                : const Text('حفظ المقاول', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          );
        },
      ),
    );
  }
}