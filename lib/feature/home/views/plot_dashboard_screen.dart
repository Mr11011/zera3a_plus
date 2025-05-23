import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:zera3a/core/constants/app_const.dart';
import 'package:zera3a/core/utils/colors.dart';
import '../../inventory/views/inventory_screen.dart';
import '../../irrigation/irrigation_screen.dart';
import '../../reports/views/reports_screen.dart';
import '../../workers/workers_screen.dart';
import '../data/plot_model.dart';

class PlotDashboard extends StatefulWidget {
  final Plot plot;

  const PlotDashboard({super.key, required this.plot});

  @override
  State<PlotDashboard> createState() => _PlotDashboardState();
}

class _PlotDashboardState extends State<PlotDashboard> {
  late List<String> functions = ["الري", "العماله", "المخزن", "التقارير"];
  String userRole = 'supervisor';

  @override
  void initState() {
    super.initState();
    fetchUserRole(userRole).then((value) {
      setState(() {
        userRole = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            widget.plot.name,
            style: TextStyle(color: AppColor.green),
          ),
          backgroundColor: AppColor.beige,
        ),
        body: Padding(
          padding:
              const EdgeInsets.only(top: 10.0, right: 5, left: 5, bottom: 10),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                colors: [Colors.green.shade50, Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Card(
                    elevation: 5,
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: LinearGradient(
                            colors: [
                              AppColor.green,
                              AppColor.green.withValues(alpha: 0.88),
                              Colors.grey
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.bottomLeft,
                          )),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  textDirection: TextDirection.rtl,
                                  textAlign: TextAlign.start,
                                  " الاسم: ${widget.plot.name}",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: true,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                                Text(" نوع المحصول: ${widget.plot.cropType}",
                                    textDirection: TextDirection.rtl,
                                    textAlign: TextAlign.start,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.white70,
                                    )),
                                Text(" رقم الحوشه: ${widget.plot.number}",
                                    textDirection: TextDirection.rtl,
                                    textAlign: TextAlign.start,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white70,
                                    )),
                              ],
                            ),
                          ),
                          CircleAvatar(
                            radius: 35,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.85),
                            child: Icon(
                              AppConstant.getCropIcon(widget.plot.cropType)
                                  .icon,
                              size: 35,
                              color: Colors.brown,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  GridView.count(
                      shrinkWrap: true,
                      scrollDirection: Axis.vertical,
                      physics: const BouncingScrollPhysics(),
                      crossAxisCount: 2,
                      childAspectRatio: 3 / 4,
                      crossAxisSpacing: 20.0,
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => IrrigationScreen(
                                          plot: widget.plot,
                                        )));
                          },
                          child: Card(
                            color: Colors.transparent,
                            child: Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomLeft,
                                    end: Alignment.topRight,
                                    colors: [
                                      Colors.deepPurple.withValues(alpha: 0.7),
                                      Colors.blue,
                                      Colors.blueAccent.withValues(alpha: 0.4),
                                    ],
                                  )),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.water_drop_outlined,
                                    size: 100,
                                    color: Colors.white.withValues(alpha: 0.95),
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  Text(
                                    textDirection: TextDirection.rtl,
                                    textAlign: TextAlign.center,
                                    functions.first,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 22),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => InventoryScreen(
                                          plot: widget.plot,
                                        )));
                          },
                          child: Card(
                            color: Colors.transparent,
                            child: Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomLeft,
                                    end: Alignment.topRight,
                                    colors: [
                                      Colors.green.withValues(alpha: 0.35),
                                      Colors.green,
                                    ],
                                  )),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    FluentIcons.box_arrow_up_24_filled,
                                    size: 100,
                                    color: Colors.white.withValues(alpha: 0.95),
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  Text(
                                    textDirection: TextDirection.rtl,
                                    textAlign: TextAlign.center,
                                    functions[2],
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 22),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => LaborScreen(
                                          plot: widget.plot,
                                        )));
                          },
                          child: Card(
                            color: Colors.transparent,
                            child: Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomLeft,
                                    end: Alignment.topRight,
                                    colors: [
                                      Colors.orange.withValues(alpha: 0.35),
                                      Colors.lightGreenAccent
                                          .withValues(alpha: 0.9),
                                    ],
                                  )),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    FluentIcons.people_edit_24_filled,
                                    size: 100,
                                    color: Colors.white.withValues(alpha: 0.95),
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  Text(
                                    textDirection: TextDirection.rtl,
                                    textAlign: TextAlign.center,
                                    functions[1],
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 22),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            userRole == 'owner'
                                ? Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => ReportsScreen(
                                          plot: widget.plot,
                                        )))
                                : Fluttertoast.showToast(
                                    msg: 'ليس لديك صلاحية');
                          },
                          child: Card(
                            color: Colors.transparent,
                            child: Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomLeft,
                                    end: Alignment.topRight,
                                    colors: [
                                      Colors.deepPurple.withValues(alpha: 0.35),
                                      Colors.deepPurpleAccent
                                          .withValues(alpha: 0.9),
                                      Colors.deepPurple
                                    ],
                                  )),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    FluentIcons
                                        .document_bullet_list_clock_24_filled,
                                    size: 100,
                                    color: Colors.white.withValues(alpha: 0.95),
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  Text(
                                    textDirection: TextDirection.rtl,
                                    textAlign: TextAlign.center,
                                    functions[3],
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 22),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
