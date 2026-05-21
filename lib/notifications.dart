import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:ipl_auction_game/parameters.dart';

void showSuccess(BuildContext ctx, String msg, {Duration duration = const Duration(seconds: 3)}) {
  Flushbar<void>(
    messageText: Text(msg, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
    duration: duration,
    margin: EdgeInsets.all(12),
    borderRadius: BorderRadius.circular(12),
    flushbarPosition: FlushbarPosition.TOP,
    backgroundColor: iconGreen,
    icon: Icon(Icons.check_circle, color: Colors.white),
    leftBarIndicatorColor: iconGold,
  ).show(ctx);
}

void showError(BuildContext ctx, String msg, {Duration duration = const Duration(seconds: 3)}) {
  Flushbar<void>(
    messageText: Text(msg, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
    duration: duration,
    margin: EdgeInsets.all(12),
    borderRadius: BorderRadius.circular(12),
    flushbarPosition: FlushbarPosition.TOP,
    backgroundColor: Colors.redAccent,
    icon: Icon(Icons.error_outline, color: Colors.white),
    leftBarIndicatorColor: iconGold,
  ).show(ctx);
}

void showInfo(BuildContext ctx, String msg, {Duration duration = const Duration(seconds: 3)}) {
  Flushbar<void>(
    messageText: Text(msg, style: TextStyle(color: Colors.white)),
    duration: duration,
    margin: EdgeInsets.all(12),
    borderRadius: BorderRadius.circular(12),
    flushbarPosition: FlushbarPosition.TOP,
    backgroundColor: iconPurple,
    icon: Icon(Icons.info_outline, color: Colors.white),
  ).show(ctx);
}
