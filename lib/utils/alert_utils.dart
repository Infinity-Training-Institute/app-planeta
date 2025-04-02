import 'package:flutter/material.dart';

void showAlert(BuildContext context, String typeMessage, String message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(typeMessage),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text("Aceptar"),
          ),
        ],
      );
    },
  );
}
