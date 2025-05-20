import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zera3a/core/constants/app_const.dart';
import 'package:zera3a/core/utils/colors.dart';
import 'package:zera3a/feature/auth/auth_cubit.dart';
import 'package:zera3a/feature/auth/signIn_screen.dart';
import 'package:zera3a/feature/home/general_reports/general_reports_screen.dart';
import 'package:zera3a/feature/home/views/plot_dashboard_screen.dart';
import '../../../core/di.dart';
import '../controller/plot_cubit.dart';
import '../controller/plot_states.dart';
import 'add_plots_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  String userRole = 'supervisor'; // Default role
  late TabController _tabController;
  final List<String> _cropFilters = [
    'الكل',
    'خوخ',
    'عنب',
    'ذرة',
    'قمح',
    'أخري'
  ];
  String _selectedFilter = 'الكل';
  String? _searchQuery;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_){
      sl<PlotCubit>().fetchPlots();
    });
    fetchUserRole(userRole).then((role) {
      setState(() {
        userRole = role;
      });
    });
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshPlots() async {
    await context.read<PlotCubit>().fetchPlots();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
        value:  sl<PlotCubit>(),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            appBar: AppBar(
              leading: userRole == 'owner'
                  ? IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const AddPlotScreen()),
                        ).then((value) {
                          sl<PlotCubit>().fetchPlots();
                        });
                      },
                      icon: const Icon(
                        FluentIcons.add_square_multiple_24_filled,
                        color: Colors.white,
                      ),
                    )
                  : null,
              elevation: 0.5,
              bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(40),
                  child: TabBar(
                    labelColor: Colors.white,
                    indicatorColor: Colors.white,
                    unselectedLabelColor: Colors.white54,
                    indicatorWeight: 4,
                    tabs: [
                      const Tab(text: "الحوشه"),
                      const Tab(text: "التقارير")
                    ],
                    controller: _tabController,
                  )),
              centerTitle: true,
              actions: [
                IconButton(
                  onPressed: () {
                    _showLogoutDialog();
                  },
                  icon: const Icon(
                    FluentIcons.arrow_exit_20_filled,
                    size: 25,
                  ),
                  color: Colors.white,
                )
              ],
              title: const Text(
                'إدارة المزرعه',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: AppColor.green,
            ),
            body: TabBarView(controller: _tabController, children: [
              Column(
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
                  Padding(
                    padding: const EdgeInsets.only(right: 5, left: 5),
                    child: SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.065,
                      child: ListView.builder(
                        itemBuilder: (context, index) {
                          final filter = _cropFilters[index];
                          return Directionality(
                            textDirection: TextDirection.rtl,
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(left: 2.0, right: 2.0),
                              child: FilterChip(
                                padding: const EdgeInsets.all(4),
                                elevation: 3.5,
                                backgroundColor:
                                    Colors.grey.withValues(alpha: 0.25),
                                shadowColor:
                                    Colors.greenAccent.withValues(alpha: 0.2),
                                labelPadding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                label: Text(
                                  textDirection: TextDirection.rtl,
                                  // Ensure RTL for Arabic
                                  filter,
                                  style: TextStyle(
                                      fontFamily:
                                          GoogleFonts.roboto().fontFamily,
                                      fontWeight: FontWeight.bold,
                                      fontSize:
                                          MediaQuery.sizeOf(context).width *
                                              0.035),
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
                        itemCount: _cropFilters.length,
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
                          return const Center(
                              child: CircularProgressIndicator());
                        } else if (state is PlotLoaded) {
                          final plots = state.plots.where((plot) {
                            // Apply search filter
                            final matchesSearch = _searchQuery == null ||
                                plot.name.contains(_searchQuery!) ||
                                plot.number
                                    .toString()
                                    .contains(_searchQuery!) ||
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
                            return matchesSearch && matchesFilter;
                          }).toList();

                          if (plots.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.grass,
                                      size: 60, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchQuery != null ||
                                            _selectedFilter != 'الكل'
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
                                      icon: const Icon(
                                        Icons.refresh,
                                        size: 30,
                                      ),
                                      label: const Text('إعادة ضبط ',
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ]
                                ],
                              ),
                            );
                          }
                          return RefreshIndicator(
                            elevation: 2,
                            onRefresh: () => _refreshPlots(),
                            color: Colors.white,
                            backgroundColor: Colors.green,
                            child: ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: plots.length,
                              itemBuilder: (context, index) {
                                final plot = plots[index];
                                return Card(
                                  shadowColor:
                                      Colors.green.withValues(alpha: 0.8),
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
                                        AppConstant.getCropIcon(plot.cropType)
                                            .icon,
                                        size: 30,
                                        color: AppConstant.getCropColor(
                                            plot.cropType),
                                      ),
                                    ),
                                    title: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(plot.name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.all(5.0),
                                      child: SizedBox(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                                'رقم الحوشة: ${plot.number}\nالمحصول: ${plot.cropType}'),
                                            const Divider(),
                                            Text(
                                              'تاريخ الإنشاء: ${convertToArabicNumbers("${plot.createdAt.year}/${plot.createdAt.month}/${plot.createdAt.day}")}',
                                              style: const TextStyle(
                                                  color: Colors.grey),
                                            )
                                          ],
                                        ),
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
                                              const SizedBox(
                                                width: 5,
                                              ),
                                              CircleAvatar(
                                                  backgroundColor: Colors.red
                                                      .withValues(alpha: 0.2),
                                                  child: IconButton(
                                                      icon: const Icon(
                                                          Icons.delete,
                                                          color: Colors.red),
                                                      onPressed: () {
                                                        showDialog(
                                                            context: context,
                                                            builder: (context) =>
                                                                AlertDialog(
                                                                    title: const Text(
                                                                        textDirection:
                                                                            TextDirection
                                                                                .rtl,
                                                                        'تأكيد حذف الحوشة'),
                                                                    content:
                                                                        const Text(
                                                                      'هل أنت متأكد من حذف هذه الحوشة؟ لا يمكن التراجع عن هذا الإجراء',
                                                                      textDirection:
                                                                          TextDirection
                                                                              .rtl,
                                                                    ),
                                                                    actions: [
                                                                      TextButton(
                                                                        onPressed:
                                                                            () =>
                                                                                Navigator.pop(context),
                                                                        child: const Text(
                                                                            'إلغاء'),
                                                                      ),
                                                                      TextButton(
                                                                        onPressed:
                                                                            () {
                                                                          context
                                                                              .read<PlotCubit>()
                                                                              .deletePlot(plot.plotId);

                                                                          Navigator.pop(
                                                                              context);
                                                                        },
                                                                        child:
                                                                            const Text(
                                                                          'حذف الحوشه ',
                                                                          style:
                                                                              TextStyle(color: Colors.red),
                                                                        ),
                                                                      ),
                                                                    ]));
                                                      })),
                                            ],
                                          )
                                        : null,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PlotDashboard(
                                            plot: plot,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          );
                        }
                        return const Center(
                            child: Text('حدث خطأ، حاول مرة أخرى'));
                      },
                    ),
                  ),
                ],
              ),
              userRole == "owner"
                  ? const GeneralReportsScreen()
                  : const Center(child: Text("عذرا ليس لديك الصلاحية"))
            ]),
          ),
        ));
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
                          builder: (context) => const SignInScreen()));
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
