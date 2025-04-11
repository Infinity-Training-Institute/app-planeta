import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';

class EanScannerComponent extends StatelessWidget {
  const EanScannerComponent({super.key});

  @override
  Widget build(BuildContext context) {
    final player = AudioPlayer();

    return Scaffold(
      appBar: AppBar(title: const Text('Escanear EAN-13')),
      body: MobileScanner(
        controller: MobileScannerController(
          formats: [BarcodeFormat.all],
          detectionSpeed: DetectionSpeed.noDuplicates,
          facing: CameraFacing.back,
          torchEnabled: false,
        ),
        fit: BoxFit.cover,
        onDetect: (capture) async {
          final String code =
              capture.barcodes.isNotEmpty
                  ? capture.barcodes.first.rawValue ?? 'Unknown'
                  : 'Unknown';
          // Handle the scanned EAN-13 code here
          if (code.length == 13 && RegExp(r'^\d+$').hasMatch(code)) {
            // Play sound when a code is scanned
            await player.play(AssetSource('beep.mp3'));
            if (!context.mounted) return;

            Navigator.pop(context, code);
          } else {
            // Show an error message or handle invalid code
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Invalid EAN-13 code scanned.'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
      ),
    );
  }
}
