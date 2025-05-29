import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:zera3a/core/di.dart';
import 'package:zera3a/core/utils/colors.dart';
import '../../../core/constants/app_const.dart';
import '../../home/data/plot_model.dart';
import '../controller/inventory_cubit.dart';
import '../controller/inventory_states.dart';

class InventoryScreen extends StatefulWidget {
  final Plot plot;

  const InventoryScreen({super.key, required this.plot});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  late TextEditingController quantityController;
  late TextEditingController unitCostController;
  late TextEditingController itemController;
  final _formKey = GlobalKey<FormState>();
  double totalCost = 0.0;
  DateTime selectedDate = DateTime.now();
  bool showListView = true; // Toggle state for view type
  String userRole = 'supervisor';

  @override
  void initState() {
    super.initState();
    quantityController = TextEditingController()
      ..addListener(_calculateTotalCost);
    unitCostController = TextEditingController()
      ..addListener(_calculateTotalCost);
    itemController = TextEditingController();
    fetchUserRole(userRole).then((value) {
      setState(() {
        userRole = value;
      });
    });
  }

  @override
  void dispose() {
    quantityController.dispose();
    unitCostController.dispose();
    itemController.dispose();
    super.dispose();
  }

  void _calculateTotalCost() {
    final quantity = double.tryParse(quantityController.text) ?? 0.0;
    final unitCost = double.tryParse(unitCostController.text) ?? 0.0;
    setState(() {
      totalCost = (quantity * unitCost).toDouble();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(DateTime.now().year),
      lastDate: DateTime(2060),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.green[800]!,
              onPrimary: Colors.white,
              surface: Colors.brown[50]!,
              onSurface: Colors.brown[900]!,
            ),
            textTheme: TextTheme(
              bodyMedium:
                  TextStyle(fontFamily: GoogleFonts.readexPro().fontFamily),
            ),
            dialogTheme: DialogThemeData(backgroundColor: Colors.brown[50]),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
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
            "إدارة المخزون - ${widget.plot.name}",
            style: TextStyle(
              fontFamily: GoogleFonts.readexPro().fontFamily,
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          backgroundColor: AppColor.green,
          elevation: 4,
        ),
        body: BlocProvider(
          create: (context) =>
              sl<InventoryCubit>()..fetchInventoryData(widget.plot.plotId),
          child: BlocConsumer<InventoryCubit, InventoryStates>(
            listener: (context, state) {
              if (state is InventoryLoadedState) {
                Fluttertoast.showToast(
                  msg: "تم تسجيل بيانات المخزون بنجاح",
                  backgroundColor: Colors.green,
                  textColor: Colors.white,
                );
                setState(() {
                  quantityController.clear();
                  unitCostController.clear();
                  itemController.clear();
                  selectedDate = DateTime.now();
                  totalCost = 0.0;
                });
              } else if (state is InventoryDeletedState) {
                Fluttertoast.showToast(
                  msg: "تم حذف البيانات بنجاح",
                );
              } else if (state is InventoryErrorState) {
                Fluttertoast.showToast(
                  msg: state.errorMessage,
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                );
              }
            },
            builder: (context, state) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    // Input Form Section
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: Colors.brown[50],
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.inventory_2,
                                      color: Colors.brown[900], size: 28),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      "بيانات استخدام المخزون",
                                      style: TextStyle(
                                        fontFamily:
                                            GoogleFonts.readexPro().fontFamily,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.brown[900],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: itemController,
                                keyboardType: TextInputType.name,
                                decoration: InputDecoration(
                                  labelText: "اختر المنتج",
                                  labelStyle:
                                      TextStyle(color: Colors.brown[700]),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "يرجى إدخال المنتج";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              InkWell(
                                onTap: () => _selectDate(context),
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: "تاريخ الاستخدام",
                                    labelStyle:
                                        TextStyle(color: Colors.brown[700]),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        convertToArabicNumbers(
                                            DateFormat('dd-MM-yyyy')
                                                .format(selectedDate)),
                                        style: TextStyle(
                                          fontFamily: GoogleFonts.readexPro()
                                              .fontFamily,
                                          color: Colors.brown[900],
                                        ),
                                      ),
                                      Icon(Icons.calendar_today,
                                          color: Colors.brown[700]),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: quantityController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: "الكمية المستخدمة (كيلو)",
                                  labelStyle:
                                      TextStyle(color: Colors.brown[700]),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "يرجى إدخال الكمية";
                                  }
                                  final num = double.tryParse(value);
                                  if (num == null || num <= 0) {
                                    return "يرجى إدخال كمية صحيحة (أكبر من 0)";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: unitCostController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: "تكلفة الوحدة (جنيه)",
                                  labelStyle:
                                      TextStyle(color: Colors.brown[700]),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "يرجى إدخال تكلفة الوحدة";
                                  }
                                  final num = double.tryParse(value);
                                  if (num == null || num <= 0) {
                                    return "يرجى إدخال تكلفة صحيحة (أكبر من 0)";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      "الإجمالي: ${convertToArabicNumbers(totalCost.toStringAsFixed(2))} جنيه",
                                      style: TextStyle(
                                        fontFamily:
                                            GoogleFonts.readexPro().fontFamily,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: totalCost > 0
                                            ? Colors.green[800]
                                            : Colors.grey,
                                      ),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: state is InventoryLoadingState
                                        ? null
                                        : () {
                                            if (_formKey.currentState!
                                                .validate()) {
                                              context
                                                  .read<InventoryCubit>()
                                                  .addInventoryData(
                                                    itemId: itemController.text,
                                                    quantity: double.parse(
                                                        quantityController
                                                            .text),
                                                    unitCost: double.parse(
                                                        unitCostController
                                                            .text),
                                                    plotId: widget.plot.plotId,
                                                  );
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green[800],
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: state is InventoryLoadingState
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            "حفظ",
                                            style: TextStyle(
                                              fontFamily:
                                                  GoogleFonts.readexPro()
                                                      .fontFamily,
                                              fontSize: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    userRole == 'owner'
                        ? Row(
                            children: [
                              Icon(Icons.history,
                                  color: Colors.brown[900], size: 28),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  "سِجل استخدام المخزون",
                                  style: TextStyle(
                                    fontFamily:
                                        GoogleFonts.readexPro().fontFamily,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.brown[900],
                                  ),
                                ),
                              ),
                              const Spacer(),
                              ToggleButtons(
                                direction: Axis.horizontal,
                                constraints: const BoxConstraints(
                                  minHeight: 40,
                                  minWidth: 40,
                                ),
                                borderRadius: BorderRadius.circular(15),
                                isSelected: [showListView, !showListView],
                                onPressed: (index) {
                                  setState(() {
                                    showListView = index == 0;
                                  });
                                },
                                children: const [
                                  Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 16),
                                    child: Icon(Icons.view_list),
                                  ),
                                  Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 16),
                                    child: Icon(Icons.table_view),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                    const SizedBox(height: 10),
                    userRole == 'owner'
                        ? SizedBox(
                            height: MediaQuery.of(context).size.height * 0.65,
                            child: Card(
                              clipBehavior: Clip.antiAlias,
                              elevation: 8,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              color: Colors.brown[50],
                              child: state is InventoryHistoryLoadedState
                                  ? state.inventoryHistory.isEmpty
                                      ? const Center(
                                          child: Text(
                                              "لا يوجد سجل استخدام مخزون بعد"))
                                      : showListView
                                          ? ListView.builder(
                                              itemCount:
                                                  state.inventoryHistory.length,
                                              itemBuilder: (context, index) {
                                                final inventory = state
                                                    .inventoryHistory[index];
                                                final dayOrNight =
                                                    DateFormat('a')
                                                        .format(inventory.date);
                                                final String hourType =
                                                    dayOrNight.toLowerCase() ==
                                                            'am'
                                                        ? 'صباحاً'
                                                        : 'مساءً';
                                                return Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      vertical: 4.0,
                                                      horizontal: 8.0),
                                                  child: ExpansionTile(
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    collapsedBackgroundColor:
                                                        Colors.white30,
                                                    backgroundColor:
                                                        Colors.white60,
                                                    collapsedShape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    collapsedIconColor:
                                                        Colors.brown[900],
                                                    iconColor:
                                                        Colors.brown[900],
                                                    textColor:
                                                        Colors.brown[900],
                                                    collapsedTextColor:
                                                        Colors.brown[900],
                                                    tilePadding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                            horizontal: 16,
                                                            vertical: 8),
                                                    leading: CircleAvatar(
                                                      backgroundColor:
                                                          Colors.white,
                                                      child: Icon(
                                                        Icons.inventory_2,
                                                        color:
                                                            Colors.brown[900],
                                                        size: 20,
                                                      ),
                                                    ),
                                                    title: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Flexible(
                                                          child: Text(
                                                            inventory.itemId,
                                                            style: TextStyle(
                                                              fontFamily: GoogleFonts
                                                                      .readexPro()
                                                                  .fontFamily,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 16,
                                                            ),
                                                          ),
                                                        ),
                                                        Text(
                                                          convertToArabicNumbers(
                                                              DateFormat(
                                                                      'dd-MM-yyyy')
                                                                  .format(
                                                                      inventory
                                                                          .date)),
                                                          style: TextStyle(
                                                            fontFamily: GoogleFonts
                                                                    .readexPro()
                                                                .fontFamily,
                                                            fontSize: 14,
                                                            color:
                                                                Colors.black54,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    subtitle: Text(
                                                      "الكمية: ${convertToArabicNumbers(inventory.quantityUsed.toString())}ك",
                                                      style: const TextStyle(
                                                          color:
                                                              Colors.black54),
                                                    ),
                                                    children: [
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal:
                                                                    16.0,
                                                                vertical: 8.0),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              "الوقت: ${convertToArabicNumbers(DateFormat('hh:mm').format(inventory.date))} $hourType",
                                                              style: const TextStyle(
                                                                  color: Colors
                                                                      .black54),
                                                            ),
                                                            Text(
                                                              "تكلفة الوحدة: ${convertToArabicNumbers(inventory.itemUnitCost.toString())}جنيه",
                                                              style: const TextStyle(
                                                                  color: Colors
                                                                      .black54),
                                                            ),
                                                            Text(
                                                              "الإجمالي: ${convertToArabicNumbers(inventory.inventoryTotalCost.toString())}جنيه",
                                                              style: const TextStyle(
                                                                  color: Colors
                                                                      .black54),
                                                            ),
                                                            const SizedBox(
                                                                height: 10),
                                                            Align(
                                                              alignment:
                                                                  Alignment
                                                                      .center,
                                                              child:
                                                                  CircleAvatar(
                                                                backgroundColor:
                                                                    Colors.grey
                                                                        .withAlpha(
                                                                            50),
                                                                child:
                                                                    IconButton(
                                                                  icon: const Icon(
                                                                      Icons
                                                                          .delete,
                                                                      color: Colors
                                                                          .red,
                                                                      size: 20),
                                                                  onPressed:
                                                                      () {
                                                                    _deleteButton(
                                                                        context,
                                                                        widget
                                                                            .plot
                                                                            .plotId,
                                                                        inventory
                                                                            .docId);
                                                                  },
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            )
                                          : SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(15.0),
                                                child: DataTable(
                                                  border: TableBorder.all(
                                                    color: Colors.grey.shade300,
                                                    width: 1.2,
                                                  ),
                                                  columns: const [
                                                    DataColumn(
                                                        label: Text('الرقم')),
                                                    DataColumn(
                                                        label: Text('المنتج')),
                                                    DataColumn(
                                                        label: Text('التاريخ')),
                                                    DataColumn(
                                                        label: Text('الكمية')),
                                                    DataColumn(
                                                        label: Text(
                                                            'تكلفة الوحدة')),
                                                    DataColumn(
                                                        label:
                                                            Text('الإجمالي')),
                                                    DataColumn(
                                                        label: Text('الإجراء')),
                                                  ],
                                                  rows: state.inventoryHistory
                                                      .asMap()
                                                      .entries
                                                      .map((entry) {
                                                    final index = entry.key + 1;
                                                    final inventory =
                                                        entry.value;
                                                    final dayOrNight =
                                                        DateFormat('a').format(
                                                            inventory.date);
                                                    final hourType = dayOrNight
                                                                .toLowerCase() ==
                                                            'am'
                                                        ? 'صباحاً'
                                                        : 'مساءً';
                                                    return DataRow(cells: [
                                                      DataCell(Text(
                                                          convertToArabicNumbers(
                                                              index
                                                                  .toString()))),
                                                      DataCell(Text(
                                                          inventory.itemId)),
                                                      DataCell(Text(
                                                          '${convertToArabicNumbers(DateFormat('dd-MM-yyyy , hh:mm').format(inventory.date))} $hourType')),
                                                      DataCell(Text(
                                                          '${convertToArabicNumbers(inventory.quantityUsed.toString())}ك')),
                                                      DataCell(Text(
                                                          '${convertToArabicNumbers(inventory.itemUnitCost.toString())}جنيه')),
                                                      DataCell(Text(
                                                          '${convertToArabicNumbers(inventory.inventoryTotalCost.toString())}جنيه')),
                                                      DataCell(IconButton(
                                                        icon: const Icon(
                                                            Icons.delete,
                                                            color: Colors.red),
                                                        onPressed: () {
                                                          _deleteButton(
                                                              context,
                                                              widget
                                                                  .plot.plotId,
                                                              inventory.docId);
                                                        },
                                                      )),
                                                    ]);
                                                  }).toList(),
                                                ),
                                              ),
                                            )
                                  : state is InventoryLoadingState
                                      ? const Center(
                                          child: CircularProgressIndicator())
                                      : const Center(
                                          child: Text("حدث خطأ، حاول لاحقًا")),
                            ),
                          )
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
                        .read<InventoryCubit>()
                        .deleteInventoryData(plotId, docId);
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
