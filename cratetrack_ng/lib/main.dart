import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'data/crate_repository.dart';
import 'presentation/blocs/crate_bloc.dart';
import 'presentation/pages/dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = CrateRepository();
  await repository.init();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.background,
  ));
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  runApp(CrateTrackApp(repository: repository));
}

class CrateTrackApp extends StatelessWidget {
  final CrateRepository repository;
  const CrateTrackApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CrateBloc(repository)..add(const CratesLoaded()),
      child: MaterialApp(
        title: 'CrateTrack NG',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: const DashboardPage(),
      ),
    );
  }
}
