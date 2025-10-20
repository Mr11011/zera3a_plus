import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:zera3a/core/constants/app_const.dart';
import '../controlller/general_inventory_cubit.dart';
import 'package:zera3a/core/di.dart';
import '../../../../core/utils/colors.dart';
import '../controlller/general_inventory_states.dart';
import '../data/inventory_product_model.dart';
import 'add_inventory_items_screen.dart';
import 'inventory_details_screen.dart';

class GeneralInventoryScreen extends StatelessWidget {
  const GeneralInventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: BlocBuilder<GeneralInventoryCubit, GeneralInventoryStates>(
          builder: (context, state) {
            if (state is GeneralInventoryLoading) {
              return Center(
                  child: CircularProgressIndicator(color: AppColor.green));
            }

            if (state is GeneralInventoryError) {
              return _buildErrorWidget(context, 'state.message');
            }

            if (state is ProductsLoaded) {
              if (state.products.isEmpty) {
                return _buildEmptyStateWidget(context);
              }
              return RefreshIndicator(
                onRefresh: () =>
                    context.read<GeneralInventoryCubit>().fetchProducts(),
                color: AppColor.green,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 8.0),
                  itemCount: state.products.length,
                  itemBuilder: (context, index) {
                    final product = state.products[index];
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: _buildListItemCard(context, product),
                    );
                  },
                ),
              );
            }

            return Center(
                child: CircularProgressIndicator(color: AppColor.green));
          },
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: ' add_inventory_product',
          onPressed: () {
            final existingCubit = context.read<GeneralInventoryCubit>();

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: existingCubit,
                  child: const AddInventoryProductScreen(),
                ),
              ),
            ).then((result) {
              if (result == true && context.mounted) {
                existingCubit.fetchProducts();
              }
            });
          },
          backgroundColor: AppColor.green,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  /// --- YOUR CARD WIDGET, NOW WITH THE PROGRESS BAR RESTORED ---
  Widget _buildListItemCard(BuildContext context, InventoryProduct product) {
    // The progress bar calculation now works because our backend provides the necessary data.
    final stockPercentage = product.totalInitialStock > 0
        ? product.totalStock / product.totalInitialStock
        : 0.0;
    final categoryColor =
        product.category == 'تسميد' ? AppColor.green : Colors.blue;

    return Card(
      color: Colors.white70.withAlpha(204), // 0.8 alpha
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (context) => sl<GeneralInventoryCubit>(),
                child: ProductDetailScreen(product: product),
              ),
            ),
          ).then((_) {
            // This code runs when you pop back from the detail screen.
            if (context.mounted) {
              context.read<GeneralInventoryCubit>().fetchProducts();
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      product.itemName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColor.darkGreen,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: categoryColor.withAlpha(38), // 0.15 alpha
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      product.category,
                      style: TextStyle(
                        color: categoryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'الكمية المتبقية:',
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
                  ),
                  Text(
                    '${convertToArabicNumbers(NumberFormat.decimalPattern('ar').format(product.totalStock))} ${product.unit}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColor.darkGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // --- THE PROGRESS BAR, RESTORED AND FULLY FUNCTIONAL ---
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: stockPercentage,
                  minHeight: 8,
                  backgroundColor: Colors.greenAccent.withValues(alpha: 0.4),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    stockPercentage > 0.5
                        ? AppColor.green
                        : stockPercentage > 0.2
                            ? AppColor.flaxBeige
                            : AppColor.medBrown,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets for Error and Empty States ---

  Widget _buildErrorWidget(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: AppColor.medBrown, size: 50),
          const SizedBox(height: 16),
          Text(message,
              style: TextStyle(color: AppColor.medBrown, fontSize: 16)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh, color: Colors.white),
            style: ElevatedButton.styleFrom(backgroundColor: AppColor.green),
            onPressed: () {
              context.read<GeneralInventoryCubit>().fetchProducts();
            },
            label: const Text('إعادة المحاولة',
                style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyStateWidget(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory, color: Colors.grey.shade400, size: 70),
          const SizedBox(height: 20),
          const Text(
            'المخزن فارغ حالياً',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'إضغط على زر الإضافة لبدء تسجيل الأصناف.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
