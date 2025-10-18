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
import '../generalInventory/data/general_inventory_model.dart';

class InventoryScreen extends StatefulWidget {
  final Plot plot;

  const InventoryScreen({super.key, required this.plot});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _formKey = GlobalKey<FormState>();

  // We only need the quantity controller now
  final _quantityController = TextEditingController();

  // --- NEW State variables for the integrated form ---
  int _selectedCategoryIndex = 0;
  final List<String> _categories = ['تسميد', 'رش'];
  PlotInventory? _selectedItem;
  double _totalCost = 0.0;

  // State for the history view
  bool _showHistoryAsList = true;
  String _userRole = 'owner'; // Default role

  @override
  void initState() {
    super.initState();
    _quantityController.addListener(_calculateTotalCost);
    // In a real app, you would fetch the user's role here.
    // fetchUserRole(_userRole).then((value) => setState(() => _userRole = value));
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  // --- UPDATED LOGIC ---
  void _calculateTotalCost() {
    final quantity = double.tryParse(_quantityController.text) ?? 0.0;
    // The cost is now based on the selected item, not a manual text field
    if (_selectedItem != null) {
      setState(() {
        _totalCost = quantity * _selectedItem!.costPerUnit;
      });
    } else {
      setState(() => _totalCost = 0.0);
    }
  }

  // --- UPDATED LOGIC ---
  void _submitForm(
    BuildContext context,
  ) {
    if (_formKey.currentState!.validate()) {
      if (_selectedItem == null) {
        Fluttertoast.showToast(msg: "يرجى اختيار صنف من المخزن");
        return;
      }
      // Call the new, integrated cubit function
      context.read<InventoryCubit>().addInventoryUsage(
            plotId: widget.plot.plotId,
            item: _selectedItem!,
            quantityUsed: double.parse(_quantityController.text),
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
          elevation: 4,
        ),
        body: BlocProvider(
          // --- UPDATED LOGIC: Call the new fetch method ---
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
                  _quantityController.clear();
                  _selectedItem = null; // Reset dropdown
                  _totalCost = 0.0;
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
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    _buildInputForm(context, state),
                    const SizedBox(height: 20),
                    if (_userRole == 'owner')
                      _buildHistorySection(context, state),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInputForm(BuildContext context, InventoryStates state) {
    // Determine the list of available items ONLY if the state is loaded
    final availableItems = (state is InventoryPageLoaded)
        ? state.availableItems
        : <PlotInventory>[];
    final filteredItems = availableItems
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
                  Text(
                    "بيانات استخدام المخزون",
                    style: TextStyle(
                      fontFamily: GoogleFonts.readexPro().fontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown[900],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- NEW WIDGETS ---
              _buildCategorySelector(),
              const SizedBox(height: 16),

              // --- REPLACED TextFormField with Dropdown ---
              DropdownButtonFormField<PlotInventory>(
                value: _selectedItem,
                hint: const Text("اختر الصنف"),
                isExpanded: true,
                items: filteredItems.map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(
                        "${item.itemName} (المتوفر: ${item.currentQuantity} ${item.unit})"),
                  );
                }).toList(),
                onChanged: (item) {
                  setState(() {
                    _selectedItem = item;
                    _calculateTotalCost();
                  });
                },
                validator: (value) => value == null ? "يرجى اختيار صنف" : null,
                decoration: _inputDecoration(labelText: "اختر المنتج"),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration(labelText: "الكمية المستخدمة"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "يرجى إدخال الكمية";
                  }
                  final num = double.tryParse(value);
                  if (num == null || num <= 0) {
                    return "يرجى إدخال كمية صحيحة (أكبر من 0)";
                  }
                  if (_selectedItem != null &&
                      num > _selectedItem!.currentQuantity) {
                    return "الكمية أكبر من المتوفر في المخزن";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      "الإجمالي: ${convertToArabicNumbers(_totalCost.toStringAsFixed(2))} جنيه",
                      style: TextStyle(
                        fontFamily: GoogleFonts.readexPro().fontFamily,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _totalCost > 0 ? Colors.green[800] : Colors.grey,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _submitForm(context),
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
      // Show a loader or empty box while the initial data is loading
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
    }

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
              isSelected: [_showHistoryAsList, !_showHistoryAsList],
              onPressed: (index) {
                setState(() {
                  _showHistoryAsList = index == 0;
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
                : _showHistoryAsList
                    ? _buildHistoryListView(context, state.history)
                    : _buildHistoryTableView(context, state.history),
          ),
        )
      ],
    );
  }

  Widget _buildHistoryListView(
      BuildContext context, List<InventoryModel> history) {
    return ListView.builder(
      itemCount: history.length,
      itemBuilder: (context, index) {
        final inventory = history[index];
        return ExpansionTile(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          collapsedShape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.inventory_2, color: Colors.brown[900], size: 20),
          ),
          title: Text(
            inventory.itemId,
            style: TextStyle(
                fontFamily: GoogleFonts.readexPro().fontFamily,
                fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
              "الكمية: ${convertToArabicNumbers(inventory.quantityUsed.toString())}"),
          trailing: Text(convertToArabicNumbers(
              DateFormat('dd / MM /yyyy', 'ar').format(inventory.date))),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildDetailRow("تكلفة الوحدة:",
                      "${convertToArabicNumbers(inventory.itemUnitCost.toStringAsFixed(2))} جنيه"),
                  _buildDetailRow("الإجمالي:",
                      "${convertToArabicNumbers(inventory.inventoryTotalCost.toStringAsFixed(2))} جنيه"),
                  const SizedBox(height: 10),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () =>
                        _deleteButton(context, widget.plot.plotId, inventory),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHistoryTableView(
      BuildContext context, List<InventoryModel> history) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('الصنف')),
          DataColumn(label: Text('الكمية')),
          DataColumn(label: Text('التكلفة')),
          DataColumn(label: Text('التاريخ')),
          DataColumn(label: Text('إجراء')),
        ],
        rows: history.map((inventory) {
          return DataRow(cells: [
            DataCell(Text(inventory.itemId)),
            DataCell(Text(
                convertToArabicNumbers(inventory.quantityUsed.toString()))),
            DataCell(Text(convertToArabicNumbers(
                inventory.inventoryTotalCost.toStringAsFixed(2)))),
            DataCell(Text(convertToArabicNumbers(
                DateFormat('yyyy/MM/dd').format(inventory.date)))),
            DataCell(IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () =>
                  _deleteButton(context, widget.plot.plotId, inventory),
            )),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label), Text(value)],
    );
  }

  Widget _buildCategorySelector() {
    return ToggleButtons(
      isSelected: [_selectedCategoryIndex == 0, _selectedCategoryIndex == 1],
      onPressed: (int index) {
        setState(() {
          _selectedCategoryIndex = index;
          _selectedItem = null;
          _totalCost = 0.0;
        });
      },
      borderRadius: BorderRadius.circular(12.0),
      selectedBorderColor: AppColor.green,
      selectedColor: Colors.white,
      fillColor: AppColor.green,
      color: AppColor.green,
      constraints: BoxConstraints(
        minHeight: 45.0,
        minWidth: (MediaQuery.of(context).size.width - 100) / 2,
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
    return showDialog(
      context: parentContext,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
            content: const Text("هل انت متأكد من حذف البيانات؟"),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("الغاء")),
              ElevatedButton(
                  onPressed: () {
                    // --- UPDATED LOGIC: Call the new delete method ---
                    parentContext.read<InventoryCubit>().deleteInventoryUsage(
                        plotId: plotId, usageLog: usageLog);
                    Navigator.of(context).pop();
                  },
                  child: const Text("حذف", style: TextStyle(color: Colors.red)))
            ]),
      ),
    );
  }
}
