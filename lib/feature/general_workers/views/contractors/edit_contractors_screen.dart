import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:zera3a/core/utils/colors.dart';
import '../../controller/general_workers_cubit.dart';
import '../../controller/general_workers_state.dart';
import '../../data/contractors.dart';

class EditContractorScreen extends StatefulWidget {
  final Contractor contractor;

  const EditContractorScreen({super.key, required this.contractor});

  @override
  State<EditContractorScreen> createState() => _EditContractorScreenState();
}

class _EditContractorScreenState extends State<EditContractorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _contactPersonController;
  late TextEditingController _pricePerDayController;

  // No local _isLoading needed, BlocBuilder will handle it

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.contractor.contractorName);
    _contactPersonController =
        TextEditingController(text: widget.contractor.contactPerson);
    _pricePerDayController = TextEditingController(
        text: widget.contractor.pricePerDay.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactPersonController.dispose();
    _pricePerDayController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    // Don't check for isLoading, button will be disabled by BlocBuilder

    final data = {
      'contractorName': _nameController.text.trim(),
      'contactPerson': _contactPersonController.text.trim(),
      'pricePerDay': double.tryParse(_pricePerDayController.text) ?? 0.0,
    };

    context
        .read<GeneralWorkersCubit>()
        .updateContractor(widget.contractor.id, data);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColor.beige,
        appBar: AppBar(
          iconTheme: IconThemeData(color: AppColor.green),
          title: Text('تعديل بيانات المقاول',
              style: TextStyle(
                  color: AppColor.darkGreen, fontWeight: FontWeight.bold)),
          backgroundColor: AppColor.beige,
          elevation: 0.7,
          // Save button is now in the bottomNavigationBar
        ),
        bottomNavigationBar: _buildSaveButton(),
        body: BlocListener<GeneralWorkersCubit, GeneralWorkersState>(
          listener: (context, state) {
            if (state is WorkersSuccess) {
              // Show toast on success (optional, as you had it before)
              Fluttertoast.showToast(
                  msg: state.message, backgroundColor: AppColor.green);
              Navigator.of(context).pop(true); // Pop with success
            } else if (state is WorkersError) {
              // Use SnackBar for error as in your example
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(state.message), backgroundColor: Colors.red),
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
                    children: [
                      _buildTextField(
                        controller: _nameController,
                        labelText: 'اسم المقاول / الشركة',
                        icon: Icons.business,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _contactPersonController,
                        labelText: 'اسم الشخص المسؤول',
                        icon: Icons.person,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _pricePerDayController,
                        labelText: 'سعر العامل في اليوم (جنيه)',
                        icon: Icons.wallet_outlined,
                        keyboardType: TextInputType.number,
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

  // Helper for TextFields (Copied from your new style)
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
        prefixIcon: Icon(icon, color: AppColor.green.withValues(alpha: 0.7)),
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

  // Helper for Save Button (Copied from your new style)
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(color: Colors.white))
                : const Text('حفظ التعديلات',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
          );
        },
      ),
    );
  }
}
