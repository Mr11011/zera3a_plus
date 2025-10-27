import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zera3a/core/constants/app_const.dart';
import 'package:zera3a/core/utils/colors.dart';
import 'package:zera3a/feature/auth/auth_cubit.dart';
import 'package:zera3a/feature/auth/signIn_screen.dart';
import 'package:zera3a/feature/cashFlow/views/cash_flow_screen.dart';
import 'package:zera3a/feature/general_workers/controller/general_workers_cubit.dart';
import 'package:zera3a/feature/home/general_reports/general_reports_screen.dart';
import 'package:zera3a/feature/home/views/plot_dashboard_screen.dart';
import '../../../core/di.dart';
import '../../general_inventory/controlller/general_inventory_cubit.dart';
import '../../general_inventory/views/general_inventory_screen.dart';
import '../../general_workers/views/general_workers_screen.dart';
import '../controller/plot_cubit.dart';
import '../controller/plot_states.dart';
import 'add_plots_screen.dart';
import 'dart:io' show Platform;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String userRole = 'supervisor';
  int _currentIndex = 0;

  String _selectedFilter = 'الكل';
  String? _searchQuery;

  @override
  void initState() {
    super.initState();
    fetchUserRole(userRole).then((role) {
      setState(() {
        userRole = role;
      });
    });
    // Load initial screen data
    _loadScreenData(0);
  }

  void _loadScreenData(int index) {
    switch (index) {
      case 0:
        sl<PlotCubit>().fetchPlots();
        break;
      case 1:
        sl<GeneralInventoryCubit>().fetchProducts();
        break;
      case 2:
        sl<GeneralWorkersCubit>().fetchWorkers();
        break;
      case 3:
        // General reports - load if needed
        break;
      case 4:
        // Cash flow - load if needed
        break;
    }
  }

  void _onNavigationTap(int index) {
    setState(() {
      _currentIndex = index;
      // Reset search and filter when changing screens
      _searchQuery = null;
      _selectedFilter = 'الكل';
    });
    // Fetch data for the selected screen
    _loadScreenData(index);
  }

  Future<void> _refreshPlots() async {
    await context.read<PlotCubit>().fetchPlots();
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return _buildPlotsScreen();
      case 1:
        return BlocProvider(
          create: (_) => sl<GeneralInventoryCubit>()..fetchProducts(),
          child: const GeneralInventoryScreen(),
        );
      case 2:
        return BlocProvider(
          create: (_) => sl<GeneralWorkersCubit>()..fetchWorkers(),
          child: const GeneralWorkersScreen(),
        );
      case 3:
        return userRole == "owner"
            ? const GeneralReportsScreen()
            : const Center(child: Text("عذرا ليس لديك الصلاحية"));
      case 4:
        return const CashFlowScreen();
      default:
        return _buildPlotsScreen();
    }
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'الحوشه';
      case 1:
        return 'المخزن العام';
      case 2:
        return 'العماله';
      case 3:
        return 'التقارير';
      case 4:
        return 'السِجل المالي';
      default:
        return 'إدارة المزرعه';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<PlotCubit>(),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          floatingActionButton: _currentIndex == 0 && userRole == 'owner'
              ? FloatingActionButton.extended(
                  heroTag: 'addPlotFAB',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddPlotScreen(),
                      ),
                    ).then((value) {
                      sl<PlotCubit>().fetchPlots();
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة حوشة'),
                  backgroundColor: AppColor.green,
                  foregroundColor: Colors.white,
                )
              : null,
          appBar: AppBar(
            centerTitle: true,
            actions: [
              IconButton(
                onPressed: _showLogoutDialog,
                icon: const Icon(
                  FluentIcons.arrow_exit_20_filled,
                  size: 25,
                ),
                color: Colors.white,
              )
            ],
            title: Text(
              _getAppBarTitle(),
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColor.green,
          ),
          body: _buildCurrentScreen(),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: _onNavigationTap,
            backgroundColor: Colors.white,
            indicatorColor: AppColor.green.withValues(alpha: 0.3),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.grass_outlined),
                selectedIcon: Icon(Icons.grass),
                label: 'الحوشه',
              ),
              NavigationDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2),
                label: 'المخزن',
              ),
              NavigationDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: 'العماله',
              ),
              NavigationDestination(
                icon: Icon(Icons.assessment_outlined),
                selectedIcon: Icon(Icons.assessment),
                label: 'التقارير',
              ),
              NavigationDestination(
                icon: Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: Icon(Icons.account_balance_wallet),
                label: 'المالي',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlotsScreen() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.048,
            width: MediaQuery.sizeOf(context).width * 0.85,
            child: SearchBar(
              padding: const WidgetStatePropertyAll<EdgeInsets>(
                EdgeInsets.symmetric(horizontal: 20.0),
              ),
              hintText: 'البحث عن حوشة...',
              leading: const Icon(Icons.search),
              onChanged: (value) => setState(() {
                _searchQuery = value.isNotEmpty ? value : null;
              }),
            ),
          ),
        ),
        Expanded(
          child: BlocConsumer<PlotCubit, PlotStates>(
            listener: (context, state) {
              if (state is PlotError) {
                Fluttertoast.showToast(
                  msg: state.error,
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                );
              }
            },
            builder: (context, state) {
              if (state is PlotLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is PlotLoaded) {
                final crops = state.cropTypes;
                final plots = state.plots.where((plot) {
                  final matchesSearch = _searchQuery == null ||
                      plot.name.contains(_searchQuery!) ||
                      plot.number.toString().contains(_searchQuery!) ||
                      plot.cropType.contains(_searchQuery!);

                  final matchesFilter = _selectedFilter == "الكل" ||
                      plot.cropType == _selectedFilter ||
                      plot.cropType
                          .toString()
                          .trim()
                          .toLowerCase()
                          .contains(_selectedFilter) ||
                      plot.cropType
                          .toString()
                          .trim()
                          .contains(_selectedFilter) ||
                      plot.name.contains(_selectedFilter);

                  if (!crops.contains(_selectedFilter)) {
                    _selectedFilter = "الكل";
                  }
                  return matchesSearch && matchesFilter;
                }).toList();

                if (plots.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.grass, size: 60, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery != null || _selectedFilter != 'الكل'
                              ? 'لا توجد نتائج مطابقة'
                              : 'لا توجد حوش بعد، أضف حوشة جديدة!',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (userRole == 'owner' &&
                            (_searchQuery != null ||
                                _selectedFilter != 'الكل')) ...[
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _searchQuery = null;
                                _selectedFilter = 'الكل';
                              });
                            },
                            icon: const Icon(Icons.refresh, size: 30),
                            label: const Text(
                              'إعادة ضبط',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ]
                      ],
                    ),
                  );
                }

                // Build the list of plots with filtering and search
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 5, left: 5),
                      child: SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.065,
                        child: ListView.builder(
                          itemBuilder: (context, index) {
                            final isWindows = Platform.isWindows;
                            final filter = crops[index];
                            return Directionality(
                              textDirection: TextDirection.rtl,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    left: 2.0, right: 2.0),
                                child: FilterChip(
                                  padding: const EdgeInsets.all(4),
                                  elevation: 3.5,
                                  backgroundColor:
                                      Colors.grey.withValues(alpha: 0.25),
                                  shadowColor:
                                      Colors.greenAccent.withValues(alpha: 0.2),
                                  labelPadding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  label: isWindows
                                      ? ConstrainedBox(
                                          constraints: const BoxConstraints(
                                              minWidth: 80, minHeight: 60),
                                          child: Center(
                                            child: Text(
                                              filter,
                                              textDirection: TextDirection.rtl,
                                              style: TextStyle(
                                                fontFamily: GoogleFonts.roboto()
                                                    .fontFamily,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        )
                                      : Text(
                                          textDirection: TextDirection.rtl,
                                          filter,
                                          style: TextStyle(
                                            fontFamily:
                                                GoogleFonts.roboto().fontFamily,
                                            fontWeight: FontWeight.bold,
                                            fontSize: MediaQuery.sizeOf(context)
                                                    .width *
                                                0.035,
                                          ),
                                        ),
                                  selected: _selectedFilter == filter,
                                  checkmarkColor: Colors.green,
                                  onSelected: (bool value) {
                                    setState(() => _selectedFilter = filter);
                                  },
                                ),
                              ),
                            );
                          },
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: crops.length,
                        ),
                      ),
                    ),
                    // --- PLOTS LIST ---
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _refreshPlots,
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: plots.length,
                          padding: const EdgeInsets.only(bottom: 60),
                          itemBuilder: (context, index) {
                            final plot = plots[index];
                            return Card(
                              shadowColor: Colors.green.withValues(alpha: 0.8),
                              color: Colors.white.withValues(alpha: 0.85),
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              margin: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  radius: 22,
                                  backgroundColor: Colors.greenAccent
                                      .withValues(alpha: 0.25),
                                  child: Icon(
                                    AppConstant.getCropIcon(plot.cropType).icon,
                                    size: 30,
                                    color:
                                        AppConstant.getCropColor(plot.cropType),
                                  ),
                                ),
                                title: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    plot.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.all(5.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'رقم الحوشة: ${convertToArabicNumbers(plot.number)}\nالمحصول: ${plot.cropType}',
                                      ),
                                      const Divider(),
                                      Text(
                                        'تاريخ الإنشاء: ${convertToArabicNumbers("${plot.createdAt.year}/${plot.createdAt.month}/${plot.createdAt.day}")}',
                                        style:
                                            const TextStyle(color: Colors.grey),
                                      )
                                    ],
                                  ),
                                ),
                                trailing: userRole == 'owner'
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: Colors.grey
                                                .withValues(alpha: 0.25),
                                            child: IconButton(
                                              icon: const Icon(Icons.edit,
                                                  color: Colors.blue),
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        AddPlotScreen(
                                                            plot: plot),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          CircleAvatar(
                                            backgroundColor: Colors.red
                                                .withValues(alpha: 0.2),
                                            child: IconButton(
                                              icon: const Icon(Icons.delete,
                                                  color: Colors.red),
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) =>
                                                      AlertDialog(
                                                    title: const Text(
                                                      textDirection:
                                                          TextDirection.rtl,
                                                      'تأكيد حذف الحوشة',
                                                    ),
                                                    content: const Text(
                                                      'هل أنت متأكد من حذف هذه الحوشة؟ لا يمكن التراجع عن هذا الإجراء',
                                                      textDirection:
                                                          TextDirection.rtl,
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context),
                                                        child:
                                                            const Text('إلغاء'),
                                                      ),
                                                      TextButton(
                                                        onPressed: () {
                                                          context
                                                              .read<PlotCubit>()
                                                              .deletePlot(
                                                                  plot.plotId);
                                                          Navigator.pop(
                                                              context);
                                                        },
                                                        child: const Text(
                                                          'حذف الحوشه',
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.red),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      )
                                    : null,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          PlotDashboard(plot: plot),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              }
              return const Center(child: Text('حدث خطأ، حاول مرة أخرى'));
            },
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تسجيل الخروج'),
            content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  sl<AuthCubit>().signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SignInScreen()),
                  );
                },
                child: const Text('تسجيل الخروج',
                    style: TextStyle(color: Colors.red)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
            ],
          ),
        );
      },
    );
  }
}
