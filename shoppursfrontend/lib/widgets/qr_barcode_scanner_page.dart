import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class QrBarcodeScannerPage extends StatefulWidget {
  final void Function(String) onScanned;
  final String title;
  const QrBarcodeScannerPage({Key? key, required this.onScanned, this.title = 'Scan Barcode'}) : super(key: key);

  @override
  State<QrBarcodeScannerPage> createState() => _QrBarcodeScannerPageState();
}

class _QrBarcodeScannerPageState extends State<QrBarcodeScannerPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool isProcessing = false;

  @override
  void reassemble() {
    super.reassemble();
    if (controller != null) {
      controller!.pauseCamera();
      controller!.resumeCamera();
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          QRView(
            key: qrKey,
            onQRViewCreated: (ctrl) {
              controller = ctrl;
              controller!.scannedDataStream.listen((scanData) {
                if (!isProcessing && scanData.code != null && scanData.code!.isNotEmpty) {
                  setState(() {
                    isProcessing = true;
                  });
                  widget.onScanned(scanData.code!);
                  Navigator.of(context).pop();
                }
              });
            },
            overlay: QrScannerOverlayShape(
              borderColor: const Color(0xFF9B1B1B),
              borderRadius: 10,
              borderLength: 30,
              borderWidth: 4,
              cutOutSize: 250,
            ),
          ),
          if (isProcessing)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
        ],
      ),
    );
  }
} 