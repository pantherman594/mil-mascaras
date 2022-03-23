import 'package:flutter/material.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({
    Key? key,
    required this.sendMessage,
  }) : super(key: key);

  final Function(String command, {List<String>? args}) sendMessage;

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  final v2 = false;
  final _pressed = <String, bool>{};
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _volField;
  late TextEditingController _soundField;

  @override
  void initState() {
    super.initState();
    _volField = TextEditingController(text: '0.50');
    _soundField = TextEditingController(text: '');
  }

  @override
  void dispose() {
    _volField.dispose();
    super.dispose();
  }

  void _submit() {
    widget.sendMessage("Vol=" + _volField.text);
    widget.sendMessage(_soundField.text);
  }

  Widget _buildButton(String direction, IconData icon) {
    return Container(
        child: GestureDetector(
            onTapDown: (_) {
              setState(() {
                _pressed[direction] = true;
              });
              widget.sendMessage(direction);
            },
            onPanStart: (_) {
              setState(() {
                _pressed[direction] = true;
              });
              widget.sendMessage(direction);
            },
            onPanEnd: (_) {
              setState(() {
                _pressed[direction] = false;
              });
              if (v2 && direction != "stop") {
                widget.sendMessage(direction + "_up");
              } else if (!v2) {
                widget.sendMessage("stop");
              }
            },
            onPanCancel: () {
              setState(() {
                _pressed[direction] = false;
              });
              if (v2 && direction != "stop") {
                widget.sendMessage(direction + "_up");
              } else if (!v2) {
                widget.sendMessage("stop");
              }
            },
            onTapUp: (_) {
              setState(() {
                _pressed[direction] = false;
              });
              if (v2 && direction != "stop") {
                widget.sendMessage(direction + "_up");
              } else if (!v2) {
                widget.sendMessage("stop");
              }
            },
            onTapCancel: () {
              setState(() {
                _pressed[direction] = false;
              });
              if (v2 && direction != "stop") {
                widget.sendMessage(direction + "_up");
              } else if (!v2) {
                widget.sendMessage("stop");
              }
            },
            child: Container(
                       padding: const EdgeInsets.all(24),
                       child: Icon(icon),
                       color: _pressed[direction] ?? false ? Colors.grey[400] : Colors.grey[300],
                   ),
          ),
        padding: const EdgeInsets.all(4),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: <Widget>[
      Container(
          margin: const EdgeInsets.all(10),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                _buildButton("forward", Icons.arrow_drop_up),
                Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      _buildButton("left", Icons.arrow_left),
                      _buildButton("stop", Icons.stop),
                      _buildButton("right", Icons.arrow_right),
                    ],
                ),
                _buildButton("backward", Icons.arrow_drop_down),
                Form(
                    key: _formKey,
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          TextFormField(
                              controller: _volField,
                              decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Volume',
                              ),
                          ),
                          TextFormField(
                              controller: _soundField,
                              decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Sound',
                              ),
                          ),
                          ElevatedButton(
                              onPressed: _submit,
                              child: const Text('Submit'),
                          ),
                        ]),
                    ),
              ],
          ),
      )]);
  }
}
