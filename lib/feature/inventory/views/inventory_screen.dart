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
import '../data/inventory_model.dart';
import '../generalInventory/data/inventory_product_model.dart';

class InventoryScreen extends StatefulWidget {
  final Plot plot;

  const InventoryScreen({super.key, required this.plot});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _formKey = GlobalKey<FormState>();

  // --- Only quantity controller is needed from your original form ---
  late TextEditingController quantityController;

  // late TextEditingController unitCostController; // REMOVED
  // late TextEditingController itemController; // REMOVED

  // --- NEW State variables for the integrated form ---
  int _selectedCategoryIndex = 0;
  final List<String> _categories = ['تسميد', 'رش'];
  InventoryProduct? _selectedItem; // <-- CHANGED Type
  // double totalCost = 0.0; // REMOVED - Cost is handled by backend

  DateTime selectedDate = DateTime.now(); // Kept from your original code.
  bool showListView = true; // Toggle state for view type
  String userRole = 'owner'; // Default role, as in your original code.

  @override
  void initState() {
    super.initState();
    quantityController = TextEditingController();
  }

  @override
  void dispose() {
    quantityController.dispose();
    // REMOVED disposal for itemController and unitCostController
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    // This function remains unchanged from your original code
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

  void _submitForm(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      if (_selectedItem == null) {
        Fluttertoast.showToast(msg: "يرجى اختيار صنف من المخزن");
        return;
      }
      // Call the new, integrated cubit function.
      context.read<InventoryCubit>().addInventoryUsage(
            plotId: widget.plot.plotId,
            product: _selectedItem!, // Pass the selected InventoryProduct
            quantityUsed: double.parse(quantityController.text),
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
            "إدارة المخزون - ${widget.plot.name}",
            style: TextStyle(
              fontFamily: GoogleFonts.readexPro().fontFamily,
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          backgroundColor: AppColor.green,
          elevation: 0,
        ),
        body: BlocProvider(
          create: (context) =>
              sl<InventoryCubit>()..fetchInventoryPageData(widget.plot.plotId),
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
                  _selectedItem = null; // Reset dropdown
                  selectedDate = DateTime.now();
                  // totalCost = 0.0; // REMOVED
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
              // Use Builder to get correct context for submit button
              return Builder(builder: (innerContext) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    children: [
                      // Pass the innerContext to the form builder
                      _buildInputForm(innerContext, state),
                      const SizedBox(height: 20),
                      if (userRole == 'owner')
                        _buildHistorySection(innerContext, state),
                      // Pass innerContext
                    ],
                  ),
                );
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInputForm(BuildContext context, InventoryStates state) {
    // --- UPDATED: Get products from the correct state ---
    final availableProducts = (state is InventoryPageLoaded)
        ? state.availableProducts
        : <InventoryProduct>[];
    final filteredItems = availableProducts
        .where((item) => item.category == _categories[_selectedCategoryIndex])
        .toList();

    return Card(
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
                  Icon(Icons.inventory_2, color: Colors.brown[900], size: 28),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      "بيانات استخدام المخزون",
                      style: TextStyle(
                        fontFamily: GoogleFonts.readexPro().fontFamily,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown[900],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- NEW: Category Selector ---
              _buildCategorySelector(),
              const SizedBox(height: 16),

              // --- UPDATED: Replaced TextFormField with Dropdown ---
              DropdownButtonFormField<InventoryProduct>(
                // <-- CHANGED Type
                initialValue: _selectedItem,
                hint: const Text("اختر الصنف"),
                isExpanded: true,
                items: filteredItems.map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(
                        "${item.itemName} (المتوفر: ${item.totalStock} ${item.unit})"), // <-- Use data from InventoryProduct
                  );
                }).toList(),
                onChanged: (item) {
                  setState(() {
                    _selectedItem = item;
                    // REMOVED _calculateTotalCost()
                  });
                },
                validator: (value) => value == null ? "يرجى اختيار صنف" : null,
                decoration: _inputDecoration(labelText: "اختر المنتج"),
              ),
              const SizedBox(height: 16),

              // Date picker is kept from your original code, although the new cubit uses server time.
              // You might want to remove this field if the date is always "now".
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: _inputDecoration(labelText: "تاريخ الاستخدام"),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        convertToArabicNumbers(
                            DateFormat('dd-MM-yyyy').format(selectedDate)),
                        style: TextStyle(
                          fontFamily: GoogleFonts.readexPro().fontFamily,
                          color: Colors.brown[900],
                        ),
                      ),
                      Icon(Icons.calendar_today, color: Colors.brown[700]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration(
                    labelText:
                        "الكمية المستخدمة (${_selectedItem?.unit ?? '...'})"),
                // Show unit dynamically
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "يرجى إدخال الكمية";
                  }
                  final num = double.tryParse(value);
                  if (num == null || num <= 0) {
                    return "يرجى إدخال كمية صحيحة (أكبر من 0)";
                  }
                  // --- UPDATED: Check against product's totalStock ---
                  if (_selectedItem != null &&
                      num > _selectedItem!.totalStock) {
                    return "الكمية أكبر من المتوفر في المخزن";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // --- REMOVED unitCost TextFormField ---
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                // Align button to the end
                children: [
                  // --- REMOVED Total cost display ---
                  ElevatedButton(
                    onPressed: state is InventoryLoadingState
                        ? null
                        : () => _submitForm(context), // Pass context
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
                              fontFamily: GoogleFonts.readexPro().fontFamily,
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
    );
  }

  Widget _buildHistorySection(BuildContext context, InventoryStates state) {
    // --- UPDATED LOGIC: Get history from the correct state ---
    if (state is! InventoryPageLoaded) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Your original history section layout starts here
    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.history, color: Colors.brown[900], size: 28),
            const SizedBox(width: 8),
            Text(
              "سِجل استخدام المخزون",
              style: TextStyle(
                fontFamily: GoogleFonts.readexPro().fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.brown[900],
              ),
            ),
            const Spacer(),
            ToggleButtons(
              borderRadius: BorderRadius.circular(15),
              isSelected: [showListView, !showListView],
              onPressed: (index) {
                setState(() {
                  showListView = index == 0;
                });
              },
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(Icons.view_list),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(Icons.table_view),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.65,
          child: Card(
            clipBehavior: Clip.antiAlias,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Colors.brown[50],
            child: state.history.isEmpty
                ? const Center(child: Text("لا يوجد سجل استخدام مخزون بعد"))
                : showListView
                    ? _buildHistoryListView(context, state.history)
                    : _buildHistoryTableView(context, state.history),
          ),
        )
      ],
    );
  }

  // --- YOUR ORIGINAL HISTORY LIST VIEW ---
  Widget _buildHistoryListView(
      BuildContext context, List<InventoryModel> history) {
    return ListView.builder(
      itemCount: history.length,
      itemBuilder: (context, index) {
        final inventory = history[index];
        final dayOrNight =
            DateFormat('a', 'ar').format(inventory.date); // Use 'ar' locale
        final String hourType =
            dayOrNight == 'ص' ? 'صباحاً' : 'مساءً'; // Check Arabic AM/PM
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          child: ExpansionTile(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            collapsedBackgroundColor: Colors.white30,
            backgroundColor: Colors.white60,
            collapsedShape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            collapsedIconColor: Colors.brown[900],
            iconColor: Colors.brown[900],
            textColor: Colors.brown[900],
            collapsedTextColor: Colors.brown[900],
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: Colors.white,
              child:
                  Icon(Icons.inventory_2, color: Colors.brown[900], size: 20),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    inventory.itemId, // Shows product name
                    style: TextStyle(
                      fontFamily: GoogleFonts.readexPro().fontFamily,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  convertToArabicNumbers(
                      DateFormat('dd-MM-yyyy').format(inventory.date)),
                  style: TextStyle(
                    fontFamily: GoogleFonts.readexPro().fontFamily,
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            subtitle: Text(
              "الكمية: ${convertToArabicNumbers(inventory.quantityUsed.toString())}", // Removed 'k' unit
              style: const TextStyle(color: Colors.black54),
            ),
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        "الوقت: ${convertToArabicNumbers(DateFormat('hh:mm').format(inventory.date))} $hourType",
                        style: const TextStyle(color: Colors.black54)),
                    Text(
                        "تكلفة الوحدة: ${convertToArabicNumbers(inventory.itemUnitCost.toStringAsFixed(2))} جنيه",
                        // Show unit cost from log
                        style: const TextStyle(color: Colors.black54)),
                    Text(
                        "الإجمالي: ${convertToArabicNumbers(inventory.inventoryTotalCost.toStringAsFixed(2))} جنيه", // Show total cost from log
                        style: const TextStyle(color: Colors.black54)),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.center,
                      child: CircleAvatar(
                        backgroundColor: Colors.grey.withAlpha(50),
                        child: IconButton(
                          icon: const Icon(Icons.delete,
                              color: Colors.red, size: 20),
                          onPressed: () {
                            _deleteButton(context, widget.plot.plotId,
                                inventory); // Pass InventoryModel
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
    );
  }

  // --- YOUR ORIGINAL HISTORY TABLE VIEW ---
  Widget _buildHistoryTableView(
      BuildContext context, List<InventoryModel> history) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        border: TableBorder.all(
          color: Colors.grey.shade300,
          width: 1.2,
        ),
        columns: const [
          DataColumn(label: Text('الرقم')),
          DataColumn(label: Text('المنتج')),
          DataColumn(label: Text('التاريخ')),
          DataColumn(label: Text('الكمية')),
          DataColumn(label: Text('تكلفة الوحدة')),
          DataColumn(label: Text('الإجمالي')),
          DataColumn(label: Text('الإجراء')),
        ],
        rows: history.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final inventory = entry.value;
          final dayOrNight = DateFormat('a', 'ar').format(inventory.date);
          final hourType = dayOrNight == 'ص' ? 'صباحاً' : 'مساءً';
          return DataRow(cells: [
            DataCell(Text(convertToArabicNumbers(index.toString()))),
            DataCell(Text(inventory.itemId)),
            DataCell(Text(
                '${convertToArabicNumbers(DateFormat('dd-MM-yyyy , hh:mm').format(inventory.date))} $hourType')),
            DataCell(Text(
                convertToArabicNumbers(inventory.quantityUsed.toString()))),
            // Removed 'k' unit
            DataCell(Text(
                '${convertToArabicNumbers(inventory.itemUnitCost.toStringAsFixed(2))} جنيه')),
            DataCell(Text(
                '${convertToArabicNumbers(inventory.inventoryTotalCost.toStringAsFixed(2))} جنيه')),
            DataCell(IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                _deleteButton(context, widget.plot.plotId,
                    inventory); // Pass InventoryModel
              },
            )),
          ]);
        }).toList(),
      ),
    );
  }

  // --- YOUR ORIGINAL HELPER WIDGETS ---

  Widget _buildCategorySelector() {
    return ToggleButtons(
      isSelected: [_selectedCategoryIndex == 0, _selectedCategoryIndex == 1],
      onPressed: (int index) {
        setState(() {
          _selectedCategoryIndex = index;
          _selectedItem = null; // Reset dropdown on category change
          // _totalCost = 0.0; // REMOVED
        });
      },
      borderRadius: BorderRadius.circular(12.0),
      selectedBorderColor: AppColor.green,
      selectedColor: Colors.white,
      fillColor: AppColor.green,
      color: AppColor.green,
      constraints: BoxConstraints(
        minHeight: 45.0,
        minWidth: (MediaQuery.of(context).size.width - 100) /
            2, // Adjust width based on padding
      ),
      children: const [
        Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('تسميد')),
        Padding(
            padding: EdgeInsets.symmetric(horizontal: 16), child: Text('رش')),
      ],
    );
  }

  InputDecoration _inputDecoration({String? labelText}) {
    // Your original input decoration
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(color: Colors.brown[700]),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Future<void> _deleteButton(BuildContext parentContext, String plotId,
      InventoryModel usageLog) async {
    // <-- UPDATED to accept InventoryModel
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
                    // --- UPDATED: Call the new delete method ---
                    parentContext.read<InventoryCubit>().deleteInventoryUsage(
                        plotId: plotId, usageLog: usageLog);
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
