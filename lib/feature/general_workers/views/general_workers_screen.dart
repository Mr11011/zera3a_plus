import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zera3a/core/constants/app_const.dart';
import 'package:zera3a/core/utils/colors.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../controller/general_workers_cubit.dart';
import '../controller/general_workers_state.dart';
import '../data/contractors.dart';
import '../data/fixed_workers.dart';
import 'contractors/add_contractors_screen.dart';
import 'fixed_workers/add_fixed_workers_screen.dart';
import 'contractors/contractors_details_screen.dart';
import 'fixed_workers/fixed_workers_details_screen.dart';

class GeneralWorkersScreen extends StatefulWidget {
  const GeneralWorkersScreen({super.key});

  @override
  State<GeneralWorkersScreen> createState() => _GeneralWorkersScreenState();
}

class _GeneralWorkersScreenState extends State<GeneralWorkersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddChoiceBottomSheet(BuildContext cubitContext) {
    showModalBottomSheet(
      context: cubitContext,
      backgroundColor: AppColor.beige,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إضافة جديد',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColor.darkGreen),
                ),
                const SizedBox(height: 16),
                _buildSheetOption(
                  context: cubitContext,
                  icon: Icons.person_add_alt_1,
                  title: 'إضافة عامل ثابت',
                  onTap: () {
                    Navigator.pop(sheetContext); // Close the sheet
                    Navigator.push(
                      cubitContext,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: cubitContext.read<GeneralWorkersCubit>(),
                          child: const AddFixedWorkerScreen(),
                        ),
                      ),
                    );
                  },
                ),
                const Divider(),
                _buildSheetOption(
                  context: cubitContext,
                  icon: Icons.business,
                  title: 'إضافة مقاول',
                  onTap: () {
                    Navigator.pop(sheetContext); // Close the sheet
                    Navigator.push(
                      cubitContext,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: cubitContext.read<GeneralWorkersCubit>(),
                          child: const AddContractorScreen(),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColor.green, size: 28),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(color: AppColor.green),
          backgroundColor: AppColor.beige.withValues(alpha: 0.2),
          elevation: 0,
          title: TabBar(
            controller: _tabController,
            labelColor: AppColor.darkGreen,
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: AppColor.green,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'عمالة ثابتة'),
              Tab(text: 'مقاولين (عمالة مؤقتة)'),
            ],
          ),
        ),
        body: BlocConsumer<GeneralWorkersCubit, GeneralWorkersState>(
          buildWhen: (previous, current) {
            return current is WorkersLoading ||
                current is WorkersLoaded ||
                current is WorkersError ||
                current is WorkersInitial;
          },
          listener: (context, state) {
            if (state is WorkersSuccess) {
              Fluttertoast.showToast(
                  msg: state.message, backgroundColor: AppColor.green);
            } else if (state is WorkersError) {
              Fluttertoast.showToast(
                  msg: state.message, backgroundColor: Colors.red);
            }
          },
          builder: (context, state) {
            if (state is WorkersLoading || state is WorkersInitial) {
              return Center(
                  child: CircularProgressIndicator(color: AppColor.green));
            }

            if (state is WorkersError) {
              return Center(child: Text(state.message));
            }

            if (state is WorkersLoaded) {
              return TabBarView(
                controller: _tabController,
                children: [
                  _buildFixedWorkersList(context, state.fixedWorkers),
                  _buildContractorsList(context, state.contractors),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
        floatingActionButton: Builder(builder: (buttonContext) {
          return FloatingActionButton(
            heroTag: 'add_worker',
            onPressed: () => _showAddChoiceBottomSheet(buttonContext),
            backgroundColor: AppColor.green,
            child: const Icon(Icons.add, color: Colors.white),
          );
        }),
      ),
    );
  }

  Widget _buildFixedWorkersList(
      BuildContext context, List<FixedWorker> workers) {
    if (workers.isEmpty) {
      return const Center(child: Text('لم يتم إضافة أي عمال ثابتين بعد.'));
    }
    return ListView.builder(
      padding:
          const EdgeInsets.only(right: 12.0, left: 12.0, top: 12, bottom: 60),
      itemCount: workers.length,
      itemBuilder: (context, index) {
        final worker = workers[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6.0),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColor.green.withValues(alpha: 0.1),
              child: Icon(Icons.person, color: AppColor.green),
            ),
            title: Text(worker.name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(worker.jobTitle),
            trailing: Text(
              '${convertToArabicNumbers(worker.monthlySalary.toStringAsFixed(0))} جنيه/شهرياً',
              style: TextStyle(
                  color: AppColor.darkGreen,
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<GeneralWorkersCubit>(),
                    child: FixedWorkerDetailScreen(worker: worker),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildContractorsList(
      BuildContext context, List<Contractor> contractors) {
    if (contractors.isEmpty) {
      return const Center(child: Text('لم يتم إضافة أي مقاولين بعد.'));
    }
    return ListView.builder(
      padding:
          const EdgeInsets.only(right: 12.0, left: 12.0, top: 12, bottom: 60),
      itemCount: contractors.length,
      itemBuilder: (context, index) {
        final contractor = contractors[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6.0),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
              child: const Icon(Icons.engineering, color: Colors.blueAccent),
            ),
            title: Text(contractor.contractorName,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: contractor.contactPerson.isNotEmpty
                ? Text(
                    'المسؤول: ${contractor.contactPerson.isNotEmpty ? contractor.contactPerson : 'غير محدد'}')
                : const Text('مقاول'),
            trailing: Text(
              '${convertToArabicNumbers(contractor.pricePerDay.toStringAsFixed(0))} جنيه/للعامل',
              style: TextStyle(
                  color: AppColor.darkGreen,
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<GeneralWorkersCubit>(),
                    child: ContractorDetailScreen(contractor: contractor),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
