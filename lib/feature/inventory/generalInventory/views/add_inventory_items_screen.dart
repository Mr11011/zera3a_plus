import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;
import '../../../../core/utils/colors.dart';
import '../controlller/general_inventory_cubit.dart';
import '../controlller/general_inventory_states.dart';
import '../data/purchase_batch_model.dart';

class AddInventoryProductScreen extends StatefulWidget {
  const AddInventoryProductScreen({super.key});

  @override
  State<AddInventoryProductScreen> createState() =>
      _AddInventoryProductScreenState();
}

class _AddInventoryProductScreenState extends State<AddInventoryProductScreen> {
  final _formKey = GlobalKey<FormState>();

  final _itemNameController = TextEditingController();
  final _vendorController = TextEditingController();
  final _originController = TextEditingController();
  final _initialQuantityController = TextEditingController();

  final _totalCostController = TextEditingController();

  String _selectedUnit = 'كيلو';
  final _units = ['كيلو', "جرام", 'لتر', "سم", 'شيكارة', 'وحدة'];

  DateTime _selectedDate = DateTime.now();
  int _selectedCategoryIndex = 0;
  final List<String> _categories = ['تسميد', 'رش'];

  @override
  void dispose() {
    _itemNameController.dispose();
    _vendorController.dispose();
    _originController.dispose();
    _initialQuantityController.dispose();
    _totalCostController.dispose();
    super.dispose();
  }

  void _submitForm() {
    // 1. Validate the form fields.
    if (_formKey.currentState!.validate()) {
      // 2. Read the cubit instance provided from the previous screen.
      final cubit = context.read<GeneralInventoryCubit>();

      // 3. Parse user input.
      final initialQuantity =
          double.tryParse(_initialQuantityController.text) ?? 0;
      final totalCost = double.tryParse(_totalCostController.text) ?? 0;

      if (initialQuantity <= 0) {
        Fluttertoast.showToast(
            msg: "الكمية يجب أن تكون أكبر من صفر", backgroundColor: Colors.red);
        return;
      }

      final costPerUnit = totalCost / initialQuantity;

      // 4. Create the first purchase batch model.
      final firstBatch = PurchaseBatch(
        id: '',
        // Firestore will generate this ID.
        vendor: _vendorController.text.trim(),
        origin: _originController.text.trim(),
        purchaseDate: _selectedDate,
        initialQuantity: initialQuantity,
        currentQuantity: initialQuantity,
        totalCost: totalCost,
        costPerUnit: costPerUnit,
      );

      // 5. Call the cubit method to create the new product.
      // The cubit will handle the loading state, Firestore transaction, and success/error states.
      cubit.createNewProductWithFirstBatch(
        itemName: _itemNameController.text.trim(),
        category: _categories[_selectedCategoryIndex],
        unit: _selectedUnit,
        firstBatch: firstBatch,
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColor.green,
              onPrimary: Colors.white,
              surface: AppColor.beige,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColor.beige.withValues(alpha: 0.5),
        appBar: AppBar(
          iconTheme: IconThemeData(color: AppColor.green),
          title: Text('إضافة صنف للمخزن',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: AppColor.darkGreen)),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        // The BlocListener handles UI side-effects like showing toasts and navigating.
        body: BlocListener<GeneralInventoryCubit, GeneralInventoryStates>(
          listener: (context, state) {
            if (state is GeneralInventorySuccess) {
              Fluttertoast.showToast(msg: state.message);
              if (mounted) {
                Navigator.pop(context, true); // Return true to indicate success
              }
            }
            if (state is GeneralInventoryError) {
              Fluttertoast.showToast(
                  msg: state.message, backgroundColor: Colors.red);
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionCard(
                    title: 'بيانات الصنف',
                    icon: Icons.inventory_2_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Text('نوع الصنف',
                              style: TextStyle(
                                  color: AppColor.medBrown, fontSize: 16)),
                        ),
                        _buildCategorySelector(),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _itemNameController,
                          label: 'اسم الصنف',
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                            controller: _vendorController, label: 'المورد'),
                        const SizedBox(height: 16),
                        _buildTextField(
                            controller: _originController, label: 'بلد المنشأ'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionCard(
                    title: 'الكمية والتكلفة (أول شحنة)',
                    icon: Icons.monetization_on_outlined,
                    child: Column(
                      children: [
                        _buildDatePicker(),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: _buildTextField(
                                controller: _initialQuantityController,
                                label: 'الكمية الإجمالية',
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: _buildUnitDropdown(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _totalCostController,
                          label: 'التكلفة الإجمالية (جنيه)',
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    // The BlocBuilder handles rebuilding the UI based on state (e.g., showing a loading indicator).
                    child: BlocBuilder<GeneralInventoryCubit,
                        GeneralInventoryStates>(
                      builder: (context, state) {
                        if (state is GeneralInventoryLoading) {
                          return Center(
                              child: CircularProgressIndicator(
                            color: AppColor.green,
                          ));
                        }
                        return _buildSubmitButton();
                      },
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

  // --- Helper Widgets ---

  Widget _buildCategorySelector() {
    return ToggleButtons(
      isSelected: [_selectedCategoryIndex == 0, _selectedCategoryIndex == 1],
      onPressed: (int index) {
        setState(() {
          _selectedCategoryIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(12.0),
      selectedBorderColor: AppColor.green,
      selectedColor: Colors.white,
      fillColor: AppColor.green,
      color: AppColor.green,
      constraints: BoxConstraints(
        minHeight: 45.0,
        minWidth: (MediaQuery.of(context).size.width - 80) / 2,
      ),
      children: const [
        Text('تسميد', style: TextStyle(fontWeight: FontWeight.bold)),
        Text('رش', style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColor.medBrown),
        filled: true,
        fillColor: AppColor.beige.withOpacity(0.5),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColor.green)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColor.darkGreen, width: 2),
        ),
      ),
      keyboardType: keyboardType,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'يرجى إدخال $label';
        }
        if (keyboardType == TextInputType.number &&
            double.tryParse(value) == null) {
          return 'يرجى إدخال رقم صحيح';
        }
        return null;
      },
    );
  }

  Widget _buildUnitDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedUnit,
      decoration: InputDecoration(
        labelText: 'الوحدة',
        labelStyle: TextStyle(color: AppColor.medBrown),
        filled: true,
        fillColor: AppColor.beige.withOpacity(0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: _units.map((String unit) {
        return DropdownMenuItem<String>(
          value: unit,
          child: Text(unit),
        );
      }).toList(),
      onChanged: (newValue) {
        setState(() {
          _selectedUnit = newValue!;
        });
      },
    );
  }

  Widget _buildSectionCard(
      {required String title, required IconData icon, required Widget child}) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColor.medBrown, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColor.darkGreen),
                ),
              ],
            ),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton.icon(
      onPressed: _submitForm,
      icon: const Icon(Icons.save_alt_outlined),
      label: const Text('حفظ الصنف'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: AppColor.green,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: "تاريخ الشراء",
          labelStyle: TextStyle(color: AppColor.medBrown),
          filled: true,
          fillColor: AppColor.beige.withOpacity(0.5),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              textDirection: TextDirection.rtl,
              DateFormat('dd / MM /yyyy', 'ar').format(_selectedDate),
              style: TextStyle(fontSize: 16, color: AppColor.darkGreen),
            ),
            Icon(Icons.calendar_today, color: AppColor.medBrown),
          ],
        ),
      ),
    );
  }
}

//
// class AddGeneralInventoryItemScreen extends StatefulWidget {
//   const AddGeneralInventoryItemScreen({super.key});
//
//   @override
//   State<AddGeneralInventoryItemScreen> createState() =>
//       _AddGeneralInventoryItemScreenState();
// }
//
// class _AddGeneralInventoryItemScreenState
//     extends State<AddGeneralInventoryItemScreen> {
//   final _formKey = GlobalKey<FormState>();
//
//   final _itemNameController = TextEditingController();
//   final _vendorController = TextEditingController();
//   final _originController = TextEditingController();
//   final _initialQuantityController = TextEditingController();
//   final _totalCostController = TextEditingController();
//
//   String _selectedUnit = 'كيلو';
//   final _units = ['كيلو', 'لتر', 'شيكارة', 'وحدة'];
//   DateTime _selectedDate = DateTime.now();
//
//   int _selectedCategoryIndex = 0; // 0 for 'تسميد', 1 for 'رش'
//   final List<String> _categories = ['تسميد', 'رش'];
//
//   @override
//   void dispose() {
//     _itemNameController.dispose();
//     _vendorController.dispose();
//     _originController.dispose();
//     _initialQuantityController.dispose();
//     _totalCostController.dispose();
//     super.dispose();
//   }
//
//   void _submitForm() {
//     if (_formKey.currentState!.validate()) {
//       final double initialQuantity =
//           double.tryParse(_initialQuantityController.text) ?? 0;
//       final double totalCost =
//           double.tryParse(_totalCostController.text) ?? 0;
//
//       context.read<GeneralInventoryCubit>().addInventoryItem(
//         itemName: _itemNameController.text,
//         category: _categories[_selectedCategoryIndex],
//         vendor: _vendorController.text,
//         origin: _originController.text,
//         purchaseDate: _selectedDate,
//         initialQuantity: initialQuantity,
//         unit: _selectedUnit,
//         totalCost: totalCost,
//       );
//     }
//   }
//
//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: _selectedDate,
//       firstDate: DateTime(2020),
//       lastDate: DateTime.now(),
//       builder: (context, child) {
//         return Theme(
//           data: ThemeData.light().copyWith(
//             colorScheme: ColorScheme.light(
//               primary: AppColor.green,
//               onPrimary: Colors.white,
//               surface: AppColor.beige,
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );
//     if (picked != null && picked != _selectedDate) {
//       setState(() {
//         _selectedDate = picked;
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Directionality(
//       textDirection: TextDirection.rtl,
//       child: Scaffold(
//         backgroundColor: AppColor.beige.withValues(alpha: 0.5),
//         appBar: AppBar(
//           iconTheme: IconThemeData(color: AppColor.green),
//           title: Text('إضافة صنف للمخزن',
//               style: TextStyle(
//                   fontWeight: FontWeight.bold, color: AppColor.darkGreen)),
//           backgroundColor: Colors.white,
//           elevation: 0,
//         ),
//         body: BlocListener<GeneralInventoryCubit, GeneralInventoryStates>(
//           listener: (context, state) {
//             if (state is GeneralInventoryItemAdded) {
//               Fluttertoast.showToast(msg: "تم إضافة الصنف بنجاح");
//               Navigator.pop(context);
//             }
//             if (state is GeneralInventoryError) {
//               Fluttertoast.showToast(
//                   msg: state.message, backgroundColor: Colors.red);
//             }
//           },
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(16.0),
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   _buildSectionCard(
//                     title: 'بيانات الصنف',
//                     icon: Icons.inventory_2_outlined,
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Padding(
//                           padding: const EdgeInsets.only(bottom: 16.0),
//                           child: Text('نوع الصنف', style: TextStyle(color: AppColor.medBrown, fontSize: 16)),
//                         ),
//                         _buildCategorySelector(),
//                         const SizedBox(height: 16),
//                         _buildTextField(
//                             controller: _itemNameController,
//                             label: 'اسم الصنف'),
//                         const SizedBox(height: 16),
//                         _buildTextField(
//                             controller: _vendorController, label: 'المورد'),
//                         const SizedBox(height: 16),
//                         _buildTextField(
//                             controller: _originController,
//                             label: 'بلد المنشأ'),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 24),
//                   _buildSectionCard(
//                     title: 'الكمية والتكلفة',
//                     icon: Icons.monetization_on_outlined,
//                     child: Column(
//                       children: [
//                         _buildDatePicker(),
//                         const SizedBox(height: 16),
//                         Row(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Expanded(
//                               flex: 3,
//                               child: _buildTextField(
//                                 controller: _initialQuantityController,
//                                 label: 'الكمية الإجمالية',
//                                 keyboardType: TextInputType.number,
//                               ),
//                             ),
//                             const SizedBox(width: 12),
//                             Expanded(
//                               flex: 2,
//                               child: _buildUnitDropdown(),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 16),
//                         _buildTextField(
//                           controller: _totalCostController,
//                           label: 'التكلفة الإجمالية (جنيه)',
//                           keyboardType: TextInputType.number,
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 32),
//                   SizedBox(
//                     width: double.infinity,
//                     child: BlocBuilder<GeneralInventoryCubit,
//                         GeneralInventoryStates>(
//                       builder: (context, state) {
//                         if (state is GeneralInventoryLoading) {
//                           return Center(
//                               child: CircularProgressIndicator(
//                                 color: AppColor.green,
//                               ));
//                         }
//                         return _buildSubmitButton();
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildCategorySelector() {
//     return ToggleButtons(
//       isSelected: [_selectedCategoryIndex == 0, _selectedCategoryIndex == 1],
//       onPressed: (int index) {
//         setState(() {
//           _selectedCategoryIndex = index;
//         });
//       },
//       borderRadius: BorderRadius.circular(12.0),
//       selectedBorderColor: AppColor.green,
//       selectedColor: Colors.white,
//       fillColor: AppColor.green,
//       color: AppColor.green,
//       constraints: BoxConstraints(
//         minHeight: 45.0,
//         minWidth: (MediaQuery.of(context).size.width - 80) / 2,
//       ),
//       children: const [
//         Text('تسميد', style: TextStyle(fontWeight: FontWeight.bold)),
//         Text('رش', style: TextStyle(fontWeight: FontWeight.bold)),
//       ],
//     );
//   }
//
//   Widget _buildSectionCard(
//       {required String title,
//         required IconData icon,
//         required Widget child}) {
//     return Card(
//       elevation: 2,
//       color: Colors.white,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(icon, color: AppColor.medBrown, size: 24),
//                 const SizedBox(width: 8),
//                 Text(
//                   title,
//                   style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: AppColor.darkGreen),
//                 ),
//               ],
//             ),
//             const Divider(height: 24),
//             child,
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildTextField(
//       {required TextEditingController controller,
//         required String label,
//         TextInputType? keyboardType}) {
//     return TextFormField(
//       controller: controller,
//       decoration: InputDecoration(
//         labelText: label,
//         labelStyle: TextStyle(color: AppColor.medBrown),
//         filled: true,
//         fillColor: AppColor.beige.withOpacity(0.5),
//         border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: BorderSide(color: AppColor.green)),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: AppColor.darkGreen, width: 2),
//         ),
//       ),
//       keyboardType: keyboardType,
//       validator: (value) {
//         if (value == null || value.isEmpty) {
//           return 'يرجى إدخال $label';
//         }
//         if (keyboardType == TextInputType.number &&
//             double.tryParse(value) == null) {
//           return 'يرجى إدخال رقم صحيح';
//         }
//         return null;
//       },
//     );
//   }
//
//   Widget _buildDatePicker() {
//     return InkWell(
//       onTap: () => _selectDate(context),
//       child: InputDecorator(
//         decoration: InputDecoration(
//           labelText: "تاريخ الشراء",
//           labelStyle: TextStyle(color: AppColor.medBrown),
//           filled: true,
//           fillColor: AppColor.beige.withOpacity(0.5),
//           border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(
//               DateFormat('yyyy / MM / dd', 'ar').format(_selectedDate),
//               style: TextStyle(fontSize: 16, color: AppColor.darkGreen),
//             ),
//             Icon(Icons.calendar_today, color: AppColor.medBrown),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildUnitDropdown() {
//     return DropdownButtonFormField<String>(
//       value: _selectedUnit,
//       decoration: InputDecoration(
//         labelText: 'الوحدة',
//         labelStyle: TextStyle(color: AppColor.medBrown),
//         filled: true,
//         fillColor: AppColor.beige.withOpacity(0.5),
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//       ),
//       items: _units.map((String unit) {
//         return DropdownMenuItem<String>(
//           value: unit,
//           child: Text(unit),
//         );
//       }).toList(),
//       onChanged: (newValue) {
//         setState(() {
//           _selectedUnit = newValue!;
//         });
//       },
//     );
//   }
//
//   Widget _buildSubmitButton() {
//     return ElevatedButton.icon(
//       onPressed: _submitForm,
//       icon: const Icon(Icons.save_alt_outlined),
//       label: const Text('حفظ الصنف'),
//       style: ElevatedButton.styleFrom(
//         padding: const EdgeInsets.symmetric(vertical: 16),
//         backgroundColor: AppColor.green,
//         foregroundColor: Colors.white,
//         textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12),
//         ),
//       ),
//     );
//   }
// }
//
