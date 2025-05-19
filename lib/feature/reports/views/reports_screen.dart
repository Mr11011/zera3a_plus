import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zera3a/core/constants/app_const.dart';
import 'package:zera3a/core/di.dart';
import 'package:zera3a/feature/home/data/plot_model.dart';
import '../controller/report_cubit.dart';
import '../controller/report_states.dart';

class ReportsScreen extends StatefulWidget {
  final Plot plot;

  const ReportsScreen({super.key, required this.plot});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int touchedIndex = -1; // Track which pie slice is touched
  final ReportsCubit _cubit = sl<ReportsCubit>();

  @override
  void initState() {
    super.initState();
    _cubit.fetchReports(widget.plot.plotId, ReportFilter.daily);
  }

  Widget _statusCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
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
          Text(
            value,
            textDirection: TextDirection.rtl,
            maxLines: 1,
            softWrap: true,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart({
    required double irrigationCost,
    required double laborCost,
    required double inventoryCost,
  }) {
    final totalCost = irrigationCost + laborCost + inventoryCost;

    // Calculate percentages
    final irrigationPercent =
        totalCost > 0 ? (irrigationCost / totalCost) * 100 : 0;
    final laborPercent = totalCost > 0 ? (laborCost / totalCost) * 100 : 0;
    final inventoryPercent =
        totalCost > 0 ? (inventoryCost / totalCost) * 100 : 0;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.4,
      width: MediaQuery.of(context).size.width,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Row(
            children: [
              Expanded(
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
                    centerSpaceRadius: 40,
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
                          fontFamily: GoogleFonts.rubik().fontFamily,
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
                          fontFamily: GoogleFonts.rubik().fontFamily,
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
                          fontFamily: GoogleFonts.rubik().fontFamily,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIndicator(
                      color: Colors.blue,
                      text: 'الري',
                      percent: irrigationPercent.toDouble()),
                  const SizedBox(height: 10),
                  _buildIndicator(
                      color: Colors.amber,
                      text: 'العمالة',
                      percent: laborPercent.toDouble()),
                  const SizedBox(height: 10),
                  _buildIndicator(
                      color: Colors.green,
                      text: 'المخزن',
                      percent: inventoryPercent.toDouble()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIndicator({
    required Color color,
    required String text,
    required double percent,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$text (${convertToArabicNumbers(percent.toStringAsFixed(1))}%)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: GoogleFonts.rubik().fontFamily,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          actions: [],
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            "تقارير - ${widget.plot.name}",
            style: TextStyle(
              fontFamily: GoogleFonts.readexPro().fontFamily,
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          backgroundColor: Colors.green[800],
          elevation: 4,
        ),
        body: BlocProvider(
          create: (context) => _cubit,
          child: BlocBuilder<ReportsCubit, ReportsState>(
            builder: (context, state) {
              if (state.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.errorMessage != null) {
                return Center(child: Text(state.errorMessage!));
              }
              if (state.dailySummaries.isEmpty) {
                return const Center(child: Text("لا توجد بيانات تقارير متاحة"));
              }

              // Aggregate data
              // double totalCost = 0;
              double laborTotalCost = 0;
              double irrigationTotalCost = 0;
              double irrigationDays = 0;
              double inventoryTotalCost = 0;
              double laborTotalDays = 0;
              int laborTotalWorkers = 0;
              // int laborCount = 0;
              int irrigationCount = 0;
              // int inventoryCount = 0;
              for (var summary in state.dailySummaries) {
                // totalCost += (summary['totalCost'] as num?)?.toDouble() ?? 0;
                laborTotalCost +=
                    (summary['laborTotalCost'] as num?)?.toDouble() ?? 0;
                irrigationTotalCost +=
                    (summary['irrigationTotalCost'] as num?)?.toDouble() ?? 0;
                irrigationDays +=
                    (summary['irrigationDays'] as num?)?.toDouble() ?? 0;
                laborTotalWorkers +=
                    (summary['laborTotalWorkers'] as num?)?.toInt() ?? 0;
                inventoryTotalCost +=
                    (summary['inventoryTotalCost'] as num?)?.toDouble() ?? 0;
                laborTotalDays +=
                    (summary['laborTotalDays'] as num?)?.toDouble() ?? 0;
                final counts = summary['counts'] as Map<String, dynamic>? ?? {};
                // laborCount += (counts['labor'] as num?)?.toInt() ?? 0;
                irrigationCount += (counts['irrigation'] as num?)?.toInt() ?? 0;
                // inventoryCount += (counts['inventory'] as num?)?.toInt() ?? 0;
              }

              return ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  // Filter Section
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () => _cubit.fetchReports(
                              widget.plot.plotId, ReportFilter.daily),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: state.filter == ReportFilter.daily
                                ? Colors.green[800]
                                : Colors.grey.withAlpha(50),
                          ),
                          child: const Text("يومي",
                              style: TextStyle(color: Colors.white)),
                        ),
                        ElevatedButton(
                          onPressed: () => _cubit.fetchReports(
                              widget.plot.plotId, ReportFilter.weekly),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: state.filter == ReportFilter.weekly
                                ? Colors.green[800]
                                : Colors.grey.withAlpha(50),
                          ),
                          child: const Text("أسبوعي",
                              style: TextStyle(color: Colors.white)),
                        ),
                        ElevatedButton(
                          onPressed: () => _cubit.fetchReports(
                              widget.plot.plotId, ReportFilter.monthly),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                state.filter == ReportFilter.monthly
                                    ? Colors.green[800]
                                    : Colors.grey.withAlpha(50),
                          ),
                          child: const Text("شهري",
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.2,
                                width: MediaQuery.of(context).size.width * 0.25,
                                child: _statusCard(
                                    title: 'أيام الري',
                                    value: convertToArabicNumbers(
                                        irrigationDays.toInt().toString()),
                                    icon: Icons.water,
                                    color: Colors.blue),
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.25,
                                height:
                                    MediaQuery.of(context).size.height * 0.2,
                                child: _statusCard(
                                    title: 'العاملين',
                                    value: convertToArabicNumbers(
                                        laborTotalWorkers.toInt().toString()),
                                    icon: Icons.people_outline_outlined,
                                    color: Colors.black45),
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.25,
                                height:
                                    MediaQuery.of(context).size.height * 0.2,
                                child: _statusCard(
                                    title: 'عدد عمليات الري',
                                    value: convertToArabicNumbers(
                                        irrigationCount.toInt().toString()),
                                    icon: Icons.water_drop_outlined,
                                    color: Colors.blueAccent),
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.25,
                                height:
                                    MediaQuery.of(context).size.height * 0.2,
                                child: _statusCard(
                                    title: 'إجمالي أيام العمال',
                                    value: convertToArabicNumbers(
                                        laborTotalDays.toInt().toString()),
                                    icon: Icons.today_sharp,
                                    color: Colors.black45),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      const Text(
                        "التكاليف",
                        style: TextStyle(color: Colors.brown, fontSize: 20),
                      ),
                      Divider(
                        thickness: 2,
                        endIndent: 100,
                        indent: 100,
                        color: Colors.grey.shade300,
                      ),
                      _buildPieChart(
                        irrigationCost: irrigationTotalCost,
                        laborCost: laborTotalCost,
                        inventoryCost: inventoryTotalCost,
                      ),
                      const SizedBox(height: 25),
                      const Text(
                        "مقارنة التكاليف",
                        style: TextStyle(color: Colors.brown, fontSize: 20),
                      ),
                      Divider(
                        thickness: 2,
                        endIndent: 100,
                        indent: 100,
                        color: Colors.grey.shade300,
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.4,
                        width: MediaQuery.of(context).size.width,
                        child: Card(
                          elevation: 8,
                          child: Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                barGroups: [
                                  BarChartGroupData(x: 0, barRods: [
                                    BarChartRodData(
                                      toY: irrigationTotalCost,
                                      color: Colors.blue,
                                      width: 15,
                                      backDrawRodData:
                                          BackgroundBarChartRodData(
                                        show: true,
                                        toY: 500000,
                                        color: Colors.grey.withAlpha(25),
                                      ),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ]),
                                  BarChartGroupData(x: 1, barRods: [
                                    BarChartRodData(
                                      toY: laborTotalCost,
                                      color: Colors.amber,
                                      width: 15,
                                      backDrawRodData:
                                          BackgroundBarChartRodData(
                                        show: true,
                                        toY: 500000,
                                        color: Colors.grey.withAlpha(25),
                                      ),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ]),
                                  BarChartGroupData(
                                    x: 2,
                                    barRods: [
                                      BarChartRodData(
                                        toY: inventoryTotalCost,
                                        color: Colors.green,
                                        width: 15,
                                        borderRadius: BorderRadius.circular(2),
                                        backDrawRodData:
                                            BackgroundBarChartRodData(
                                          show: true,
                                          toY: 500000,
                                          color: Colors.grey.withAlpha(25),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                barTouchData: BarTouchData(
                                  touchTooltipData: BarTouchTooltipData(
                                    getTooltipItem:
                                        (group, groupIndex, rod, rodIndex) {
                                      final value = rod.toY;
                                      return BarTooltipItem(
                                        '${convertToArabicNumbers(value.toInt().toString())} جنيه\n',
                                        TextStyle(
                                          color: Colors.white,
                                          fontFamily:
                                              GoogleFonts.rubik().fontFamily,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                gridData: const FlGridData(show: false),
                                borderData: FlBorderData(
                                  show: true,
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                ),
                                titlesData: FlTitlesData(
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize:
                                          MediaQuery.sizeOf(context).width *
                                              0.15,
                                      getTitlesWidget: (value, meta) {
                                        return Flexible(
                                          child: Text(
                                            style: TextStyle(
                                              fontFamily: GoogleFonts.rubik()
                                                  .fontFamily,
                                            ),
                                            textDirection: TextDirection.rtl,
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            softWrap: true,
                                            overflow: TextOverflow.ellipsis,
                                            convertToArabicNumbers(
                                                value.toInt().toString()),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  leftTitles: const AxisTitles(),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 30,
                                      getTitlesWidget: (value, meta) {
                                        final titles = [
                                          "الري",
                                          "العمالة",
                                          "المخزن"
                                        ];
                                        return Text(
                                          titles[value.toInt()],
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
