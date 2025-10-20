import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;
import 'package:zera3a/core/constants/app_const.dart';
import 'package:zera3a/core/utils/colors.dart';
import '../../controller/general_workers_cubit.dart';
import '../../controller/general_workers_state.dart';
import '../../data/fixed_workers.dart';
import '../../data/salary_notes.dart';
import 'edit_fixed_workers_screen.dart';

class FixedWorkerDetailScreen extends StatefulWidget {
  final FixedWorker worker;

  const FixedWorkerDetailScreen({super.key, required this.worker});

  @override
  State<FixedWorkerDetailScreen> createState() =>
      _FixedWorkerDetailScreenState();
}

class _FixedWorkerDetailScreenState extends State<FixedWorkerDetailScreen> {
  final _noteController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    context.read<GeneralWorkersCubit>().fetchSalaryNotes(widget.worker.id);
  }

  @override
  void dispose() {
    _noteController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addNote(BuildContext context) {
    if (_noteController.text.trim().isEmpty) {
      return;
    }
    context.read<GeneralWorkersCubit>().addSalaryNote(
          workerId: widget.worker.id,
          noteText: _noteController.text.trim(),
        );
    _noteController.clear();
    FocusScope.of(context).unfocus(); // Close keyboard after sending
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColor.beige,
        appBar: AppBar(
          iconTheme: IconThemeData(color: AppColor.green),
          title: Text(widget.worker.name,
              style: TextStyle(
                  color: AppColor.darkGreen, fontWeight: FontWeight.bold)),
          backgroundColor: AppColor.beige,
          elevation: 0.7,
          actions: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<GeneralWorkersCubit>(),
                      child: EditFixedWorkerScreen(worker: widget.worker),
                    ),
                  ),
                ).then((didUpdate) {
                  // This checks if the EditScreen popped with 'true'
                  if (didUpdate == true) {
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  }
                });
              },
              icon: Icon(Icons.edit_note, color: AppColor.green, size: 28),
            ),
            IconButton(
              onPressed: () =>
                  _showDeleteWorkerConfirmationDialog(context, widget.worker),
              icon: Icon(Icons.delete_forever_outlined,
                  color: AppColor.medBrown, size: 28),
            ),
          ],
        ),
        body: BlocListener<GeneralWorkersCubit, GeneralWorkersState>(
          listener: (context, state) {
            if (state is WorkersSuccess) {
              Fluttertoast.showToast(
                  msg: state.message, backgroundColor: AppColor.green);
            } else if (state is GeneralWorkersItemDeleted) {
              Navigator.of(context).pop();
            } else if (state is WorkersError) {
              Fluttertoast.showToast(
                  msg: state.message, backgroundColor: Colors.red);
            }
          },
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                        bottom: BorderSide(color: Colors.grey.shade300))),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: AppColor.green.withValues(alpha: 0.1),
                      child:
                          Icon(Icons.person, color: AppColor.green, size: 40),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.worker.name,
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColor.darkGreen),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.worker.jobTitle,
                      style: TextStyle(fontSize: 16, color: AppColor.medBrown),
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSalaryInfo('الراتب الشهري',
                            '${convertToArabicNumbers(NumberFormat.decimalPattern('ar').format(widget.worker.monthlySalary))} جنيه'),
                        _buildSalaryInfo('اليومية',
                            '${convertToArabicNumbers(NumberFormat.decimalPattern('ar').format(widget.worker.dailyRate))} جنيه'),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                    top: 16.0, right: 16.0, left: 16.0, bottom: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.notes, color: AppColor.darkGreen),
                    const SizedBox(width: 8),
                    Text(
                      'ملاحظات ',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColor.darkGreen),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: BlocBuilder<GeneralWorkersCubit, GeneralWorkersState>(
                  builder: (context, state) {
                    if (state is NotesLoaded) {
                      if (state.notes.isEmpty) {
                        return const Center(
                            child: Text('لا توجد ملاحظات مسجلة.'));
                      }
                      return _buildNotesList(context, state.notes);
                    }
                    // This will catch WorkersLoading and WorkersInitial
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              ),
              _buildNoteInputRow(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper for the salary info in the header
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

  /// The "Feed-style" list for notes
  Widget _buildNotesList(BuildContext context, List<SalaryNote> notes) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return Card(
          elevation: 1,
          color: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            title: Text(note.noteText),
            subtitle: Text(DateFormat('yyyy/MM/dd', 'ar').format(note.date)),
            trailing: IconButton(
              icon: Icon(Icons.delete_outline, color: AppColor.medBrown),
              onPressed: () {
                context.read<GeneralWorkersCubit>().deleteSalaryNote(
                      workerId: widget.worker.id,
                      noteId: note.id,
                    );
              },
            ),
          ),
        );
      },
    );
  }

  /// The "Chat-style" input field
  Widget _buildNoteInputRow(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _noteController,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: 'اكتب ملاحظتك هنا...',
                fillColor: AppColor.beige,
                filled: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _addNote(context),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.send, color: AppColor.green),
            onPressed: () => _addNote(context),
          ),
        ],
      ),
    );
  }

  void _showDeleteWorkerConfirmationDialog(
      BuildContext context, FixedWorker worker) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // Use the root context to read the cubit
        final cubit = context.read<GeneralWorkersCubit>();
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تأكيد الحذف'),
            content: Text(
                'هل أنت متأكد من حذف العامل "${worker.name}"؟ سيتم حذف جميع ملاحظاته المسجلة.'),
            actions: [
              TextButton(
                  child: const Text('إلغاء'),
                  onPressed: () => Navigator.of(dialogContext).pop()),
              TextButton(
                child: const Text('حذف', style: TextStyle(color: Colors.red)),
                onPressed: () {
                  cubit.deleteFixedWorker(worker.id);
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
