import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:zera3a/core/constants/app_const.dart';
import 'package:zera3a/core/widgets/customTextFormField.dart';
import 'package:zera3a/core/di.dart';
import 'package:zera3a/feature/irrigation/irrigation_cubit.dart';
import 'package:zera3a/feature/home/data/plot_model.dart';
import 'package:zera3a/feature/irrigation/irrigation_states.dart';
import '../../core/utils/colors.dart';

class IrrigationScreen extends StatefulWidget {
  final Plot plot;

  const IrrigationScreen({super.key, required this.plot});

  @override
  State<IrrigationScreen> createState() => _IrrigationScreenState();
}

class _IrrigationScreenState extends State<IrrigationScreen> {
  late TextEditingController daysController;
  late TextEditingController hoursController;
  late TextEditingController costController;
  double totalCost = 0.0;
  String userRole = 'supervisor';

  @override
  void initState() {
    daysController = TextEditingController()..addListener(_calculateTotalCost);
    hoursController = TextEditingController()..addListener(_calculateTotalCost);
    costController = TextEditingController()..addListener(_calculateTotalCost);
    fetchUserRole(userRole).then((role) {
      userRole = role;
    });

    super.initState();
  }

  @override
  void dispose() {
    daysController.dispose();
    hoursController.dispose();
    costController.dispose();
    super.dispose();
  }

  Widget _buildHistoryItem(BuildContext context, Map<String, dynamic> entry) {
    final hour = DateFormat('hh:mm').format(entry['date']);
    final date = DateFormat('dd-MM-yyyy').format(entry['date']);

    final dayOrNight = DateFormat('a').format(entry['date']);

    final String hourType;
    dayOrNight.toLowerCase() == 'am' ? hourType = 'صباحاً': hourType = 'مساءً';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(
          '${convertToArabicNumbers(hour)} $hourType',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الساعات: ${convertToArabicNumbers(entry['hours'].toStringAsFixed(2))}',
                style: const TextStyle(color: Colors.black45),
              ),
              const SizedBox(
                height: 3,
              ),
              Text('التكلفة/ساعة: ${convertToArabicNumbers(entry['unitCost'].toString())}ج',
                  style: const TextStyle(color: Colors.black45)),
              const SizedBox(
                height: 3,
              ),
              Text(
                'اليوم: ${convertToArabicNumbers(date)}',
                style: const TextStyle(color: Colors.black45),
              ),
              const SizedBox(
                height: 3,
              ),
              Text(
                "عدد الايام: ${convertToArabicNumbers(entry['days'].toString())}يوم",
                style: const TextStyle(color: Colors.black45),
              )
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${convertToArabicNumbers(entry['totalCost'].toString())}ج',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              backgroundColor: Colors.grey.withAlpha(50),
              child: IconButton(
                onPressed: () {
                  _deleteButton(context, widget.plot.plotId, entry['docId']);
                },
                icon: const Icon(Icons.delete, color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _calculateTotalCost() {
    final days = int.tryParse(daysController.text) ?? 0;
    final hours = double.tryParse(hoursController.text) ?? 0.0;
    final cost = int.tryParse(costController.text) ?? 0;
    setState(() {
      totalCost = days * hours * cost.toDouble();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          centerTitle: true,
          title: Text(
            "تسجيل الري - ${widget.plot.name}",
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColor.green,
        ),
        body: BlocProvider(
          create: (context) =>
              sl<IrrigationCubit>()..fetchIrrigationData(widget.plot.plotId),
          child: BlocConsumer<IrrigationCubit, IrrigationStates>(
            listener: (context, state) {
              if (state is IrrigationDeletedState) {
                Fluttertoast.showToast(msg: 'تم حذف البيانات ');
              }
              if (state is IrrigationErrorState) {
                Fluttertoast.showToast(
                  msg: state.errorMessage,
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                );
              } else if (state is IrrigationLoadedState) {
                Fluttertoast.showToast(
                  msg: "تم تسجيل البيانات بنجاح",
                  backgroundColor: Colors.green,
                  textColor: Colors.white,
                );
                daysController.clear();
                hoursController.clear();
                costController.clear();
                _calculateTotalCost();
              }
            },
            builder: (context, state) {
              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: ListView(
                  children: [
                    Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      shadowColor: Colors.blue.shade200,
                      color: Colors.lightBlue[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.water_drop,
                                  color: Colors.blue,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "إدخال بيانات الري",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            CustomTextFormField(
                              prefixIcon: Icons.calendar_month,
                              controller: daysController,
                              hintText: "عدد الأيام",
                              keyboardType: TextInputType.number,
                              validator: (value) =>
                                  value!.isEmpty ? "أدخل عدد الأيام" : null,
                            ),
                            const SizedBox(height: 15),
                            CustomTextFormField(
                              prefixIcon: Icons.access_time,
                              controller: hoursController,
                              hintText: "عدد الساعات",
                              keyboardType: TextInputType.number,
                              validator: (value) =>
                                  value!.isEmpty ? "أدخل عدد الساعات" : null,
                            ),
                            const SizedBox(height: 15),
                            CustomTextFormField(
                              controller: costController,
                              prefixIcon: Icons.attach_money_rounded,
                              hintText: "التكلفة لكل ساعة (جنيه)",
                              keyboardType: TextInputType.number,
                              validator: (value) =>
                                  value!.isEmpty ? "أدخل التكلفة" : null,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              "الإجمالي: ${convertToArabicNumbers(totalCost.toStringAsFixed(2))} جنيه",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color:
                                    totalCost > 0 ? Colors.blue : Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 20),
                            state is IrrigationLoadingState
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : Center(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        if (daysController.text.isNotEmpty &&
                                            hoursController.text.isNotEmpty &&
                                            costController.text.isNotEmpty) {
                                          context
                                              .read<IrrigationCubit>()
                                              .addIrrigationData(
                                                int.parse(daysController.text),
                                                double.parse(
                                                    hoursController.text),
                                                int.parse(costController.text),
                                                widget.plot.plotId,
                                              );
                                        } else {
                                          Fluttertoast.showToast(
                                            msg: "يرجى ملء جميع البيانات",
                                            backgroundColor: Colors.red,
                                            textColor: Colors.white,
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green.shade400,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10, horizontal: 40),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      label: const Text(
                                        "حفظ",
                                        style: TextStyle(
                                            fontSize: 18, color: Colors.white),
                                      ),
                                      icon: const Icon(
                                        Icons.save,
                                        size: 22,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // History Section
                    userRole.toString() == 'owner'
                        ? const Text(
                            "تاريخ سِجل الري",
                            style: TextStyle(
                                color: Colors.blue,
                                fontSize: 22,
                                fontWeight: FontWeight.w500),
                          )
                        : const SizedBox.shrink(),
                    Divider(
                      color: Colors.grey[300],
                      thickness: 1,
                      // indent: 1,
                      endIndent: 180,
                    ),
                    userRole.toString() == 'owner'
                        ? _buildIrrigationHistory(context)
                        : const SizedBox.shrink(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildIrrigationHistory(BuildContext context) {
    return BlocBuilder<IrrigationCubit, IrrigationStates>(
      builder: (context, state) {
        if (state is IrrigationHistoryLoadedState) {
          if (state.irrigationHistory.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(25.0),
                child: Text('لا يوجد سجل ري سابق'),
              ),
            );
          }

          return ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: state.irrigationHistory.length,
            itemBuilder: (context, index) {
              final entry = state.irrigationHistory[index];
              return _buildHistoryItem(context, entry);
            },
          );
        }

        if (state is IrrigationLoadingState) {
          return const Center(child: CircularProgressIndicator());
        }

        return const SizedBox.shrink();
      },
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
                        .read<IrrigationCubit>()
                        .deleteIrrigationData(plotId, docId);
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
}
