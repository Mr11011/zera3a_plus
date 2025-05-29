import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:shared_preferences/shared_preferences.dart';
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
  late TextEditingController dateController; // New controller for date
  double totalCost = 0.0;
  String userRole = 'supervisor';
  DateTime selectedDate = DateTime.now(); // Default to today
  Map<String, dynamic> plotDetails = {
    'space': 0.0,
    'numPlants': 0,
    'numLines': 0,
    'plantsPerLine': 0,
  };

  @override
  void initState() {
    daysController = TextEditingController(text: 1.toString())
      ..addListener(_calculateTotalCost);
    hoursController = TextEditingController()..addListener(_calculateTotalCost);
    costController = TextEditingController()..addListener(_calculateTotalCost);
    dateController = TextEditingController(
        text: DateFormat('yyyy-MM-dd')
            .format(selectedDate)); // Initialize with today
    fetchUserRole(userRole).then((role) {
      userRole = role;
    });

    sl<IrrigationCubit>().getUnitCost(widget.plot.plotId).then((value) {
      costController.text = value.toString();
    }, onError: (e) {
      costController.text = '0';
      Fluttertoast.showToast(msg: 'فشل في جلب تكلفة الري');
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      sl<IrrigationCubit>().getPlotDetails(widget.plot.plotId).then((details) {
        setState(() {
          plotDetails = details;
        });
      }, onError: (e) {
        Fluttertoast.showToast(msg: 'فشل في جلب تفاصيل الأرض');
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    daysController.dispose();
    hoursController.dispose();
    costController.dispose();
    dateController.dispose();
    super.dispose();
  }

  Future<void> _showEditPlotDetailsDialog(BuildContext context) async {
    final spaceController =
        TextEditingController(text: plotDetails['space'].toString());
    final numPlantsController =
        TextEditingController(text: plotDetails['numPlants'].toString());
    final numLinesController =
        TextEditingController(text: plotDetails['numLines'].toString());
    final plantsPerLineController =
        TextEditingController(text: plotDetails['plantsPerLine'].toString());

    return showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text("تعديل تفاصيل الأرض"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextFormField(
                  labelText: 'مساحة الارض',
                  controller: spaceController,
                  hintText: "مساحة الأرض (فدان)",
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "أدخل مساحة الأرض";
                    }
                    final space = double.tryParse(value);
                    if (space == null || space <= 0) {
                      return "المساحة يجب أن تكون أكبر من 0";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                CustomTextFormField(
                  labelText: 'عدد النباتات/الأشجار',
                  controller: numPlantsController,
                  hintText: "عدد النباتات/الأشجار",
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "أدخل عدد النباتات";
                    }
                    final numPlants = int.tryParse(value);
                    if (numPlants == null || numPlants <= 0) {
                      return "عدد النباتات يجب أن يكون أكبر من 0";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                CustomTextFormField(
                  labelText: 'عدد الخطوط',
                  controller: numLinesController,
                  hintText: "عدد الخطوط",
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "أدخل عدد الخطوط";
                    }
                    final numLines = int.tryParse(value);
                    if (numLines == null || numLines <= 0) {
                      return "عدد الخطوط يجب أن يكون أكبر من 0";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                CustomTextFormField(
                  labelText: "عدد النباتات لكل خط",
                  controller: plantsPerLineController,
                  hintText: "عدد النباتات لكل خط",
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "أدخل عدد النباتات لكل خط";
                    }
                    final plantsPerLine = int.tryParse(value);
                    if (plantsPerLine == null || plantsPerLine <= 0) {
                      return "عدد النباتات لكل خط يجب أن يكون أكبر من 0";
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("إلغاء", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final space = double.tryParse(spaceController.text);
                final numPlants = int.tryParse(numPlantsController.text);
                final numLines = int.tryParse(numLinesController.text);
                final plantsPerLine =
                    int.tryParse(plantsPerLineController.text);

                if (space != null &&
                    numPlants != null &&
                    numLines != null &&
                    plantsPerLine != null) {
                  sl<IrrigationCubit>()
                      .updatePlotDetails(
                    plotId: widget.plot.plotId,
                    space: space,
                    numPlants: numPlants,
                    numLines: numLines,
                    plantsPerLine: plantsPerLine,
                  )
                      .then((_) {
                    setState(() {
                      plotDetails = {
                        'space': space,
                        'numPlants': numPlants,
                        'numLines': numLines,
                        'plantsPerLine': plantsPerLine,
                      };
                    });
                    Navigator.pop(context);
                    Fluttertoast.showToast(
                      msg: "تم تحديث تفاصيل الأرض بنجاح",
                      backgroundColor: Colors.green,
                      textColor: Colors.white,
                    );
                  });
                } else {
                  Fluttertoast.showToast(
                    msg: "يرجى ملء جميع الحقول بشكل صحيح",
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                  );
                }
              },
              child: const Text("حفظ", style: TextStyle(color: Colors.green)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, Map<String, dynamic> entry) {
    final hour = DateFormat('hh:mm').format(entry['date']);
    final date = DateFormat('dd-MM-yyyy').format(entry['date']);
    final dayOrNight = DateFormat('a').format(entry['date']);
    final hourType = dayOrNight.toLowerCase() == 'am' ? 'صباحاً' : 'مساءً';

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
              const SizedBox(height: 3),
              Text(
                  'التكلفة/ساعة: ${convertToArabicNumbers(entry['unitCost'].toString())}ج',
                  style: const TextStyle(color: Colors.black45)),
              const SizedBox(height: 3),
              Text(
                'اليوم: ${convertToArabicNumbers(date)}',
                style: const TextStyle(color: Colors.black45),
              ),
              const SizedBox(height: 3),
              Text(
                "عدد الايام: ${convertToArabicNumbers(entry['days'].toString())}يوم",
                style: const TextStyle(color: Colors.black45),
              ),
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(DateTime.now().year),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        dateController.text = DateFormat('yyyy-MM-dd').format(selectedDate);
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
                hoursController.clear();
                costController.text = sl<SharedPreferences>()
                    .getInt('unitCost${widget.plot.plotId}')
                    .toString();
                dateController.text = DateFormat('yyyy-MM-dd')
                    .format(DateTime.now()); // Reset to today
                _calculateTotalCost();
              }
            },
            builder: (context, state) {
              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: Colors.green.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Flexible(
                                  child: Text(
                                    "تفاصيل الأرض",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                                if (userRole == 'owner')
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () =>
                                        _showEditPlotDetailsDialog(context),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "• مساحة الأرض: ${convertToArabicNumbers(plotDetails['space'].toString())} فدان",
                              style: const TextStyle(fontSize: 16),
                            ),
                            Text(
                              "• عدد النباتات/الأشجار: ${convertToArabicNumbers(plotDetails['numPlants'].toString())}",
                              style: const TextStyle(fontSize: 16),
                            ),
                            Text(
                              "• عدد الخطوط: ${convertToArabicNumbers(plotDetails['numLines'].toString())}",
                              style: const TextStyle(fontSize: 16),
                            ),
                            Text(
                              "• عدد النباتات لكل خط: ${convertToArabicNumbers(plotDetails['plantsPerLine'].toString())}",
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
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
                                Flexible(
                                  child: Text(
                                    "إدخال بيانات الري",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: dateController,
                              keyboardType: TextInputType.datetime,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(15),
                                  ),
                                ),
                                suffixIcon: Icon(Icons.arrow_drop_down),
                                prefixIcon: Icon(Icons.calendar_month),
                                hintText: "تاريخ الري",
                              ),
                              readOnly: true,
                              // Prevent manual editing
                              onTap: () => _selectDate(context),
                              // Open calendar
                              validator: (value) =>
                                  value!.isEmpty ? "اختر تاريخ الري" : null,
                            ),
                            const SizedBox(height: 15),
                            CustomTextFormField(
                              prefixIcon: Icons.onetwothree_sharp,
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
                                            costController.text.isNotEmpty &&
                                            dateController.text.isNotEmpty) {
                                          context
                                              .read<IrrigationCubit>()
                                              .addIrrigationData(
                                                days: int.parse(
                                                    daysController.text),
                                                hours: double.parse(
                                                    hoursController.text),
                                                cost: int.parse(
                                                    costController.text),
                                                plotId: widget.plot.plotId,
                                                date: selectedDate,
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
              ),
            ),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
