import 'package:amour_chat/enums/enums.dart';
import 'package:flutter/cupertino.dart';

class baseViewModel extends ChangeNotifier{
  ViewState _state = ViewState.idle;
  ViewState get state=>_state;
  setstate(ViewState state){
    _state=state;
    notifyListeners();
  }
}