import 'package:flutter/material.dart';

import 'config/theme.dart';
import 'config/routes.dart';
import 'core/errors/error_handler.dart';

class KopDarApp extends StatelessWidget {
  const KopDarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GlobalErrorHandler(
      child: MaterialApp.router(
        title: 'KopDar',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
