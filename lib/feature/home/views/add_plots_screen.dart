import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/colors.dart';
import '../Bloc/plot_cubit.dart';
import '../data/plot_model.dart';

class AddPlotScreen extends StatefulWidget {
  final Plot? plot; // Optional: for editing

  const AddPlotScreen({super.key, this.plot});

  @override
  State<AddPlotScreen> createState() => _AddPlotScreenState();
}

class _AddPlotScreenState extends State<AddPlotScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  final _cropTypeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.plot != null) {
      _nameController.text = widget.plot!.name;
      _numberController.text = widget.plot!.number;
      _cropTypeController.text = widget.plot!.cropType;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _cropTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(color: Colors.white),
          title: Text(
            widget.plot == null ? 'إضافة حوشة' : 'تعديل حوشة',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColor.green,
        ),
        body: Padding(
          padding: const EdgeInsets.all(25),
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                        labelText: 'اسم الحوشة',
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(10)))),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'يرجى إدخال اسم الحوشة';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _numberController,
                    decoration: const InputDecoration(
                        labelText: 'رقم الحوشة',
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(10)))),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'يرجى إدخال رقم الحوشة';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _cropTypeController,
                    decoration: const InputDecoration(
                        labelText: 'نوع المحصول',
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(10)))),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'يرجى إدخال نوع المحصول';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        if (widget.plot == null) {
                          // Add new plot
                          context.read<PlotCubit>().addPlot(
                                name: _nameController.text,
                                number: _numberController.text,
                                cropType: _cropTypeController.text,
                              );
                        } else {
                          // Edit existing plot
                          context.read<PlotCubit>().editPlot(
                                widget.plot!.plotId,
                                name: _nameController.text,
                                number: _numberController.text,
                                cropType: _cropTypeController.text,
                              );
                        }
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 15),
                    ),
                    child: Text(
                      widget.plot == null ? 'إضافة' : 'تعديل',
                      style: const TextStyle(fontSize: 18, color: Colors.white),
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
}
