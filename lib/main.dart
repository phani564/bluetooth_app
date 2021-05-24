import 'dart:async';
import 'dart:convert';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:bluetooth_app/scandevices.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:shared_preferences/shared_preferences.dart';

FlutterBluetoothSerial flutterBluetoothSerial = FlutterBluetoothSerial.instance;
void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // title: 'Splash Screen',
      color: Colors.white,
      theme: ThemeData(
        primaryColor: Colors.white,
      ),
      home: MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    Timer(
        Duration(seconds: 3),
        () => Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => BluetoothApp())));
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
        backgroundColor: Colors.white,
        // appBar: AppBar(),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
                height: height / 1.4,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Image.asset('assets/drdo.png',
                          width: width / 1.4, height: height / 1.4)
                    ])),
            SizedBox(
                height: height / 4,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset('assets/WhatASolutionLogo.jpg',
                          width: width / 2, height: height / 2),
                      Image.asset('assets/vrke.png',
                          width: width / 4, height: height / 4)
                    ])),
          ],
        ));

    // FlutterLogo(size: MediaQuery.of(context).size.height));
  }
}

class BluetoothApp extends StatelessWidget {
  bool isSwitched = false;
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(title: "VRKE", home: ScanDevicesList());
  }
}

class ScanDevicesList extends StatefulWidget {
  @override
  _ScanDevicesListState createState() {
    return new _ScanDevicesListState();
  }
}

class _ScanDevicesListState extends State<ScanDevicesList>
    with TickerProviderStateMixin {
  String firstDeviceDefaultData =
      "{\"DEVICE\":1,\"SP\":0.05,\"DIR\":0,\"START\":0.00,\"SD\":1.0,\"SPEED\":0.05,\"TIME\":0.00,\"STOP\":0.00,\"T/D\":0}";
      
  String secondDeviceDefaultData =
      "{\"DEVICE\":2,\"SP\":0.05,\"DIR\":0,\"START\":0.00,\"SD\":1.0,\"SPEED\":0.05,\"TIME\":0.00,\"STOP\":0.00,\"T/D\":0}";

  bool disabledSendData = true;
  List<bool> _isDisabled = [false, true];
  TabController _tabController;
  ScrollController _scrollController;
  bool fixedScroll;
  String defaultDevice = "HC-05;00:19:09:26:3D:78";////"B8:27:EB:86:65:E1";
  BluetoothConnection _connection;
  bool blueToothStatus = false;
  List<Widget> _devicesList = [
    Text(
      "No Device Connected",
      style: TextStyle(fontWeight: FontWeight.bold),
    )
  ];
  List<String> connectedDeviceNames = ['Device not connected'];
  // List<String> connectedDeviceAddress = ['Device not connected'];
  String _selectedText = 'Device not connected';
  //Device 1
  double _startPoint1 = 0.0,
      _startDelay1 = 1.0,
      _speed1 = 0.05,
      _time1 = 1,
      _time1Max = 25,
      _distance1 = 0,
      _stopPoint1 = 1.3;

  //Device 2
  double _startPoint2 = 0.0,
      _startDelay2 = 1.0,
      _speed2 = 0.05,
      _time2 = 1,
      _time2Max = 25,
      _distance2 = 0,
      _stopPoint2 = 1.3;
  BluetoothDevice connectedDevice;
  TextEditingController dataController = new TextEditingController();

  int deviceSelection = 0;
  int _directionValue1 = 0, _directionValue2 = 0;
  int _eventValue1 = 0, _eventValue2 = 0;
  List<String> nameArray = [];
  List<String> addressArray = [];
  _ScanDevicesListState() {
    setTextFieldData();
  }
  @override
  void initState() {
    _scrollController = ScrollController(initialScrollOffset: 50.0);
    _scrollController.addListener(_scrollListener);
    _tabController = TabController(vsync: this, length: 2);
    _tabController.addListener(_smoothScrollToTop);

    fetchPreferences();

    flutterBluetoothSerial.state.then((state) => setState(() {
          blueToothStatus = state == BluetoothState.STATE_ON ? true : false;
        }));
  }

  _scrollListener() {
    if (fixedScroll) {
      _scrollController.jumpTo(0);
    }
  }

  _smoothScrollToTop() {
    if (_isDisabled[_tabController.index]) {
      int index = _tabController.previousIndex;
      setState(() {
        _tabController.index = index;
      });
    }
    setState(() {
      fixedScroll = _tabController.index == 1;
    });
  }

  void clearCache() async {
    final prefData = await SharedPreferences.getInstance();
    prefData.clear();
  }

  void fetchPreferences() async {
    final prefData = await SharedPreferences.getInstance();
    String deviceArray = prefData.getString('device_array');
    String connectedDevice = prefData.getString('connected_device');
    if (deviceArray != null && deviceArray.isNotEmpty) {
      deviceArray = deviceArray.contains(",") ? deviceArray : deviceArray + ",";
      if (deviceArray != null && deviceArray.contains(",")) {
        setState(() {
          for (String data in deviceArray.split(",")) {
            if (data == defaultDevice) {
              connectedDevice = data;
            }
            if (data.contains(";") &&
                !connectedDeviceNames.contains(data.split(";")[0])) {
              connectedDeviceNames.add(data.split(";")[0]);
            }
          }
          if (this._connection == null &&
              connectedDevice != null &&
              connectedDevice.contains(";")) {
            _selectedText = connectedDevice.split(";")[0];
            connecToDevice(
                connectedDevice.split(";")[0], connectedDevice.split(";")[1]);
          } else {
            if (!connectedDeviceNames.contains('Device not connected')) {
              connectedDeviceNames.add('Device not connected');
            }
            _selectedText = 'Device not connected';
          }
          // bool dataSaved = prefData.getBool('dataSaved');
          // if (dataSaved != null && dataSaved) {
          //   _directionValue1 = prefData.getInt("direction1");
          //   _startPoint1 = prefData.getDouble("startPoint1");
          //   _startDelay1 = prefData.getDouble("startDelay1");
          //   _speed1 = prefData.getDouble("speed1");
          //   _eventValue1 = prefData.getInt("event1");
          //   _time1 = prefData.getDouble("time1");
          //   _distance1 = prefData.getDouble("distance1");
          //   _stopPoint1 = prefData.getDouble("stopPoint1");

          //   _directionValue2 = prefData.getInt("direction2");
          //   _startPoint2 = prefData.getDouble("startPoint2");
          //   _startDelay2 = prefData.getDouble("startDelay2");
          //   _speed2 = prefData.getDouble("speed2");
          //   _eventValue2 = prefData.getInt("event2");
          //   _time2 = prefData.getDouble("time2");
          //   _distance2 = prefData.getDouble("distance2");
          //   _stopPoint2 = prefData.getDouble("stopPoint2");
          //   deviceSelection = prefData.getInt("deviceSelection");
          // }
          // setTextFieldData();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    flutterBluetoothSerial.onStateChanged().listen((event) {
      setState(() {
        blueToothStatus = event.isEnabled;
      });
    });
    double heightValue =
        MediaQuery.of(context).orientation == Orientation.portrait
            ? MediaQuery.of(context).size.height
            : MediaQuery.of(context).size.width;
    double pageHeight = heightValue > 1000 ? 1 : 1.5;
    return SingleChildScrollView(
        child: Container(
            height: heightValue * pageHeight,
            child: Scaffold(
              floatingActionButton: FloatingActionButton(
                  child: Icon(Icons.bluetooth),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  onPressed: () async {
                    final prefData = await SharedPreferences.getInstance();
                    String deviceArray = '', connectedDevice;
                    List<String> deviceList = [];
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ScanDevices(
                                this._connection))).then((value) => {
                          this._connection = value,
                          deviceArray = prefData.getString('device_array'),
                          connectedDevice =
                              prefData.getString('connected_device'),
                          setState(() {
                            connectedDeviceNames = [];
                            connectedDeviceNames.add('Device not connected');
                            if (deviceArray != null) {
                              deviceArray = deviceArray.contains(",")
                                  ? deviceArray
                                  : deviceArray + ",";

                              for (String data in deviceArray.split(",")) {
                                if (data.contains(";") &&
                                    !connectedDeviceNames
                                        .contains(data.split(";")[0])) {
                                  connectedDeviceNames.add(data.split(";")[0]);
                                }
                              }
                            }
                            if (connectedDevice == null) {
                              _selectedText = 'Device not connected';
                            } else {
                              _selectedText = connectedDevice.split(";")[0];
                            }
                          })
                        });
                  }),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.endFloat,
              appBar: AppBar(
                title: Text("VRKE"),
                actions: [
                  Switch(
                    value: blueToothStatus,
                    onChanged: (bool isOn) {
                      enableBluetooth();
                    },
                    activeColor: Colors.green,
                    inactiveTrackColor: Colors.red,
                    activeTrackColor: Colors.green[200],
                  )
                ],
              ),
              body: Column(
                children: [
                  Center(
                      child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Column(children: [
                                      Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          children: [
                                            Radio(
                                              value: 0,
                                              groupValue: deviceSelection,
                                              onChanged:
                                                  _handleDeviceSelectionChanged,
                                            ),
                                            Text(
                                              'Sled - 1',
                                              style:
                                                  new TextStyle(fontSize: 16.0),
                                            ),
                                          ])
                                    ]),
                                    Column(children: [
                                      Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          children: [
                                            Radio(
                                              value: 1,
                                              groupValue: deviceSelection,
                                              onChanged:
                                                  _handleDeviceSelectionChanged,
                                            ),
                                            Text('Sled - 2',
                                                style: new TextStyle(
                                                  fontSize: 16.0,
                                                )),
                                          ])
                                    ]),
                                    Column(children: [
                                      Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          children: [
                                            Radio(
                                              value: 2,
                                              groupValue: deviceSelection,
                                              onChanged:
                                                  _handleDeviceSelectionChanged,
                                            ),
                                            Text('Both',
                                                style: new TextStyle(
                                                  fontSize: 16.0,
                                                ))
                                          ])
                                    ]),
                                  ]),
                              Container(
                                margin: EdgeInsets.only(top: 20.0),
                                child: Center(
                                  child: new DropdownButton<String>(
                                    hint: Text("Status"),
                                    value: _selectedText,
                                    items: connectedDeviceNames
                                        .map((String value) {
                                      return new DropdownMenuItem<String>(
                                        value: value,
                                        child: new Text(value),
                                      );
                                    }).toList(),
                                    onChanged: (String val) {
                                      setState(() {
                                        _selectedText = val;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              Container(
                                  margin: EdgeInsets.only(top: 50.0),
                                  decoration: new BoxDecoration(
                                      color: Theme.of(context).primaryColor),
                                  child: TabBar(
                                    isScrollable: true,
                                    labelColor: Colors.white,
                                    // unselectedLabelColor: Colors.grey,
                                    // isScrollable: true,
                                    controller: _tabController,
                                    indicatorColor: Colors.orange,
                                    indicatorWeight: 4,
                                    labelPadding: EdgeInsets.all(8.0),
                                    tabs: [
                                      Container(
                                        width:
                                            MediaQuery.of(context).size.width /
                                                3,
                                        child: new Tab(text: 'Sled-1'),
                                      ),
                                      Container(
                                        width:
                                            MediaQuery.of(context).size.width /
                                                3,
                                        child: new Tab(text: 'Sled-2'),
                                      )
                                    ],
                                  )),
                              new Container(
                                  height: 550.0,
                                  child: TabBarView(
                                    physics: NeverScrollableScrollPhysics(),
                                    controller: _tabController,
                                    children: [
                                      Center(child: firstDeviceForm()),
                                      Center(child: secondDeviceForm()),
                                    ],
                                  )),
                              TextFormField(
                                maxLines: null,
                                readOnly: true,
                                controller: dataController,
                                decoration: InputDecoration(labelText: 'Data'),
                              ),
                              Container(
                                  margin: EdgeInsets.only(top: 50.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      RaisedButton(
                                          color: Colors.red,
                                          textColor: Colors.white,
                                          child: Text('Exit VRKE'),
                                          onPressed: () {
                                            AlertDialog alert = AlertDialog(
                                              title: Text("Confirm"),
                                              content: Text(
                                                  "Are you sure, you want to Exit?"),
                                              actions: [
                                                FlatButton(
                                                    child: Text("No"),
                                                    onPressed: () async {
                                                      Navigator.of(context,
                                                              rootNavigator:
                                                                  true)
                                                          .pop('dialog');
                                                    }),
                                                FlatButton(
                                                  child: Text("Yes"),
                                                  onPressed: () {
                                                    SystemNavigator.pop();
                                                  },
                                                ),
                                              ],
                                            );
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return alert;
                                              },
                                            );
                                          }),
                                      RaisedButton(
                                          child: Text('Reset Data'),
                                          onPressed: () {
                                            AlertDialog alert = AlertDialog(
                                              title: Text("Confirm"),
                                              content: Text(
                                                  "Are you sure to Reset Data?"),
                                              actions: [
                                                FlatButton(
                                                    child: Text("No"),
                                                    onPressed: () async {
                                                      Navigator.of(context,
                                                              rootNavigator:
                                                                  true)
                                                          .pop('dialog');
                                                    }),
                                                FlatButton(
                                                  child: Text("Yes"),
                                                  onPressed: () async {
                                                    // setState(() {
                                                    //   _startPoint1 = 0.0;
                                                    //   _startDelay1 = 1;
                                                    //   _speed1 = 0.05;
                                                    //   _time1 = 1;
                                                    //   _distance1 = 0;
                                                    //   _stopPoint1 = 0.1;

                                                    //   //Device 2
                                                    //   _startPoint2 = 0.0;
                                                    //   _startDelay2 = 1;
                                                    //   _speed2 = 0.05;
                                                    //   _time2 = 1;
                                                    //   _distance2 = 0;
                                                    //   _stopPoint2 = 0.1;

                                                    //   deviceSelection = 0;
                                                    //   _directionValue1 = 0;
                                                    //   _directionValue2 = 0;
                                                    //   _eventValue1 = 0;
                                                    //   _eventValue2 = 0;
                                                    // });
                                                    // _handleDeviceSelectionChanged(
                                                    //     deviceSelection);
                                                    try {
                                                      if (this._connection !=
                                                          null) {
                                                        this
                                                            ._connection
                                                            .output
                                                            .add(utf8.encode(
                                                                "{\"RESET\":1}"));
                                                        await _connection.output
                                                            .allSent; //.then((value) =>
                                                        {
                                                          final assetsAudioPlayer =
                                                              AssetsAudioPlayer
                                                                  .newPlayer();

                                                          assetsAudioPlayer
                                                              .open(
                                                            Audio(
                                                                "assets/shipbell.mp3"),
                                                          );
                                                          Navigator.of(context,
                                                                  rootNavigator:
                                                                      true)
                                                              .pop('dialog');
                                                          // });
                                                          showDialog(
                                                              context:
                                                                  this.context,
                                                              builder:
                                                                  (BuildContext
                                                                      context) {
                                                                return AlertDialog(
                                                                  title: new Text(
                                                                      "Info"),
                                                                  content: new Text(
                                                                      "Reset Completed"),
                                                                );
                                                              });
                                                        }
                                                      }
                                                    } on Exception catch (exception) {
                                                      Navigator.of(context,
                                                              rootNavigator:
                                                                  true)
                                                          .pop('dialog');
                                                      showDialog(
                                                          context: this.context,
                                                          builder: (BuildContext
                                                              context) {
                                                            return AlertDialog(
                                                              title: new Text(
                                                                  "Error"),
                                                              content: new Text(
                                                                  exception
                                                                      .toString()),
                                                            );
                                                          });
                                                    }
                                                    Navigator.of(context,
                                                            rootNavigator: true)
                                                        .pop('dialog');
                                                  },
                                                ),
                                              ],
                                            );
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return alert;
                                              },
                                            );
                                          }),
                                      RaisedButton(
                                          child: Text('Launch Program'),
                                          color: disabledSendData
                                              ? Colors.grey
                                              : Colors.green,
                                          textColor: disabledSendData
                                              ? Colors.black
                                              : Colors.white,
                                          onPressed: disabledSendData
                                              ? null
                                              : () async {
                                                  AlertDialog alert =
                                                      AlertDialog(
                                                    title: Text("Confirm"),
                                                    content: Text(
                                                        "Press Continue to launch the program. Press Cancel to edit settings"),
                                                    actions: [
                                                      FlatButton(
                                                          child: Text("Cancel"),
                                                          onPressed: () async {
                                                            Navigator.of(
                                                                    context,
                                                                    rootNavigator:
                                                                        true)
                                                                .pop('dialog');
                                                          }),
                                                      FlatButton(
                                                        child: Text("Continue"),
                                                        onPressed: () async {
                                                          try {
                                                            if (this._connection !=
                                                                null) {
                                                              this
                                                                  ._connection
                                                                  .output
                                                                  .add(utf8.encode(
                                                                      dataController
                                                                          .value
                                                                          .text));
                                                              await _connection
                                                                  .output
                                                                  .allSent; //.then((value) =>
                                                              {
                                                                saveData();
                                                                print(
                                                                    "data sent");
                                                                final assetsAudioPlayer =
                                                                    AssetsAudioPlayer
                                                                        .newPlayer();

                                                                assetsAudioPlayer
                                                                    .open(
                                                                  Audio(
                                                                      "assets/shipbell.mp3"),
                                                                );
                                                                Navigator.of(
                                                                        context,
                                                                        rootNavigator:
                                                                            true)
                                                                    .pop(
                                                                        'dialog');
                                                                // });
                                                                showDialog(
                                                                    context: this
                                                                        .context,
                                                                    builder:
                                                                        (BuildContext
                                                                            context) {
                                                                      return AlertDialog(
                                                                        title: new Text(
                                                                            "Info"),
                                                                        content:
                                                                            new Text("Data sent"),
                                                                      );
                                                                    });
                                                              }
                                                            }
                                                          } on Exception catch (exception) {
                                                            Navigator.of(
                                                                    context,
                                                                    rootNavigator:
                                                                        true)
                                                                .pop('dialog');
                                                            showDialog(
                                                                context: this
                                                                    .context,
                                                                builder:
                                                                    (BuildContext
                                                                        context) {
                                                                  return AlertDialog(
                                                                    title: new Text(
                                                                        "Error"),
                                                                    content: new Text(
                                                                        exception
                                                                            .toString()),
                                                                  );
                                                                });
                                                          }

                                                          // }
                                                        },
                                                      ),
                                                    ],
                                                  );
                                                  showDialog(
                                                    context: context,
                                                    builder:
                                                        (BuildContext context) {
                                                      return alert;
                                                    },
                                                  );
                                                }),
                                    ],
                                  ))
                            ],
                          )))
                ],
              ),
            )));
  }

  Widget firstDeviceForm() {
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        Column(
          children: [
            Row(
              children: [
                Radio(
                  value: 0,
                  groupValue: _directionValue1,
                  onChanged: (value) {
                    setState(() {
                      _directionValue1 = value;
                      setTextFieldData();
                    });
                  },
                ),
                Text(
                  'Forward',
                  style: new TextStyle(fontSize: 16.0),
                )
              ],
            )
          ],
        ),
        Column(children: [
          Row(children: [
            Radio(
              value: 1,
              groupValue: _directionValue1,
              onChanged: (value) {
                setState(() {
                  _directionValue1 = value;
                  setTextFieldData();
                });
              },
            ),
            Text('Backward',
                style: new TextStyle(
                  fontSize: 16.0,
                ))
          ])
        ])
      ]),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Container(
          margin: EdgeInsets.only(top: 30.0),
          child: Text('Start Point (m)    ',
              style: TextStyle(fontWeight: FontWeight.bold)),
        )
      ]),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        new Expanded(
            child: Slider(
          value: num.parse(_startPoint1.toStringAsFixed(2)),
          min: 0.0,
          max: 1.3,
          divisions: 26,
          label: _startPoint1.toStringAsFixed(2),
          onChanged: (double value) {
            setState(() {
              _startPoint1 = value; // + 0.05;
              setTextFieldData();
            });
          },
        ))
      ]),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Container(
          margin: EdgeInsets.only(top: 20.0),
          child: Text(
            'Take-off Delay (s)',
            style: TextStyle(fontWeight: FontWeight.bold),
            // textAlign: TextAlign.left,
          ),
        )
      ]),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        new Expanded(
            child: Slider(
          value: num.parse(_startDelay1.toStringAsFixed(1)),
          min: 1,
          max: 25,
          divisions: 24,
          label: _startDelay1.toStringAsFixed(1),
          onChanged: (double value) {
            setState(() {
              if (value > _time1Max) {
                value = _time1Max;
              }
              _startDelay1 = value; //+ 0.05;
              setTextFieldData();
            });
          },
        ))
      ]),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Container(
          margin: EdgeInsets.only(top: 20.0),
          child: Text(
            'Speed (m/s)      ',
            style: TextStyle(fontWeight: FontWeight.bold),
            // textAlign: TextAlign.left,
          ),
        )
      ]),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        new Expanded(
            child: Slider(
          value: num.parse(_speed1.toStringAsFixed(2)),
          min: 0.05,
          max: 0.5,
          divisions: 9,
          label: _speed1.toStringAsFixed(2),
          onChanged: (double value) {
            setState(() {
              _speed1 = value; //+ 0.05;
              _time1Max = ((1.3 / _speed1) - 1);
              if (_time1 > _time1Max) {
                _time1 = _time1Max;
              }
              if (_startDelay1 > _time1Max) {
                _startDelay1 = _time1Max;
              }
              setTextFieldData();
            });
          },
        ))
      ]),
      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        Column(children: [
          Row(children: [
            Radio(
              value: 1,
              groupValue: _eventValue1,
              onChanged: (value) {
                setState(() {
                  _eventValue1 = value;
                  setTextFieldData();
                });
              },
            ),
            Text(
              'Time (s)',
              style: new TextStyle(fontSize: 16.0),
            )
          ])
        ]),
        Column(children: [
          Row(children: [
            Radio(
              value: 0,
              groupValue: _eventValue1,
              onChanged: (value) {
                setState(() {
                  _eventValue1 = value;
                  setTextFieldData();
                });
              },
            ),
            Text('Distance (m)',
                style: new TextStyle(
                  fontSize: 16.0,
                ))
          ])
        ])
      ]),
      Visibility(
          visible: _eventValue1 == 1,
          child: Container(
              margin: EdgeInsets.only(top: 20.0),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Event Time (s)   ',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ]))),
      Visibility(
        visible: _eventValue1 == 1,
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          new Expanded(
              child: Slider(
            value: num.parse(_time1.toStringAsFixed(1)),
            min: 1,
            max: 25,
            divisions: 24,
            label: num.parse(_time1.toStringAsFixed(1)).toString(),
            onChanged: (double value) {
              setState(() {
                if (value > _time1Max) {
                  value = _time1Max;
                }
                _time1 = value;
                setTextFieldData();
              });
            },
          ))
        ]),
      ),
      Visibility(
          visible: _eventValue1 == 0,
          child: Container(
              margin: EdgeInsets.only(top: 20.0),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Event Distance (m)',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ]))),
      Visibility(
          visible: _eventValue1 == 0,
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            new Expanded(
                child: Slider(
              value: num.parse(_distance1.toStringAsFixed(2)),
              min: 0.0,
              max: 1.3,
              divisions: 26,
              label: num.parse(_distance1.toStringAsFixed(2)).toString(),
              onChanged: (double value) {
                setState(() {
                  _distance1 = value;
                  setTextFieldData();
                });
              },
            ))
          ])),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Container(
          margin: EdgeInsets.only(top: 20.0),
          child: Text(
            'Stop Point (m)',
            style: TextStyle(fontWeight: FontWeight.bold),
            // textAlign: TextAlign.left,
          ),
        )
      ]),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        new Expanded(
            child: Slider(
          value: num.parse(_stopPoint1.toStringAsFixed(2)),
          min: 0.0,
          max: 1.3,
          divisions: 26,
          label: _stopPoint1.toStringAsFixed(2),
          onChanged: (double value) {
            setState(() {
              _stopPoint1 = value; //+ 0.05;
              setTextFieldData();
            });
          },
        ))
      ])
    ]);
  }

  Widget secondDeviceForm() {
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        Column(
          children: [
            Row(
              children: [
                Radio(
                    value: 0,
                    groupValue: _directionValue2,
                    onChanged: (value) {
                      setState(() {
                        _directionValue2 = value;
                        setTextFieldData();
                      });
                    }),
                Text(
                  'Forward',
                  style: new TextStyle(fontSize: 16.0),
                )
              ],
            )
          ],
        ),
        Column(children: [
          Row(children: [
            Radio(
              value: 1,
              groupValue: _directionValue2,
              onChanged: (value) {
                setState(() {
                  _directionValue2 = value;
                  setTextFieldData();
                });
              },
            ),
            Text('Backward',
                style: new TextStyle(
                  fontSize: 16.0,
                ))
          ])
        ])
      ]),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Container(
          margin: EdgeInsets.only(top: 30.0),
          child: Text('Start Point (m)    ',
              style: TextStyle(fontWeight: FontWeight.bold)),
        )
      ]),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        new Expanded(
            child: Slider(
          value: num.parse(_startPoint2.toStringAsFixed(2)),
          min: 0.0,
          max: 1.3,
          divisions: 26,
          label: _startPoint2.toStringAsFixed(2),
          onChanged: (double value) {
            setState(() {
              _startPoint2 = value; // + 0.05;
              setTextFieldData();
            });
          },
        ))
      ]),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Container(
          margin: EdgeInsets.only(top: 20.0),
          child: Text(
            'Take-off Delay (s)',
            style: TextStyle(fontWeight: FontWeight.bold),
            // textAlign: TextAlign.left,
          ),
        )
      ]),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        new Expanded(
            child: Slider(
          value: num.parse(_startDelay2.toStringAsFixed(2)),
          min: 1,
          max: 25,
          divisions: 24,
          label: _startDelay2.toStringAsFixed(1),
          onChanged: (double value) {
            setState(() {
              if (value > _time2Max) {
                value = _time2Max;
              }
              _startDelay2 = value; //+ 0.05;
              setTextFieldData();
            });
          },
        ))
      ]),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Container(
          margin: EdgeInsets.only(top: 20.0),
          child: Text(
            'Speed (m/s)      ',
            style: TextStyle(fontWeight: FontWeight.bold),
            // textAlign: TextAlign.left,
          ),
        )
      ]),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        new Expanded(
            child: Slider(
          value: num.parse(_speed2.toStringAsFixed(2)),
          min: 0.05,
          max: 0.5,
          divisions: 9,
          label: _speed2.toStringAsFixed(2),
          onChanged: (double value) {
            setState(() {
              _speed2 = value; //+ 0.05;
              _time2Max = ((1.3 / _speed2) - 1);
              if (_time2 > _time2Max) {
                _time2 = _time2Max;
              }
              if (_startDelay2 > _time2Max) {
                _startDelay2 = _time2Max;
              }
              setTextFieldData();
            });
          },
        ))
      ]),
      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        Column(children: [
          Row(children: [
            Radio(
              value: 1,
              groupValue: _eventValue2,
              onChanged: (value) {
                setState(() {
                  _eventValue2 = value;
                  setTextFieldData();
                });
              },
            ),
            Text(
              'Time (s)',
              style: new TextStyle(fontSize: 16.0),
            )
          ])
        ]),
        Column(children: [
          Row(children: [
            Radio(
              value: 0,
              groupValue: _eventValue2,
              onChanged: (value) {
                setState(() {
                  _eventValue2 = value;
                  setTextFieldData();
                });
              },
            ),
            Text('Distance (m)',
                style: new TextStyle(
                  fontSize: 16.0,
                ))
          ])
        ])
      ]),
      Visibility(
          visible: _eventValue2 == 1,
          child: Container(
              margin: EdgeInsets.only(top: 20.0),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Event Time (s)   ',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ]))),
      Visibility(
        visible: _eventValue2 == 1,
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          new Expanded(
              child: Slider(
            value: num.parse(_time2.toStringAsFixed(1)),
            min: 1,
            max: 25,
            divisions: 24,
            label: num.parse(_time2.toStringAsFixed(1)).toString(),
            onChanged: (double value) {
              setState(() {
                if (value > _time2Max) {
                  value = _time2Max;
                }
                _time2 = value;
                setTextFieldData();
              });
            },
          ))
        ]),
      ),
      Visibility(
          visible: _eventValue2 == 0,
          child: Container(
              margin: EdgeInsets.only(top: 20.0),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Event Distance (m)',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ]))),
      Visibility(
          visible: _eventValue2 == 0,
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            new Expanded(
                child: Slider(
              value: num.parse(_distance2.toStringAsFixed(2)),
              min: 0.0,
              max: 1.3,
              divisions: 26,
              label: num.parse(_distance2.toStringAsFixed(2)).toString(),
              onChanged: (double value) {
                setState(() {
                  _distance2 = value;
                  setTextFieldData();
                });
              },
            ))
          ])),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Container(
          margin: EdgeInsets.only(top: 20.0),
          child: Text(
            'Stop Point (m)',
            style: TextStyle(fontWeight: FontWeight.bold),
            // textAlign: TextAlign.left,
          ),
        )
      ]),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        new Expanded(
            child: Slider(
          value: num.parse(_stopPoint2.toStringAsFixed(2)),
         min: 0.0,
          max: 1.3,
          divisions: 26,
          label: _stopPoint2.toStringAsFixed(2),
          onChanged: (double value) {
            setState(() {
              _stopPoint2 = value; //+ 0.05;
              setTextFieldData();
            });
          },
        ))
      ])
    ]);
  }

  void _handleDeviceSelectionChanged(int value) {
    setState(() {
      deviceSelection = value;
      if (value == 0) {
        _isDisabled[0] = false;
        _isDisabled[1] = true;
        _tabController.index = 0;
      } else if (value == 1) {
        _isDisabled[0] = true;
        _isDisabled[1] = false;
        _tabController.index = 1;
      } else {
        _isDisabled[0] = false;
        _isDisabled[1] = false;
      }
      setTextFieldData();
    });
  }

  setTextFieldData() {
    String jsonData = "", firstData = "", secondData = "";
    if (deviceSelection == 0 || deviceSelection == 2) {
      String startValue1 = _startPoint1.toStringAsFixed(2),
          stopValue1 = _stopPoint1.toStringAsFixed(2);
      String timeorDistance1 = _eventValue1.toString();
      String eventValue1;
      if (_eventValue1 == 1) {
        eventValue1 = _time1.toStringAsFixed(1);
      } else {
        eventValue1 = _distance1.toStringAsFixed(2);
      }
      String spValue;
      if (_directionValue1 == 0) {
        spValue = "0.05";
      } else {
        spValue = "1.45";
      }

      firstData = "{\"DEVICE\":1" +
          ",\"SP\":" +
          spValue.toString() +
          ",\"DIR\":" +
          _directionValue1.toString() +
          ",\"START\":" +
          startValue1 +
          ",\"SD\":" +
          _startDelay1.toStringAsFixed(1) +
          ",\"SPEED\":" +
          _speed1.toStringAsFixed(2) +
          ",\"TIME\":" +
          eventValue1 +
          ",\"STOP\":" +
          stopValue1 +
          ",\"T/D\":" +
          timeorDistance1 +
          "}";
      jsonData = firstData;
    }
    if (deviceSelection == 1 || deviceSelection == 2) {
      String startValue2 = _startPoint2.toStringAsFixed(2),
          stopValue2 = _stopPoint2.toStringAsFixed(2);
      String timeorDistance2 = _eventValue2.toString();
      String eventValue2;
      if (_eventValue2 == 1) {
        eventValue2 = _time2.toStringAsFixed(1);
      } else {
        eventValue2 = _distance2.toStringAsFixed(2);
      }
      String spValue;
      if (_directionValue2 == 0) {
        spValue = "0.05";
      } else {
        spValue = "1.45";
      }

      secondData = "{\"DEVICE\":2" +
          ",\"SP\":" +
          spValue.toString() +
          ",\"DIR\":" +
          _directionValue2.toString() +
          ",\"START\":" +
          startValue2 +
          ",\"SD\":" +
          _startDelay2.toStringAsFixed(1) +
          ",\"SPEED\":" +
          _speed2.toStringAsFixed(2) +
          ",\"TIME\":" +
          eventValue2 +
          ",\"STOP\":" +
          stopValue2 +
          ",\"T/D\":" +
          timeorDistance2 +
          "}";
      jsonData += secondData;
    }
    bool buttonDisableState = true;
    if (firstData.isNotEmpty &&
        deviceSelection == 0 &&
        firstData != firstDeviceDefaultData) {
      buttonDisableState = false;
    } else if (secondData.isNotEmpty &&
        deviceSelection == 1 &&
        secondData != secondDeviceDefaultData) {
      buttonDisableState = false;
    } else if (firstData.isNotEmpty &&
        secondData.isNotEmpty &&
        deviceSelection == 2 &&
        firstData != firstDeviceDefaultData &&
        secondData != secondDeviceDefaultData) {
      buttonDisableState = false;
    }

    if (this.mounted) {
      setState(() {
        disabledSendData = buttonDisableState;
      });
    }
    dataController = new TextEditingController(text: (jsonData));
  }

  Future<void> enableBluetooth() async {
    setState(() {
      blueToothStatus = !blueToothStatus;
    });
    // Retrieving the current Bluetooth state

    // If the Bluetooth is off, then turn it on first
    // and then retrieve the devices that are paired.
    if (blueToothStatus == true) {
      await flutterBluetoothSerial.requestEnable();
      // await getPairedDevices();
      return true;
    } else {
      await flutterBluetoothSerial.requestDisable();
    }
    return false;
  }

  saveData() async {
    final prefData = await SharedPreferences.getInstance();
    prefData.setBool("dataSaved", true);
    prefData.setInt("direction1", _directionValue1);
    prefData.setDouble("startPoint1", _startPoint1);
    prefData.setDouble("startDelay1", _startDelay1);
    prefData.setDouble("speed1", _speed1);
    prefData.setInt("event1", _eventValue1);
    prefData.setDouble("time1", _time1);
    prefData.setDouble("distance1", _distance1);
    prefData.setDouble("stopPoint1", _stopPoint1);

    prefData.setInt("direction2", _directionValue2);
    prefData.setDouble("startPoint2", _startPoint2);
    prefData.setDouble("startDelay2", _startDelay2);
    prefData.setDouble("speed2", _speed2);
    prefData.setInt("event2", _eventValue2);
    prefData.setDouble("time2", _time2);
    prefData.setDouble("distance2", _distance2);
    prefData.setDouble("stopPoint2", _stopPoint2);
    prefData.setInt("deviceSelection", deviceSelection);
  }

  void connecToDevice(String name, String connectedAddress) async {
    try {
      List<Widget> devices = [
        Text(
          "No Device Connected",
          style: TextStyle(fontWeight: FontWeight.bold),
        )
      ];
      List<String> names = ['Device not connected'];
      List<String> address = ['Device not connected'];
      BluetoothConnection _connection =
          await BluetoothConnection.toAddress(connectedAddress);

      print('Connected to the device');
      setState(() {
        this._connection = _connection;
        devices = [];
        names = [];
        address = [];
        devices.add(ListTile(
          leading: Icon(Icons.bluetooth_connected),
          title: Text((name)),
          subtitle: Text((connectedAddress.toString())),
          onTap: () async {},
        ));
        names.add(name);
        address.add(connectedAddress);
      });

      this._connection.input.listen(null).onDone(() async {});
    } catch (e) {
      print(e);
    } finally {}
  }
}
