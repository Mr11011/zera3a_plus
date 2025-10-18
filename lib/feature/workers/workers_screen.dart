import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:zera3a/core/constants/app_const.dart';
import 'package:zera3a/core/di.dart';
import 'package:zera3a/core/utils/colors.dart';
import 'package:zera3a/feature/home/data/plot_model.dart';
import 'package:zera3a/feature/workers/workers_cubit.dart';
import 'package:zera3a/feature/workers/workers_states.dart';

class LaborScreen extends StatefulWidget {
  final Plot plot;

  const LaborScreen({super.key, required this.plot});

  @override
  State<LaborScreen> createState() => _LaborScreenState();
}

class _LaborScreenState extends State<LaborScreen> {
  int fixedWorkersCount = 0;
  int fixedWorkersCostPerWorker = 0;
  int temporaryWorkersCount = 0;
  int temporaryWorkersCostPerWorker = 0;
  int totalLaborCost = 0;
  int temporaryWorkingDays = 0;
  int fixedWorkingDays = 0;

  int _currentStep = 0;
  final _stepperKey = GlobalKey();
  String userRole = 'supervisor';

  @override
  void initState() {
    super.initState();
    fetchUserRole(userRole).then((value) {
      setState(() {
        userRole = value;
      });
    });
  }

  void _calculateTotalCost() {
    setState(() {
      // Calculate costs based on worker count, cost per worker, and days
      totalLaborCost =
          (fixedWorkersCount * fixedWorkersCostPerWorker * fixedWorkingDays) +
              (temporaryWorkersCount *
                  temporaryWorkersCostPerWorker *
                  temporaryWorkingDays);
    });
  }

  void _continueStep(BuildContext context) {
    if (_currentStep < 1) {
      _currentStep += 1;
    } else {
      _submitLaborData(context);
    }
    setState(() {});
  }

  void _cancelStep() {
    if (_currentStep > 0) {
      _currentStep -= 1;
      setState(() {});
    }
  }

  void _submitLaborData(BuildContext context) {
    if (fixedWorkersCount > 0 || temporaryWorkersCount > 0) {
      context.read<LaborCubit>().addLaborData(
            fixedWorkersCount: fixedWorkersCount,
            fixedWorkersCost: fixedWorkersCount * fixedWorkersCostPerWorker,
            temporaryWorkersCount: temporaryWorkersCount,
            temporaryWorkersCost:
                temporaryWorkersCount * temporaryWorkersCostPerWorker,
            fixedWorkersDays: fixedWorkingDays,
            temporaryWorkersDays: temporaryWorkingDays,
            plotId: widget.plot.plotId,
          );
    } else {
      Fluttertoast.showToast(
        msg: "يرجى اختيار عدد العمال على الأقل",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
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
            "إدارة العمال - ${widget.plot.name}",
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
          backgroundColor: AppColor.green,
          elevation: 0,
        ),
        body: BlocProvider(
          create: (context) =>
              sl<LaborCubit>()..fetchLaborData(widget.plot.plotId),
          child: BlocConsumer<LaborCubit, LaborStates>(
            listener: (context, state) {
              if (state is LaborDeletedState) {
                Fluttertoast.showToast(
                  msg: "تم حذف البيانات",
                );
              }
              if (state is LaborErrorState) {
                Fluttertoast.showToast(
                  msg: state.errorMessage,
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                );
              } else if (state is LaborHistoryLoadedState) {
                Fluttertoast.showToast(
                  msg: "تم تحديث سجل العمالة",
                  backgroundColor: Colors.green,
                  textColor: Colors.white,
                );
              }
            },
            builder: (context, state) {
              if (state is LaborLoadingState) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.brown),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    children: [
                      // Stepper for Worker Input
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          color: AppColor.beige,
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                  primary: Colors.brown[700]!),
                            ),
                            child: Stepper(
                              key: _stepperKey,
                              currentStep: _currentStep,
                              onStepContinue: () => _continueStep(context),
                              onStepCancel: _cancelStep,
                              onStepTapped: (step) =>
                                  setState(() => _currentStep = step),
                              controlsBuilder: (context, details) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 16.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      if (_currentStep > 0)
                                        ElevatedButton(
                                          onPressed: _cancelStep,
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.grey.shade200),
                                          child: const Text("رجوع"),
                                        ),
                                      ElevatedButton(
                                        onPressed: details.onStepContinue,
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.brown[700]),
                                        child: Text(
                                          _currentStep == 1 ? "حفظ" : "التالي",
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              steps: [
                                Step(
                                  title: const Text("اختيار العمال الثابتين"),
                                  content: Column(
                                    children: [
                                      _buildWorkerSelector(
                                        title: "عدد العمال الثابتين",
                                        count: fixedWorkersCount,
                                        onCountChanged: (value) {
                                          setState(() {
                                            fixedWorkersCount = value;
                                            _calculateTotalCost();
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 20),
                                      _buildCostInput(
                                        title:
                                            "التكلفة لكل عامل ثابت (جنيه/يوم)",
                                        value: fixedWorkersCostPerWorker,
                                        onChanged: (value) {
                                          setState(() {
                                            fixedWorkersCostPerWorker =
                                                int.tryParse(value) ?? 0;
                                            _calculateTotalCost();
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 22),
                                      _buildDaysSelector(
                                          title: "الايام للعمال الثابتين",
                                          days: fixedWorkingDays,
                                          onDaysChanged: (value) {
                                            setState(() {
                                              fixedWorkingDays = value;
                                              _calculateTotalCost();
                                            });
                                          })
                                    ],
                                  ),
                                  isActive: _currentStep >= 0,
                                  state: _currentStep >= 0
                                      ? StepState.complete
                                      : StepState.disabled,
                                ),
                                Step(
                                  title: const Text("اختيار العمال المؤقتين"),
                                  content: Column(
                                    children: [
                                      _buildWorkerSelector(
                                        title: "عدد العمال المؤقتين",
                                        count: temporaryWorkersCount,
                                        onCountChanged: (value) {
                                          setState(() {
                                            temporaryWorkersCount = value;
                                            _calculateTotalCost();
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      _buildCostInput(
                                        title:
                                            "التكلفة لكل عامل مؤقت (جنيه/يوم)",
                                        value: temporaryWorkersCostPerWorker,
                                        onChanged: (value) {
                                          setState(() {
                                            temporaryWorkersCostPerWorker =
                                                int.tryParse(value) ?? 0;
                                            _calculateTotalCost();
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 22),
                                      _buildDaysSelector(
                                          title: "الايام للعمال المؤقتين",
                                          days: temporaryWorkingDays,
                                          onDaysChanged: (value) {
                                            setState(() {
                                              temporaryWorkingDays = value;
                                              _calculateTotalCost();
                                            });
                                          })
                                    ],
                                  ),
                                  isActive: _currentStep >= 1,
                                  state: _currentStep >= 1
                                      ? StepState.complete
                                      : StepState.disabled,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Total Cost Display
                      Card(
                        elevation: 6,
                        color: Colors.brown[200],
                        child: ListTile(
                          title: Text(
                            "الإجمالي: ${convertToArabicNumbers(totalLaborCost.toString())} جنيه",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.brown[900]),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Labor History
                      userRole == 'owner'
                          ? SizedBox(
                              height: MediaQuery.of(context).size.height * 0.5,
                              child: Card(
                                clipBehavior: Clip.antiAlias,
                                elevation: 8,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                                color: Colors.brown[50],
                                child: state is LaborHistoryLoadedState
                                    ? state.laborHistory.isEmpty
                                        ? const Center(
                                            child:
                                                Text("لا يوجد سجل عمالة بعد"))
                                        : ListView.builder(
                                            itemCount:
                                                state.laborHistory.length,
                                            itemBuilder: (context, index) {
                                              final labor =
                                                  state.laborHistory[index];
                                              final dayOrNight = DateFormat('a')
                                                  .format(labor.date);
                                              final String hourType;
                                              dayOrNight.toLowerCase() == 'am'
                                                  ? hourType = 'صباحاً'
                                                  : hourType = 'مساءً';
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.all(10.0),
                                                child: ExpansionTile(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16),
                                                  ),
                                                  collapsedBackgroundColor:
                                                      Colors.white30,
                                                  backgroundColor:
                                                      Colors.white60,
                                                  collapsedShape:
                                                      RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16),
                                                  ),
                                                  collapsedIconColor:
                                                      Colors.brown[900],
                                                  iconColor: Colors.brown[900],
                                                  textColor: Colors.brown[900],
                                                  collapsedTextColor:
                                                      Colors.brown[900],
                                                  tilePadding:
                                                      const EdgeInsets.all(10),
                                                  leading: const CircleAvatar(
                                                    backgroundColor:
                                                        Colors.white,
                                                    child: Icon(
                                                      Icons.people,
                                                      color: Colors.brown,
                                                    ),
                                                  ),
                                                  title: RichText(
                                                    text: TextSpan(
                                                        text:
                                                            "اليوم: ${convertToArabicNumbers(DateFormat('dd / MM /yyyy', 'ar').format(labor.date))}\n\n",
                                                        style: TextStyle(
                                                            fontFamily: GoogleFonts
                                                                    .readexPro()
                                                                .fontFamily,
                                                            color: Colors.black,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 16),
                                                        children: <TextSpan>[
                                                          TextSpan(
                                                              text:
                                                                  "الوقت: ${convertToArabicNumbers(DateFormat(
                                                                'hh:mm',
                                                              ).format(labor.date))}",
                                                              style: const TextStyle(
                                                                  color: Colors
                                                                      .black54)),
                                                          TextSpan(
                                                              text:
                                                                  " $hourType",
                                                              style: const TextStyle(
                                                                  color: Colors
                                                                      .black54))
                                                        ]),
                                                  ),
                                                  children: [
                                                    Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 16,
                                                          vertical: 8),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          _buildDetailRow(
                                                              "العمال ثابتة:",
                                                              "${convertToArabicNumbers(labor.fixedWorkersCount.toString())} عامل - ${convertToArabicNumbers(labor.fixedWorkersCost.toString())} جنيه / ${convertToArabicNumbers(labor.fixedWorkersDays.toString())} يوم"),
                                                          const SizedBox(
                                                              height: 18),
                                                          _buildDetailRow(
                                                              "مؤقتون:",
                                                              "${convertToArabicNumbers(labor.temporaryWorkersCount.toString())} عامل - ${convertToArabicNumbers(labor.temporaryWorkersCost.toString())} جنيه / ${convertToArabicNumbers(labor.temporaryWorkersDays.toString())} يوم"),
                                                          const SizedBox(
                                                              height: 12),
                                                          const Divider(
                                                              thickness: 1),
                                                          _buildDetailRow(
                                                              "الإجمالي:",
                                                              "${convertToArabicNumbers(labor.totalLaborCost.toString())} جنيه",
                                                              isBold: true),
                                                          const SizedBox(
                                                              height: 16),
                                                          Align(
                                                            alignment: Alignment
                                                                .center,
                                                            child: CircleAvatar(
                                                              backgroundColor:
                                                                  Colors.grey
                                                                      .withAlpha(
                                                                          50),
                                                              child: IconButton(
                                                                  icon: const Icon(
                                                                      Icons
                                                                          .delete,
                                                                      color: Colors
                                                                          .red),
                                                                  onPressed: () =>
                                                                      _deleteButton(
                                                                        context,
                                                                        widget
                                                                            .plot
                                                                            .plotId,
                                                                        labor
                                                                            .docId!,
                                                                      )),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    )
                                                  ],
                                                ),
                                              );
                                            },
                                          )
                                    : state is LaborLoadingState
                                        ? const Center(
                                            child: CircularProgressIndicator())
                                        : const Center(
                                            child:
                                                Text("حدث خطأ، حاول لاحقًا")),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _deleteButton(
      BuildContext parentContext, String plotId, String docId) async {
    return showDialog(
      context: parentContext,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
            content: const Padding(
              padding: EdgeInsets.all(5.0),
              child: Text(
                "هل انت متأكد من حذف البيانات؟",
                style: TextStyle(color: Colors.brown, fontSize: 18),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    "الغاء",
                    style: TextStyle(color: Colors.grey),
                  )),
              ElevatedButton(
                  onPressed: () {
                    parentContext
                        .read<LaborCubit>()
                        .deleteLaborData(plotId, docId);
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    "حذف",
                    style: TextStyle(color: Colors.red),
                  ))
            ]),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.brown,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkerSelector(
      {required String title,
      required int count,
      required Function(int) onCountChanged}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.remove, color: Colors.brown[700]),
              onPressed: count > 0 ? () => onCountChanged(count - 1) : null,
            ),
            CircleAvatar(
                backgroundColor: Colors.grey.shade500,
                child: Text(convertToArabicNumbers(count.toString()),
                    style: const TextStyle(fontSize: 16))),
            IconButton(
              icon: Icon(Icons.add, color: Colors.brown[700]),
              onPressed: () => onCountChanged(count + 1),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDaysSelector(
      {required String title,
      required int days,
      required Function(int) onDaysChanged}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.remove, color: Colors.brown[700]),
              onPressed: days > 1 ? () => onDaysChanged(days - 1) : null,
            ),
            CircleAvatar(
                backgroundColor: Colors.grey.shade500,
                child: Text(convertToArabicNumbers(days.toString()),
                    style: const TextStyle(fontSize: 16))),
            IconButton(
              icon: Icon(Icons.add, color: Colors.brown[700]),
              onPressed: () => onDaysChanged(days + 1),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCostInput(
      {required String title,
      required int value,
      required Function(String) onChanged}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Flexible(
          child: Column(
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(
                height: 15,
              ),
              SizedBox(
                width: 80,
                child: TextField(
                  keyboardType: TextInputType.number,
                  onChanged: onChanged,
                  decoration: InputDecoration(
                    hintText: "0",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
