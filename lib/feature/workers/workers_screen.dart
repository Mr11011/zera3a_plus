import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:zera3a/core/di.dart';
import 'package:zera3a/core/utils/colors.dart';
import 'package:zera3a/feature/home/data/plot_model.dart';
import 'package:zera3a/feature/workers/workers_cubit.dart';
import 'package:zera3a/feature/workers/workers_model.dart';
import 'package:zera3a/feature/workers/workers_states.dart';
import '../../core/constants/app_const.dart';
import '../general_workers/data/contractors.dart';
import '../general_workers/data/fixed_workers.dart';

class LaborScreen extends StatefulWidget {
  final Plot plot;

  const LaborScreen({super.key, required this.plot});

  @override
  State<LaborScreen> createState() => _LaborScreenState();
}

class _LaborScreenState extends State<LaborScreen> {
  // --- State variables for the new form ---
  FixedWorker? _selectedFixedWorker;
  final _fixedDaysController = TextEditingController();

  Contractor? _selectedContractor;
  final _tempWorkersCountController = TextEditingController();
  final _tempDaysController = TextEditingController();

  double _totalLaborCost = 0.0;
  String userRole = 'owner';

  @override
  void initState() {
    super.initState();
    // Add listeners to controllers to auto-calculate cost
    _fixedDaysController.addListener(_calculateTotalCost);
    _tempWorkersCountController.addListener(_calculateTotalCost);
    _tempDaysController.addListener(_calculateTotalCost);
  }

  @override
  void dispose() {
    _fixedDaysController.dispose();
    _tempWorkersCountController.dispose();
    _tempDaysController.dispose();
    super.dispose();
  }

  void _calculateTotalCost() {
    double fixedCost = 0;
    double tempCost = 0;

    if (_selectedFixedWorker != null) {
      final days = double.tryParse(_fixedDaysController.text) ?? 0.0;
      fixedCost = days * _selectedFixedWorker!.dailyRate;
    }

    if (_selectedContractor != null) {
      final count = double.tryParse(_tempWorkersCountController.text) ?? 0.0;
      final days = double.tryParse(_tempDaysController.text) ?? 0.0;
      tempCost = count * days * _selectedContractor!.pricePerDay;
    }

    setState(() {
      _totalLaborCost = fixedCost + tempCost;
    });
  }

  void _submitLaborData(BuildContext context) {
    final cubit = context.read<PlotLaborCubit>();
    bool didSubmit = false;

    // Check if fixed worker data is valid and entered
    if (_selectedFixedWorker != null && _fixedDaysController.text.isNotEmpty) {
      final days = double.tryParse(_fixedDaysController.text) ?? 0.0;
      if (days > 0) {
        cubit.addLaborActivity(
          plotId: widget.plot.plotId,
          laborType: 'fixed',
          resourceId: _selectedFixedWorker!.id,
          resourceName: _selectedFixedWorker!.name,
          workerCount: 1,
          days: days,
          costPerUnit: _selectedFixedWorker!.dailyRate,
        );
        didSubmit = true;
      }
    }

    // Check if temporary worker data is valid and entered
    if (_selectedContractor != null &&
        _tempWorkersCountController.text.isNotEmpty &&
        _tempDaysController.text.isNotEmpty) {
      final workerCount =
          double.tryParse(_tempWorkersCountController.text) ?? 0.0;
      final days = double.tryParse(_tempDaysController.text) ?? 0.0;
      if (workerCount > 0 && days > 0) {
        cubit.addLaborActivity(
          plotId: widget.plot.plotId,
          laborType: 'temporary',
          resourceId: _selectedContractor!.id,
          resourceName: _selectedContractor!.contractorName,
          workerCount: workerCount,
          days: days,
          costPerUnit: _selectedContractor!.pricePerDay,
        );
        didSubmit = true;
      }
    }

    if (!didSubmit) {
      Fluttertoast.showToast(
        msg: "يرجى إدخال بيانات عامل واحد على الأقل",
        backgroundColor: Colors.red,
      );
    } else {
      setState(() {
        _selectedFixedWorker = null;
        _fixedDaysController.clear();
        _selectedContractor = null;
        _tempWorkersCountController.clear();
        _tempDaysController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            "تسجيل عمالة - ${widget.plot.name}",
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColor.green,
          elevation: 0,
        ),
        body: BlocProvider(
          create: (context) =>
              sl<PlotLaborCubit>()..fetchPageData(widget.plot.plotId),
          child: BlocConsumer<PlotLaborCubit, PlotLaborState>(
            listener: (context, state) {
              if (state is PlotLaborDeleted) {
                Fluttertoast.showToast(msg: "تم حذف البيانات");
              }
              if (state is PlotLaborError) {
                Fluttertoast.showToast(
                    msg: state.message, backgroundColor: Colors.red);
              } else if (state is PlotLaborSuccess) {
                Fluttertoast.showToast(
                    msg: state.message, backgroundColor: Colors.green);
              }
            },
            builder: (context, state) {
              if (state is PlotLaborLoading || state is PlotLaborInitial) {
                return const Center(
                  child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.brown)),
                );
              }
              if (state is PlotLaborError) {
                return Center(child: Text(state.message));
              }
              if (state is PlotLaborPageLoaded) {
                return ListView(
                  padding: const EdgeInsets.all(16.0),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildFixedWorkerCard(context, state.availableFixedWorkers),
                    const SizedBox(height: 24),
                    _buildTempWorkerCard(context, state.availableContractors),
                    const SizedBox(height: 24),
                    _buildTotalCostCard(),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save, color: Colors.white),
                        label: const Text('حفظ',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        onPressed: () => _submitLaborData(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (userRole == 'owner')
                      _buildHistorySection(context, state),
                  ],
                );
              }
              return const Center(child: Text("حالة غير معروفة"));
            },
          ),
        ),
      ),
    );
  }

  // --- NEW UI: Interactive Card for Fixed Workers ---
  Widget _buildFixedWorkerCard(
      BuildContext context, List<FixedWorker> workers) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppColor.beige,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("العمالة الثابتة",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown)),
            const Divider(height: 20),
            DropdownButtonFormField<FixedWorker>(
              value: _selectedFixedWorker,
              hint: const Text("اختر عامل"),
              isExpanded: true,
              items: workers
                  .map((worker) =>
                      DropdownMenuItem(value: worker, child: Text(worker.name)))
                  .toList(),
              onChanged: (worker) => setState(() {
                _selectedFixedWorker = worker;
                _calculateTotalCost();
              }),
              decoration: _inputDecoration(label: "العامل"),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _fixedDaysController,
              decoration: _inputDecoration(label: "عدد أيام العمل"),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
      ),
    );
  }

  // --- NEW UI: Interactive Card for Temporary Workers ---
  Widget _buildTempWorkerCard(
      BuildContext context, List<Contractor> contractors) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppColor.beige,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("العمالة المؤقتة",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown)),
            const Divider(height: 20),
            DropdownButtonFormField<Contractor>(
              value: _selectedContractor,
              hint: const Text("اختر مقاول"),
              isExpanded: true,
              items: contractors
                  .map((c) =>
                      DropdownMenuItem(value: c, child: Text(c.contractorName)))
                  .toList(),
              onChanged: (c) => setState(() {
                _selectedContractor = c;
                _calculateTotalCost();
              }),
              decoration: _inputDecoration(label: "المقاول"),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _tempWorkersCountController,
                    decoration: _inputDecoration(label: "عدد العمال"),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _tempDaysController,
                    decoration: _inputDecoration(label: "عدد الأيام"),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCostCard() {
    return Card(
      elevation: 6,
      color: Colors.grey[200],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(
          "الإجمالي: ${convertToArabicNumbers(_totalLaborCost.toStringAsFixed(2))} جنيه",
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.brown[900]),
        ),
      ),
    );
  }

  // --- History section with UI enhancements ---
  Widget _buildHistorySection(BuildContext context, PlotLaborPageLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("سِجل العمالة",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        state.history.isEmpty
            ? const Card(
                child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: Text("لا يوجد سجل عمالة بعد"))))
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.history.length,
                itemBuilder: (context, index) {
                  final labor = state.history[index];
                  final bool isFixed = labor.laborType == 'fixed';
                  final IconData iconData =
                      isFixed ? Icons.person : Icons.engineering;
                  final Color iconColor =
                      isFixed ? AppColor.green : Colors.blueAccent;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ExpansionTile(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      collapsedShape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      leading: CircleAvatar(
                          backgroundColor: iconColor.withValues(alpha: 0.1),
                          child: Icon(iconData, color: iconColor)),
                      title: Text(
                          "تاريخ: ${convertToArabicNumbers(DateFormat('dd / MM / yyyy', 'ar').format(labor.date))}"),
                      subtitle: Text(
                          "الإجمالي: ${convertToArabicNumbers(labor.totalCost.toStringAsFixed(2))} جنيه"),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 8.0)
                              .copyWith(top: 0),
                          child: Column(
                            children: [
                              _buildDetailRow("النوع:",
                                  isFixed ? 'عامل ثابت' : 'عمالة مؤقتة'),
                              _buildDetailRow(
                                  "الاسم/المقاول:", labor.resourceName),
                              _buildDetailRow(
                                  "العدد:",
                                  convertToArabicNumbers(
                                      labor.workerCount.toString())),
                              _buildDetailRow(
                                  "الأيام:",
                                  convertToArabicNumbers(
                                      labor.days.toString())),
                              _buildDetailRow("التكلفة/وحدة:",
                                  "${convertToArabicNumbers(labor.costPerUnit.toStringAsFixed(2))} جنيه"),
                              const Divider(),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red),
                                  onPressed: () => _deleteButton(
                                      context, widget.plot.plotId, labor),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ],
    );
  }

  Future<void> _deleteButton(
      BuildContext parentContext, String plotId, PlotLaborLog log) async {
    return showDialog(
      context: parentContext,
      builder: (context) => AlertDialog(
        content: const Text("هل انت متأكد من حذف البيانات؟"),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("الغاء")),
          ElevatedButton(
              onPressed: () {
                parentContext
                    .read<PlotLaborCubit>()
                    .deleteLaborActivity(plotId, log);
                Navigator.of(context).pop();
              },
              child: const Text("حذف", style: TextStyle(color: Colors.red)))
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 14, color: Colors.brown)),
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({String? label}) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300)),
    );
  }
}
