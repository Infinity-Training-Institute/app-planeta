import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';

class EanScannerComponent extends StatefulWidget {
  const EanScannerComponent({super.key});

  @override
  State<EanScannerComponent> createState() => _EanScannerComponentState();
}

class _EanScannerComponentState extends State<EanScannerComponent> {
  final MobileScannerController controller = MobileScannerController(
    formats: [BarcodeFormat.all],
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  final AudioPlayer player = AudioPlayer();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear EAN-13')),
      body: MobileScanner(
        controller: controller,
        fit: BoxFit.cover,
        onDetect: (capture) async {
          final String code =
              capture.barcodes.isNotEmpty
                  ? capture.barcodes.first.rawValue ?? 'Unknown'
                  : 'Unknown';
          if (code.length == 13 && RegExp(r'^\d+$').hasMatch(code)) {
            await player.play(AssetSource('beep.mp3'));
            if (!context.mounted) return;
            Navigator.pop(context, code);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Invalid EAN-13 code scanned.'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
      ),
    );
  }
}

class QrScannerComponent extends StatefulWidget {
  const QrScannerComponent({super.key});

  @override
  State<QrScannerComponent> createState() => _QrScannerComponentState();
}

class _QrScannerComponentState extends State<QrScannerComponent> {
  final MobileScannerController controller = MobileScannerController(
    formats: [BarcodeFormat.all],
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  bool isProcessing = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear Qr')),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            fit: BoxFit.cover,
            onDetect: (capture) async {
              if (isProcessing) return;
              final barcode = capture.barcodes.first;
              final String code = barcode.rawValue ?? 'Unknown';

              isProcessing = true;

              if (code != 'Unknown') {
                print('Código detectado: $code');
                if (!context.mounted) return;
                Navigator.pop(context, code);
              }
            },
          ),

          // Cuadro en el centro
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          // Sombra exterior para destacar el área central
          IgnorePointer(
            child: Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Container(
                  width: 250,
                  height: 250,
                  color: Colors.transparent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
