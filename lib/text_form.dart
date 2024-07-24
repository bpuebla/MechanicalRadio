import 'package:flutter/material.dart';

class MyTextFormField extends StatelessWidget {
  final String hintText;
  final void Function(String?)? onSaved;

  MyTextFormField({
    Key? key,
    required this.hintText,
    required this.onSaved,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Padding(
        key: key,
        padding: const EdgeInsets.all(4.0),
        child: SizedBox(
            width: 200,
            child: TextFormField(
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: hintText,
                contentPadding: const EdgeInsets.all(15.0),
                border: InputBorder.none,
                filled: true,
                fillColor: Colors.grey[200],
              ),
              validator: (value) {
                // only if non empty
                if (value == null || value.isEmpty) {
                  return 'Please enter some text';
                }
                return null;
              },
              onSaved: onSaved, // custom save function
            )));
  }
}
