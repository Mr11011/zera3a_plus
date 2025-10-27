import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;
import 'package:zera3a/core/constants/app_const.dart';
import '../../../../core/di.dart';
import '../../../../core/utils/colors.dart';
import '../controlller/general_inventory_cubit.dart';
import '../controlller/general_inventory_states.dart';
import '../data/inventory_product_model.dart';
import '../data/purchase_batch_model.dart';
import 'edit_batch_screen.dart';
import 'edit_general_inventory_screen.dart';

class AddPurchaseBatchScreen extends StatefulWidget {
  final InventoryProduct product;

  const AddPurchaseBatchScreen({super.key, required this.product});

  @override
  State<AddPurchaseBatchScreen> createState() => _AddPurchaseBatchScreenState();
}

class _AddPurchaseBatchScreenState extends State<AddPurchaseBatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vendorController = TextEditingController();
  final _originController = TextEditingController();
  final _initialQuantityController = TextEditingController();
  final _totalCostController = TextEditingController();
  DateTime _purchaseDate = DateTime.now();

  @override
  void dispose() {
    _vendorController.dispose();
    _originController.dispose();
    _initialQuantityController.dispose();
    _totalCostController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final double initialQuantity =
          double.tryParse(_initialQuantityController.text) ?? 0;
      final double totalCost = double.tryParse(_totalCostController.text) ?? 0;

      final newBatch = PurchaseBatch(
        id: '',
        // Firestore will generate this
        vendor: _vendorController.text.trim(),
        origin: _originController.text.trim(),
        purchaseDate: _purchaseDate,
        initialQuantity: initialQuantity,
        currentQuantity: initialQuantity,
        totalCost: totalCost,
        costPerUnit: initialQuantity > 0 ? totalCost / initialQuantity : 0,
      );

      context.read<GeneralInventoryCubit>().addPurchaseBatch(
            productId: widget.product.id,
            batchData: newBatch,
          );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColor.green,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _purchaseDate) {
      setState(() {
        _purchaseDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColor.beige,
        appBar: AppBar(
          iconTheme: IconThemeData(color: AppColor.green),
          title: Text('إضافة شحنة جديدة',
              style: TextStyle(
                  color: AppColor.darkGreen, fontWeight: FontWeight.bold)),
          backgroundColor: AppColor.beige,
          elevation: 0,
        ),
        bottomNavigationBar: _buildSaveButton(),
        body: BlocListener<GeneralInventoryCubit, GeneralInventoryStates>(
          listener: (context, state) {
            if (state is GeneralInventorySuccess) {
              Navigator.of(context).pop();
            } else if (state is GeneralInventoryError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColor.medBrown,
                ),
              );
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Card(
                elevation: 2,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(
                          'بيانات الشحنة لـ "${widget.product.itemName}"'),
                      const Divider(height: 24),
                      _buildTextField(
                        controller: _initialQuantityController,
                        labelText: 'الكمية المستلمة (${widget.product.unit})',
                        icon: Icons.format_list_numbered,
                        keyboardType: TextInputType.number,
                        validator: (v) => (v?.trim().isEmpty ?? true)
                            ? 'يرجى إدخال الكمية'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _totalCostController,
                        labelText: 'التكلفة الإجمالية للشحنة',
                        icon: Icons.monetization_on_outlined,
                        keyboardType: TextInputType.number,
                        validator: (v) => (v?.trim().isEmpty ?? true)
                            ? 'يرجى إدخال التكلفة'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _vendorController,
                        labelText: 'اسم المورد',
                        icon: Icons.store_mall_directory_outlined,
                        validator: (v) => (v?.trim().isEmpty ?? true)
                            ? 'يرجى إدخال اسم المورد'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _originController,
                        labelText: 'بلد المنشأ',
                        icon: Icons.public_outlined,
                      ),
                      const SizedBox(height: 16),
                      _buildDatePicker(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon, color: AppColor.green.withValues(alpha: 0.7)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColor.green, width: 2),
        ),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: "تاريخ الشراء",
          prefixIcon: Icon(Icons.calendar_today_outlined,
              color: AppColor.green.withValues(alpha: 0.7)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(DateFormat('d MMMM yyyy', 'ar').format(_purchaseDate)),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: AppColor.beige,
      child: BlocBuilder<GeneralInventoryCubit, GeneralInventoryStates>(
        builder: (context, state) {
          final isLoading = state is GeneralInventoryLoading;
          return ElevatedButton(
            onPressed: isLoading ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : const Text('حفظ الشحنة',
                    style: TextStyle(color: Colors.white)),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Text(
        title,
        style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColor.darkGreen),
      ),
    );
  }
}

class ProductDetailScreen extends StatelessWidget {
  final InventoryProduct product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<GeneralInventoryCubit>()
        ..fetchProductDetails(productId: product.id),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            iconTheme: IconThemeData(color: AppColor.green),
            title: Text(product.itemName,
                style: TextStyle(
                    color: AppColor.darkGreen, fontWeight: FontWeight.bold)),
            backgroundColor: AppColor.beige,
            elevation: 0.7,
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider(
                          create: (context) => sl<GeneralInventoryCubit>(),
                          child: EditProductScreen(
                            product: product,
                          ),
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.edit_note, color: AppColor.green, size: 30),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
                child: IconButton(
                  onPressed: () =>
                      _showDeleteProductConfirmationDialog(context, product),
                  icon: Icon(Icons.delete_forever,
                      color: AppColor.medBrown, size: 28),
                ),
              ),
            ],
          ),
          body: BlocListener<GeneralInventoryCubit, GeneralInventoryStates>(
            listener: (context, state) {
              if (state is GeneralInventorySuccess) {
                // When a batch is added or deleted, refresh the details
                context
                    .read<GeneralInventoryCubit>()
                    .fetchProductDetails(productId: product.id);
                Fluttertoast.showToast(msg: state.message);
              }
              if (state is GeneralInventoryItemDeleted) {
                // If the entire product is deleted, pop back
                Navigator.of(context).pop();
              }
              if (state is GeneralInventoryError) {
                Fluttertoast.showToast(
                    msg: state.message, backgroundColor: Colors.red);
              }
            },
            child: BlocBuilder<GeneralInventoryCubit, GeneralInventoryStates>(
              builder: (context, state) {
                if (state is GeneralInventoryLoading ||
                    state is! ProductDetailsLoaded) {
                  return Center(
                      child: CircularProgressIndicator(color: AppColor.green));
                }

                return RefreshIndicator(
                  onRefresh: () => context
                      .read<GeneralInventoryCubit>()
                      .fetchProductDetails(productId: product.id),
                  color: AppColor.green,
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      _buildProductSummaryCard(state.product),
                      const SizedBox(height: 24),
                      _buildBatchesHeader(context, state.product),
                      const SizedBox(height: 8),
                      _buildBatchesList(context, state.batches, state.product),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductSummaryCard(InventoryProduct product) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDetailRow('نوع الصنف:', product.category),
            _buildDetailRow('وحدة القياس:', product.unit),
            const Divider(height: 24),
            Text(
              'إجمالي الكمية المتوفرة',
              style: TextStyle(fontSize: 16, color: AppColor.medBrown),
            ),
            const SizedBox(height: 8),
            Text(
              '${convertToArabicNumbers(NumberFormat.decimalPattern('ar').format(product.totalStock))} ${product.unit}',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColor.darkGreen),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBatchesHeader(BuildContext context, InventoryProduct product) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'سجل الشحنات',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColor.darkGreen),
        ),
        ElevatedButton.icon(
          onPressed: () {
            // Navigate to the new AddPurchaseBatchScreen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<GeneralInventoryCubit>(),
                  child: AddPurchaseBatchScreen(product: product),
                ),
              ),
            );
          },
          icon: const Icon(Icons.add, color: Colors.white, size: 20),
          label:
              const Text('إضافة شحنة', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColor.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBatchesList(BuildContext context, List<PurchaseBatch> batches,
      InventoryProduct product) {
    if (batches.isEmpty) {
      return const Card(
        color: Colors.white,
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(child: Text('لم يتم تسجيل أي شحنات لهذا الصنف بعد.')),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: batches.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final batch = batches[index];
        final stockPercentage = batch.initialQuantity > 0
            ? batch.currentQuantity / batch.initialQuantity
            : 0.0;
        return Card(
          elevation: 1,
          color: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'تاريخ الشراء: ${DateFormat('yyyy/MM/dd', 'ar').format(batch.purchaseDate)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'delete') {
                          _showDeleteBatchConfirmationDialog(
                              context, product, batch);
                        }
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'edit',
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: InkWell(
                              onTap: () {
                                Navigator.pop(context); // Close the popup menu
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BlocProvider.value(
                                      value:
                                          context.read<GeneralInventoryCubit>(),
                                      child: EditPurchaseBatchScreen(
                                        product: product,
                                        batch: batch,
                                      ),
                                    ),
                                  ),
                                );
                              },
                              child: const Row(
                                children: [
                                  Icon(Icons.edit,
                                      color: Colors.blue, size: 20),
                                  SizedBox(width: 4),
                                  Text('تعديل الشحنة')
                                ],
                              ),
                            ),
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline,
                                    color: Colors.red, size: 20),
                                SizedBox(width: 4),
                                Text('حذف الشحنة'),
                              ],
                            ),
                          ),
                        ),
                      ],
                      icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                Text('المورد: ${batch.vendor}',
                    style: TextStyle(color: AppColor.medBrown)),
                const Divider(),
                _buildDetailRow('الكمية الحالية:',
                    '${convertToArabicNumbers(NumberFormat.decimalPattern('ar').format(batch.currentQuantity))} / ${convertToArabicNumbers(NumberFormat.decimalPattern('ar').format(batch.initialQuantity))} ${product.unit}'),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: stockPercentage,
                  backgroundColor: AppColor.beige,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColor.green),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteProductConfirmationDialog(
      BuildContext context, InventoryProduct product) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تأكيد الحذف'),
            content: Text(
                'هل أنت متأكد من حذف صنف "${product.itemName}"؟ سيتم حذف جميع شحناته المسجلة ولا يمكن التراجع عن هذا الإجراء.'),
            actions: [
              TextButton(
                  child: const Text('إلغاء'),
                  onPressed: () => Navigator.of(dialogContext).pop()),
              TextButton(
                child: const Text('حذف', style: TextStyle(color: Colors.red)),
                onPressed: () {
                  context
                      .read<GeneralInventoryCubit>()
                      .deleteProduct(productId: product.id);
                  Navigator.of(dialogContext).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteBatchConfirmationDialog(
      BuildContext context, InventoryProduct product, PurchaseBatch batch) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تأكيد حذف الشحنة'),
            content: Text(
                'هل أنت متأكد من حذف الشحنة بتاريخ ${DateFormat('yyyy/MM/dd', 'ar').format(batch.purchaseDate)}؟'),
            actions: [
              TextButton(
                  child: const Text('إلغاء'),
                  onPressed: () => Navigator.of(dialogContext).pop()),
              TextButton(
                child: const Text('حذف', style: TextStyle(color: Colors.red)),
                onPressed: () {
                  context.read<GeneralInventoryCubit>().deletePurchaseBatch(
                        productId: product.id,
                        batchToDelete: batch,
                      );
                  Navigator.of(dialogContext).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          // mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 15)),
            const SizedBox(
              width: 12,
            ),
            Text(
              value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColor.darkGreen,
                  fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
