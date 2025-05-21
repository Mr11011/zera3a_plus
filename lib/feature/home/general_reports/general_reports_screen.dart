import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zera3a/feature/home/general_reports/general_reports_states.dart';
import '../../../core/constants/app_const.dart';
import '../controller/plot_cubit.dart';
import '../controller/plot_states.dart';
import 'general_reporst_cubit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zera3a/core/di.dart';

class GeneralReportsScreen extends StatefulWidget {
  const GeneralReportsScreen({super.key});

  @override
  State<GeneralReportsScreen> createState() => _GeneralReportsScreenState();
}

class _GeneralReportsScreenState extends State<GeneralReportsScreen> {
  int touchedIndex = -1; // Track which pie slice is touched
  final GeneralReportsCubit _generalReportsCubit = sl<GeneralReportsCubit>();
  int? threshold = 500000;
  bool isPressed = false;
  final ScrollController sc = ScrollController();
  final isWindows = Platform.isWindows;

  @override
  void initState() {
    super.initState();
    // Fetch data once plots are loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final plotState = context.read<PlotCubit>().state;
      if (plotState is PlotLoaded) {
        _generalReportsCubit.fetchGeneralReports(plotState.plots, threshold);
      }
    });
  }

  Widget _buildPieChart({
    required double irrigationCost,
    required double laborCost,
    required double inventoryCost,
  }) {
    final totalCost = irrigationCost + laborCost + inventoryCost;

    if (totalCost == 0) {
      return const Center(child: Text("لا توجد تكاليف لعرضها"));
    }

    final irrigationPercent = (irrigationCost / totalCost) * 100;
    final laborPercent = (laborCost / totalCost) * 100;
    final inventoryPercent = (inventoryCost / totalCost) * 100;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.35,
      width: MediaQuery.of(context).size.width,
      child: Card(
        // clipBehavior: Clip.antiAlias,
        elevation: 8,
        child: Row(
          children: [
            Flexible(
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          touchedIndex = -1;
                          return;
                        }
                        touchedIndex = pieTouchResponse
                            .touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2,
                  centerSpaceRadius: 30,
                  sections: [
                    PieChartSectionData(
                      color: Colors.blue,
                      value: irrigationCost,
                      title: touchedIndex == 0
                          ? '${irrigationPercent.toStringAsFixed(1)}%'
                          : 'الري',
                      radius: touchedIndex == 0 ? 80 : 70,
                      titleStyle: TextStyle(
                        fontSize: touchedIndex == 0 ? 14 : 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: GoogleFonts.readexPro().fontFamily,
                      ),
                    ),
                    PieChartSectionData(
                      color: Colors.amber,
                      value: laborCost,
                      title: touchedIndex == 1
                          ? '${laborPercent.toStringAsFixed(1)}%'
                          : 'العمالة',
                      radius: touchedIndex == 1 ? 80 : 70,
                      titleStyle: TextStyle(
                        fontSize: touchedIndex == 1 ? 14 : 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: GoogleFonts.readexPro().fontFamily,
                      ),
                    ),
                    PieChartSectionData(
                      color: Colors.green,
                      value: inventoryCost,
                      title: touchedIndex == 2
                          ? '${inventoryPercent.toStringAsFixed(1)}%'
                          : 'المخزن',
                      radius: touchedIndex == 2 ? 80 : 70,
                      titleStyle: TextStyle(
                        fontSize: touchedIndex == 2 ? 14 : 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: GoogleFonts.readexPro().fontFamily,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 15),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildIndicator(
                    color: Colors.blue,
                    text: 'الري',
                    percent: irrigationPercent),
                const SizedBox(height: 10),
                _buildIndicator(
                    color: Colors.amber,
                    text: 'العمالة',
                    percent: laborPercent),
                const SizedBox(height: 10),
                _buildIndicator(
                    color: Colors.green,
                    text: 'المخزن',
                    percent: inventoryPercent),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicator({
    required Color color,
    required String text,
    required double percent,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$text (${convertToArabicNumbers(percent.toStringAsFixed(1))}%)',
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey.withAlpha(50),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              textDirection: TextDirection.rtl,
              maxLines: 2,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
              title,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            Flexible(
              child: Text(
                value,
                textDirection: TextDirection.rtl,
                maxLines: 1,
                softWrap: true,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: BlocProvider.value(
        value: _generalReportsCubit,
        child: BlocBuilder<PlotCubit, PlotStates>(
          builder: (context, plotState) {
            if (plotState is PlotLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (plotState is PlotError) {
              return Center(child: Text(plotState.error));
            } else if (plotState is PlotLoaded) {
              return BlocBuilder<GeneralReportsCubit, GeneralReportsState>(
                builder: (context, state) {
                  if (state.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.errorMessage != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(state.errorMessage!),
                          ElevatedButton(
                            onPressed: () =>
                                _generalReportsCubit.fetchGeneralReports(
                                    plotState.plots, threshold),
                            child: const Text("إعادة المحاولة"),
                          ),
                        ],
                      ),
                    );
                  }
                  if (state.plots.isEmpty) {
                    return const Center(
                        child: Text("لا توجد حوش لعرض تقاريرها"));
                  }

                  final aggregatedData = state.aggregatedData;
                  return ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      const Text(
                        "التقارير العامة",
                        style: TextStyle(color: Colors.brown, fontSize: 20),
                        textAlign: TextAlign.center,
                      ),
                      const Divider(
                        thickness: 2,
                        endIndent: 100,
                        indent: 100,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 20),
                      _buildPieChart(
                        irrigationCost:
                            aggregatedData['irrigationTotalCost'] ?? 0,
                        laborCost: aggregatedData['laborTotalCost'] ?? 0,
                        inventoryCost:
                            aggregatedData['inventoryTotalCost'] ?? 0,
                      ),
                      const SizedBox(height: 25),
                      const SizedBox(height: 25),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Flexible(
                            child: Text(
                              "الإحصائيات والحالة",
                              style:
                                  TextStyle(color: Colors.brown, fontSize: 20),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          IconButton(
                            tooltip: 'تغيير حَد صرف الحوش المستخدم للتحظير',
                            icon: const Icon(
                              Icons.filter_list_alt,
                              size: 35,
                            ),
                            onPressed: () {
                              setState(() {
                                isPressed = !isPressed;
                              });
                            },
                          )
                        ],
                      ),
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Divider(
                          thickness: 2,
                          endIndent: 100,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 20),
                      isPressed
                          ? Column(
                              children: [
                                Text(
                                    'الحد الاقصي: ${convertToArabicNumbers(threshold.toString())}ج'),
                                AnimatedContainer(
                                  curve: Curves.easeInOut,
                                  height: 80,
                                  width: MediaQuery.of(context).size.width,
                                  duration: const Duration(
                                    milliseconds: 500,
                                  ),
                                  child: Slider(
                                      divisions: 10,
                                      min: 0,
                                      max: 1000000,
                                      value: threshold!.toDouble(),
                                      onChanged: (value) {
                                        setState(() {
                                          threshold = value.toInt();
                                        });

                                        Future.delayed(
                                            const Duration(
                                                seconds: 1,
                                                milliseconds: 200), () {
                                          _generalReportsCubit
                                              .fetchGeneralReports(
                                                  plotState.plots, threshold);
                                        });
                                      }),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                      const SizedBox(height: 15),
                      Scrollbar(
                        radius: const Radius.circular(10),
                        controller: sc,
                        thickness: isWindows ? 10 : 5,
                        thumbVisibility: isWindows ? true : false,
                        child: SingleChildScrollView(
                          controller: sc,
                          physics: const BouncingScrollPhysics(),
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.4,
                                height:
                                    MediaQuery.of(context).size.height * 0.3,
                                child: _buildStatusCard(
                                  title: 'إجمالي الحوش',
                                  value: convertToArabicNumbers(
                                      (aggregatedData['totalPlots'] ?? 0)
                                          .toString()),
                                  icon: Icons.landscape,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.4,
                                height:
                                    MediaQuery.of(context).size.height * 0.3,
                                child: _buildStatusCard(
                                  title: 'التكلفة الكلية',
                                  value:
                                      '${convertToArabicNumbers((aggregatedData['totalCost'] ?? 0).toStringAsFixed(1))} جنيه',
                                  icon: Icons.money,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.4,
                                height:
                                    MediaQuery.of(context).size.height * 0.3,
                                child: InkWell(
                                  onTap: () {
                                    final List attentionPlotName =
                                        aggregatedData['attentionPlotName'];
                                    String nameOfAttentionPlots = '';

                                    for (int i = 0;
                                        i < attentionPlotName.length;
                                        i++) {
                                      nameOfAttentionPlots +=
                                          '${convertToArabicNumbers((i + 1).toString()).toString()}- ${attentionPlotName[i]}\n';
                                    }

                                    //   showDialog
                                    showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                              icon: const Icon(
                                                Icons.warning,
                                                color: Colors.red,
                                              ),
                                              title: Column(
                                                children: [
                                                  Text(
                                                    "حوش تخطت حَد ${convertToArabicNumbers(threshold.toString())} جنيه",
                                                    textAlign: TextAlign.center,
                                                    softWrap: true,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    textDirection:
                                                        TextDirection.rtl,
                                                    style: const TextStyle(
                                                        color: Colors.brown,
                                                        fontSize: 16),
                                                  ),
                                                  const Divider()
                                                ],
                                              ),
                                              content: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                        textDirection:
                                                            TextDirection.rtl,
                                                        nameOfAttentionPlots)
                                                  ]),
                                            ));
                                  },
                                  child: _buildStatusCard(
                                    title: 'حوش تخطت الحد المطلوب',
                                    value: convertToArabicNumbers(
                                        (aggregatedData[
                                                    'plotsNeedingAttention'] ??
                                                0)
                                            .toString()),
                                    icon: Icons.warning,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            }
            return const Center(child: Text("حدث خطأ، حاول مرة أخرى"));
          },
        ),
      ),
    );
  }
}
