import 'dart:convert';
import 'package:states_rebuilder/states_rebuilder.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

final rm = RM.inject(() => RadioState());

class RadioStation {
  String name = "";
  bool status = false;
}

class RadioState {
  Widget station =
      const Text('กรุณาเพิ่มสถานี', style: TextStyle(fontSize: 20));
  void addStation(context) {
    final addstationRm = RM.inject(() => RadioStation());
    GlobalKey<FormState> formKey = GlobalKey<FormState>();
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return addstationRm.rebuild(() => Form(
                key: formKey,
                child: AlertDialog(
                  scrollable: true,
                  title: const Text('เพิ่มสถานี'),
                  content: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: <Widget>[
                        TextFormField(
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'กรุณากรอกชื่อสถานี';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            addstationRm.setState((s) => s.name = value!);
                          },
                          decoration: const InputDecoration(
                            labelText: 'ชื่อสถานี',
                            icon: Icon(Icons.radio),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            const Text('สถานะ'),
                            const SizedBox(width: 20),
                            Switch(
                                value: addstationRm.state.status,
                                onChanged: (value) {
                                  addstationRm
                                      .setState((s) => s.status = value);
                                })
                          ],
                        )
                      ],
                    ),
                  ),
                  actions: [
                    Container(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ElevatedButton(
                            child: const Text("เพิ่มสถานี"),
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                formKey.currentState!.save();
                                Map<String, dynamic> data = {
                                  "name": addstationRm.state.name,
                                  "status": addstationRm.state.status
                                };
                                rm.state.setStation(data);
                                Navigator.pop(context);
                              }
                            }),
                      ),
                    )
                  ],
                ),
              ));
        });
  }

  void load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? radio = prefs.getString("radio");
    if (radio != null) {
      print(radio);
      rm.setState((s) => s.station = ListView.builder(
          shrinkWrap: true,
          itemCount: (json.decode(radio) as List).length,
          itemBuilder: (context, index) {
            List<Map<String, dynamic>> list = (json.decode(radio) as List)
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
            return Card(
              child: ListTile(
                title: Text(list[index]["name"]),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Switch(
                          value: list[index]["status"],
                          onChanged: (value) {
                            rm.setState((s) => s.changeStatus(index, value));
                          }),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: IconButton(
                          onPressed: () {
                            rm.state.editStation(context, index);
                          },
                          icon: const Icon(Icons.edit)),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: IconButton(
                          onPressed: () {
                            // dialog
                            showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('ลบสถานี'),
                                    content: const Text(
                                        'คุณต้องการลบสถานีนี้หรือไม่'),
                                    actions: [
                                      TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: const Text('ยกเลิก')),
                                      TextButton(
                                          onPressed: () {
                                            rm.setState(
                                                (s) => s.deleteStation(index));
                                            Navigator.pop(context);
                                          },
                                          child: const Text('ลบ')),
                                    ],
                                  );
                                });
                          },
                          icon: const Icon(Icons.delete)),
                    ),
                  ],
                ),
              ),
            );
          }));
    }
  }

  void setAll(bool status) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? radio = prefs.getString("radio");
    if (radio != null) {
      List<Map<String, dynamic>> list = (json.decode(radio) as List)
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      for (int i = 0; i < list.length; i++) {
        list[i]["status"] = status;
      }
      prefs.setString("radio", jsonEncode(list));
      rm.state.load();
    }
  }

  void changeStatus(int index, bool status) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? radio = prefs.getString("radio");
    if (radio != null) {
      List<Map<String, dynamic>> list = (json.decode(radio) as List)
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      list[index]["status"] = status;
      prefs.setString("radio", jsonEncode(list));
      rm.state.load();
    }
  }

  void setStation(Map<String, dynamic> data) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? radio = prefs.getString("radio");
    if (radio != null) {
      List<Map<String, dynamic>> list = (json.decode(radio) as List)
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      list.add(data);
      prefs.setString("radio", jsonEncode(list));
      rm.state.load();
    } else {
      List<Map<String, dynamic>> list = [];
      list.add(data);
      prefs.setString("radio", jsonEncode(list));
      rm.state.load();
    }
  }

  void deleteStation(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? radio = prefs.getString("radio");
    if (radio != null) {
      List<Map<String, dynamic>> list = (json.decode(radio) as List)
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      list.removeAt(index);
      prefs.setString("radio", jsonEncode(list));
      rm.state.load();
    }
  }

  Future<Map?> getDataFromIndex(int index) async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? radio = prefs.getString("radio");
    if (radio != null) {
      List<Map<String, dynamic>> list = (json.decode(radio) as List)
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      return list[index];
    }
    return null;
  }

  void editStationDetail(int index, data) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? radio = prefs.getString("radio");
    if (radio != null) {
      List<Map<String, dynamic>> list = (json.decode(radio) as List)
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      list[index] = data;
      prefs.setString("radio", jsonEncode(list));
      rm.state.load();
    }
  }

  void editStation(context, int index) async{
    final addstationRm = RM.inject(() => RadioStation());
    final dataLoad = await rm.state.getDataFromIndex(index);
    addstationRm.setState((s){
      s.name = dataLoad!["name"];
      s.status = dataLoad!["status"];
      return null;
    });
    GlobalKey<FormState> formKey = GlobalKey<FormState>();
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return addstationRm.rebuild(() => Form(
                key: formKey,
                child: AlertDialog(
                  scrollable: true,
                  title: const Text('แก้ไขสถานี'),
                  content: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: <Widget>[
                        TextFormField(
                          initialValue: addstationRm.state.name,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'กรุณากรอกชื่อสถานี';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            addstationRm.setState((s) => s.name = value!);
                          },
                          decoration: const InputDecoration(
                            labelText: 'ชื่อสถานี',
                            icon: Icon(Icons.radio),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            const Text('สถานะ'),
                            const SizedBox(width: 20),
                            Switch(
                                value: addstationRm.state.status,
                                onChanged: (value) {
                                  addstationRm
                                      .setState((s) => s.status = value);
                                })
                          ],
                        )
                      ],
                    ),
                  ),
                  actions: [
                    Container(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ElevatedButton(
                            child: const Text("แก้ไขสถานี"),
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                formKey.currentState!.save();
                                Map<String, dynamic> data = {
                                  "name": addstationRm.state.name,
                                  "status": addstationRm.state.status
                                };
                                rm.state.editStationDetail(index, data);
                                Navigator.pop(context);
                              }
                            }),
                      ),
                    )
                  ],
                ),
              ));
        });
  }
}

void main() {
  runApp(const RadioOnline());
}

class RadioOnline extends StatelessWidget {
  const RadioOnline({super.key});
  @override
  Widget build(BuildContext context) {
    rm.state.load();
    return MaterialApp(
      title: 'วิทยุออนไลน์',
      theme: ThemeData(
        useMaterial3: false,
        primaryColor: Colors.blue,
      ),
      home: Scaffold(
        body: rm.rebuild(() {
          return ui();
        }),
        appBar: AppBar(
          title: const Text(
              'ระบบควบคุมการกระจายสัญญาณวิทยุออนไลน์ เทศบาลตำบลเกษตรพัฒนา'),
        ),
      ),
    );
  }
}

class ui extends StatelessWidget {
  const ui({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(50),
      child: Column(children: [
        manu(),
        const SizedBox(height: 20),
        SingleChildScrollView(child: rm.state.station),
      ]),
    );
  }
}

class manu extends StatelessWidget {
  const manu({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          'images/logo.png',
          width: 150,
          height: 150,
        ),
        const SizedBox(width: 20),
        mainBTN(
            action: () {
              rm.state.setAll(false);
            },
            icon: Icons.music_off,
            text: "ปิดสถานีทั้งหมด",
            btnColor: Colors.red),
        const SizedBox(width: 20),
        mainBTN(
            action: () {
              rm.state.setAll(true);
            },
            icon: Icons.music_note,
            text: "เปิดสถานีทั้งหมด",
            btnColor: Colors.green),
        const SizedBox(width: 20),
        mainBTN(
            action: () {
              rm.state.addStation(context);
              rm.state.load();
            },
            icon: Icons.add,
            text: "เพิ่มสถานี",
            btnColor: Colors.blue)
      ],
    );
  }
}

class mainBTN extends StatelessWidget {
  VoidCallback? action;
  IconData? icon;
  String? text;
  Color? btnColor;
  mainBTN(
      {super.key,
      required this.action,
      required this.icon,
      required this.text,
      required this.btnColor});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: action,
      style: ButtonStyle(backgroundColor: MaterialStateProperty.all(btnColor)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 10),
            Text(text!),
          ],
        ),
      ),
    );
  }
}
