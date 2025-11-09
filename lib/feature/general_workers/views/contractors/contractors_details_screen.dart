import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:zera3a/core/constants/app_const.dart';
import 'package:zera3a/core/utils/colors.dart';
import '../../controller/general_workers_cubit.dart';
import '../../controller/general_workers_state.dart';
import '../../data/contractors.dart';
import 'edit_contractors_screen.dart';

class ContractorDetailScreen extends StatelessWidget {
  final Contractor contractor;

  const ContractorDetailScreen({super.key, required this.contractor});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColor.beige,
        appBar: AppBar(
          iconTheme: IconThemeData(color: AppColor.green),
          title: Text(contractor.contractorName,
              style: TextStyle(
                  color: AppColor.darkGreen, fontWeight: FontWeight.bold)),
          backgroundColor: AppColor.beige,
          elevation: 0.7,
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: context.read<GeneralWorkersCubit>(),
                        child: EditContractorScreen(contractor: contractor),
                      ),
                    ),
                  ).then((didUpdate) {
                    if (didUpdate == true) {
                      if (!context.mounted) return;
                      // If update was successful, pop back to the main list
                      Navigator.of(context).pop();
                    }
                  });
                },
                icon: Icon(Icons.edit_note, color: AppColor.green, size: 28),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: IconButton(
                onPressed: () =>
                    _showDeleteContractorConfirmationDialog(context, contractor),
                icon: Icon(Icons.delete_forever_outlined,
                    color: AppColor.medBrown, size: 28),
              ),
            ),
          ],
        ),
        body: BlocListener<GeneralWorkersCubit, GeneralWorkersState>(
          listener: (context, state) {
            // We listen for the DELETED state to pop the screen
            if (state is GeneralWorkersItemDeleted) {
              Navigator.of(context).pop();
            } else if (state is WorkersError) {
              Fluttertoast.showToast(
                  msg: state.message, backgroundColor: Colors.red);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
                    child: const Icon(Icons.engineering,
                        color: Colors.blueAccent, size: 40),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    contractor.contractorName,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColor.darkGreen),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'مقاول (عمالة مؤقتة)',
                    style: TextStyle(fontSize: 16, color: AppColor.medBrown),
                  ),
                  const Divider(height: 24),
                  _buildSalaryInfo(
                    'الشخص المسؤول',
                    contractor.contactPerson.isNotEmpty
                        ? contractor.contactPerson
                        : 'غير محدد',
                  ),
                  const SizedBox(height: 16),
                  _buildSalaryInfo(
                    'سعر اليومية للعامل',
                    '${convertToArabicNumbers(NumberFormat.decimalPattern('ar').format(contractor.pricePerDay))} جنيه',
                  ),
                  const SizedBox(height: 16),

                  InkWell(
                    onTap: () {
                      Clipboard.setData(
                              ClipboardData(text: contractor.phoneNumber))
                          .then((_) {
                        Fluttertoast.showToast(
                            msg: 'تم نسخ رقم الهاتف',
                            backgroundColor: Colors.green);
                      });
                    },
                    child: _buildSalaryInfo(
                      'رقم الهاتف المحمول',
                      convertToArabicNumbers(contractor.phoneNumber),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Helper for the info in the header
  Widget _buildSalaryInfo(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColor.darkGreen),
        ),
      ],
    );
  }

  void _showDeleteContractorConfirmationDialog(
      BuildContext context, Contractor contractor) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final cubit = context.read<GeneralWorkersCubit>();
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تأكيد الحذف'),
            content: Text(
                'هل أنت متأكد من حذف المقاول "${contractor.contractorName}"؟'),
            actions: [
              TextButton(
                  child: const Text('إلغاء'),
                  onPressed: () => Navigator.of(dialogContext).pop()),
              TextButton(
                child: const Text('حذف', style: TextStyle(color: Colors.red)),
                onPressed: () {
                  // We use the cubit to delete
                  cubit.deleteContractor(contractor.id);
                  Navigator.of(dialogContext).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
