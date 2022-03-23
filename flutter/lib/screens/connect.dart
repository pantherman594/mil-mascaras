import 'package:flutter/material.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({
    Key? key,
    required this.onSubmit,
  }) : super(key: key);

  final Function(String address) onSubmit;

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _addressField;

  @override
  void initState() {
    super.initState();
    _addressField = TextEditingController(text: '');
  }

  @override
  void dispose() {
    _addressField.dispose();
    super.dispose();
  }

  void _submit() {
    widget.onSubmit(_addressField.text);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
        key: _formKey,
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextFormField(
                  controller: _addressField,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'hostname or hostname:port',
                      labelText: 'MQTT Server Address',
                  ),
              ),
              ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Connect'),
              ),
            ]),
        );
  }
}
