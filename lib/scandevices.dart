import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScanDevices extends StatefulWidget {
  BluetoothConnection _connection;
  ScanDevices(BluetoothConnection connection) {
    this._connection = connection;
  }

  @override
  State<StatefulWidget> createState() => _ScanDevicesState(this._connection);
}

class _ScanDevicesState extends State<ScanDevices> {
  ProgressDialog pr;
  List<Widget> _listSection = List<Widget>();
  String status = "";
  bool isloaded = false;
  BluetoothConnection connection;

  MaterialColor buttonClr = Colors.green;
  String buttonText = 'Connect';
  FlutterBluetoothSerial flutterBluetoothSerial =
      FlutterBluetoothSerial.instance;

  BuildContext context;
  _ScanDevicesState(BluetoothConnection _connection) {
    this.connection = _connection;
  }

  void initState() {
    super.initState();
    this._listSection = [];
    this.fetchDevices();
  }

  @override
  Widget build(BuildContext context) {
    //For normal dialog
    pr = ProgressDialog(context,
        type: ProgressDialogType.Normal, isDismissible: true);
    if (this.mounted) {
      setState(() {
        this.context = context;
      });
    }
    return new WillPopScope(
        child: Scaffold(
          appBar: AppBar(
            title: Text("Paired Devices"),
          ),
          body: SingleChildScrollView(
              child: Column(
            children: [
              SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    shrinkWrap: true,
                    children: _listSection,
                  ))
            ],
          )),
        ),
        onWillPop: () async {
          Navigator.pop(context, Future.value(this.connection));
          return false;
        });
  }

  void fetchDevices() {
    bool connection = false;
    List<Widget> temp = new List<Widget>();
    flutterBluetoothSerial
        .getBondedDevices()
        .asStream()
        .listen((value) async => {
              print(value),
              flutterBluetoothSerial.state.then((state) => setState(() {
                    if (state == BluetoothState.STATE_OFF) {
                      temp.add(ListTile(
                          title: Text(
                        "Please,Turn on Bluetooth",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20.0,
                            color: Colors.red),
                      )));
                    }
                    this._listSection = List.from(temp);
                  })),
              for (BluetoothDevice r in value)
                {
                  connection = r.isConnected,
                  if (r.isConnected)
                    {
                      buttonClr = Colors.red,
                      buttonText = 'Disconnect',
                    }
                  else
                    {
                      buttonClr = Colors.green,
                      buttonText = 'Connect',
                    },
                  temp.add(
                    ListTile(
                      leading: Icon(Icons.bluetooth),
                      title:
                          Text('${r.name}'.isEmpty ? 'Unknown' : '${r.name}'),
                      subtitle: Text(r.address.toString()),
                      trailing: RaisedButton(
                        padding: const EdgeInsets.all(0.0),
                        textColor: Colors.white,
                        color: buttonClr,
                        child: connection
                            ? Text(buttonText, style: TextStyle(fontSize: 20))
                            : Text(buttonText, style: TextStyle(fontSize: 20)),
                        onPressed: () async {
                          if (buttonText == 'Connect' && !r.isConnected) {
                            await pr.show();
                            if (this.mounted) {
                              setState(() {
                                status = "Connecting...";
                              });
                            }
                            await connecToDevice(r.name, r.address);
                            print(buttonClr);
                            print(buttonText);
                          } else {
                            if (this.connection != null) {
                              this.connection.close();
                            }
                            this.connection = null;
                            if (this.mounted) {
                              setState(() {
                                buttonClr = Colors.green;
                                buttonText = 'Connect';
                              });
                              final prefs =
                                  await SharedPreferences.getInstance();
                              prefs.setString('connected_device', null);
                            }
                          }
                        },
                      ),
                    ),
                  ),
                },
              if (this.mounted)
                {
                  setState(() {
                    _listSection = temp;
                  }),
                }
            });
  }

  Future connecToDevice(String name, String address) async {
    try {
      BluetoothConnection _connection = await BluetoothConnection.toAddress(
          address); //.then((_connection) async {
      print('Connected to the device');
      this.connection = _connection;
      await pr.hide();
      final prefs = await SharedPreferences.getInstance();
      String deviceArray = prefs.getString('device_array');
      if (deviceArray == null || !deviceArray.contains(name)) {
        if (deviceArray == null || deviceArray.isEmpty) {
          deviceArray = name + ";" + address;
        } else {
          deviceArray = deviceArray + "," + name + ";" + address;
        }
        prefs.setString('device_array', deviceArray);
      }
      prefs.setString('connected_device', name + ";" + address);
      if (this.mounted) {
        setState(() {
          buttonClr = Colors.red;
          buttonText = 'Disconnect';
        });
      }
      showDialog(
          context: this.context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: new Text("Info"),
              content: new Text("Connected"),
            );
          });

      this.connection.input.listen(null).onDone(() {
        if (this.mounted) {
          setState(() {});
        }
      });
    } catch (e) {
      print(e);
      await pr.hide();
      showDialog(
          context: this.context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: new Text("Error"),
              content: new Text('$name' + " not in discoverable state"),
            );
          });
    } finally {
      await pr.hide();
      setState(() {});
    }
  }
}
