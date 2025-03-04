import 'dart:developer';
import 'dart:io';

import 'package:at_wavi_app/common_components/loading_widget.dart';
import 'package:at_wavi_app/model/user.dart';
import 'package:at_wavi_app/routes/route_names.dart';
import 'package:at_wavi_app/routes/routes.dart';
import 'package:at_wavi_app/services/common_functions.dart';
import 'package:at_wavi_app/services/field_order_service.dart';
import 'package:at_wavi_app/services/search_service.dart';
import 'package:at_wavi_app/services/size_config.dart';
import 'package:at_wavi_app/utils/colors.dart';
import 'package:at_wavi_app/utils/text_styles.dart';
import 'package:at_wavi_app/view_models/user_preview.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class QRScanner extends StatefulWidget {
  const QRScanner({Key? key}) : super(key: key);

  @override
  State<QRScanner> createState() => _QRScannerState();
}

class _QRScannerState extends State<QRScanner> {
  //if flag is true the camera will scan for a qr code or else it wont
  bool flag = true;
  QRViewController? _controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;

  @override
  initState() {
    checkPermissions();
    super.initState();
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      _controller!.pauseCamera();
    } else if (Platform.isIOS) {
      _controller!.resumeCamera();
    }
  }

  Future<void> scanQR(Barcode? result) async {
    if (flag) {
      flag = false;
      bool _atSignValid = await CommonFunctions().checkAtsign(result?.code);
      if (_atSignValid) {
        _controller?.stopCamera();
        await onScan(result?.code, context);
      } else {
        await ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: ColorConstants.RED,
          content: Text(
            'QR code is invalid.',
            style: CustomTextStyles.customTextStyle(
              ColorConstants.white,
            ),
          ),
        ));
      }
      flag = true;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  checkPermissions() async {
    var cameraStatus = await Permission.camera.status;
    print("camera status => $cameraStatus");

    if (!cameraStatus.isGranted &&
        !cameraStatus.isPermanentlyDenied &&
        !cameraStatus.isLimited) {
      await askPermissions(Permission.camera);
    }
  }

  askPermissions(Permission type) async {
    if (type == Permission.camera) {
      var _res = await Permission.camera.request();

      if (_res == PermissionStatus.granted ||
          _res == PermissionStatus.limited) {
        setState(() {});
      }
    }
  }

  Future<void> onScan(String? searchedAtsign, context) async {
    if (searchedAtsign != null) {
      LoadingDialog().show(text: '$searchedAtsign', heading: 'Fetching');

      var _searchedAtsignData =
          SearchService().getAlreadySearchedAtsignDetails(searchedAtsign);
      late bool _isPresent;
      if (_searchedAtsignData != null) {
        _isPresent = true;
      } else {
        _isPresent = await CommonFunctions().checkAtsign(searchedAtsign);
      }
      if (_isPresent) {
        SearchInstance? _searchService =
            await SearchService().getAtsignDetails(searchedAtsign);
        User? _res = _searchService?.user;

        LoadingDialog().hide();

        /// in case the search is cancelled, dont do anything
        if (_searchService == null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: ColorConstants.RED,
            content: Text(
              'Something went wrong',
              style: CustomTextStyles.customTextStyle(
                ColorConstants.white,
              ),
            ),
          ));
          return;
        }

        Provider.of<UserPreview>(context, listen: false).setUser = _res;
        FieldOrderService().setPreviewOrder = _searchService.fieldOrders;

        await SetupRoutes.replace(context, Routes.HOME, arguments: {
          'key': Key(searchedAtsign),
          'themeData': _searchService.currentAtsignThemeData,
          'isPreview': true,
        });
      } else {
        LoadingDialog().hide();

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: ColorConstants.RED,
          content: Text(
            '$searchedAtsign not found',
            style: CustomTextStyles.customTextStyle(
              ColorConstants.white,
            ),
          ),
        ));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: ColorConstants.RED,
            content: Text(
              'No result was retrieved from the scanned code.',
              style: CustomTextStyles.customTextStyle(
                ColorConstants.white,
              ),
            ),
          ));
      log("No result was retrieved from the scanned code.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan a QR code'),
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          children: <Widget>[
            Expanded(
              flex: 5,
              child: QRView(
                key: qrKey,
                onQRViewCreated: _onQRViewCreated,
              ),
            ),
            Expanded(
              flex: 1,
              child: Center(
                child:
                    (result != null) ? Text('Scanned') : Text('Scan a QR code'),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this._controller = controller;
    this._controller?.scannedDataStream.listen(onScanned);
    this._controller?.pauseCamera();
    this._controller?.resumeCamera();
  }

  void onScanned(scanData) {
    setState(() {
      result = scanData;
      this._controller?.pauseCamera();
      scanQR(result);
    });
  }
}
