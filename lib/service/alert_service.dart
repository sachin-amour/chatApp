import 'package:amour_chat/service/navigation_service.dart';
import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class AlertService {
  final GetIt _getIt = GetIt.instance;
  late NavigattionService _navigationService;

  AlertService() {
    _navigationService= _getIt.get<NavigattionService>();
  }
  void showToast({
    required String message,
    IconData icon = Icons.info,
    Color backgroundColor = Colors.grey,
    Color textColor = Colors.white,
  }) {
    try {
      DelightToastBar(
        autoDismiss: true,
        position: DelightSnackbarPosition.top,
        builder: (context) {
          return ToastCard(
            leading: Icon(icon, size: 28,),
            title: Text(
              message,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          );
        },
      ).show(_navigationService.navigatorKey!.currentContext!);
    } catch (e) {
      print(e);
    }
  }
}
