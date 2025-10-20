import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zera3a/core/utils/colors.dart';
import '../../controller/general_workers_cubit.dart';
import '../../controller/general_workers_state.dart';


class AddFixedWorkerScreen extends StatefulWidget {
  const AddFixedWorkerScreen({super.key});

  @override
  State<AddFixedWorkerScreen> createState() => _AddFixedWorkerScreenState();
}

class _AddFixedWorkerScreenState extends State<AddFixedWorkerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _salaryController = TextEditingController();
  DateTime _hireDate = DateTime.now();

  @override
  void dispose() {
    _nameController.dispose();
    _jobTitleController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final monthlySalary = double.tryParse(_salaryController.text) ?? 0.0;
      final data = {
        'name': _nameController.text.trim(),
        'jobTitle': _jobTitleController.text.trim(),
        'monthlySalary': monthlySalary,
        'dailyRate': monthlySalary / 30, // Calculate daily rate
        'hireDate': _hireDate,
      };
      context.read<GeneralWorkersCubit>().addFixedWorker(data);
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
          title: Text('إضافة عامل ثابت',
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
                SnackBar(
                    content: Text(state.message), backgroundColor: Colors.red),
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _nameController,
                        labelText: 'اسم العامل',
                        icon: Icons.person,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _jobTitleController,
                        labelText: 'المسمى الوظيفي',
                        icon: Icons.work_outline,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _salaryController,
                        labelText: 'الراتب الشهري (جنيه)',
                        icon: Icons.monetization_on_outlined,
                        keyboardType: TextInputType.number,
                      ),
                      // We can add a date picker for hire date later if needed
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
                : const Text('حفظ العامل',
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



