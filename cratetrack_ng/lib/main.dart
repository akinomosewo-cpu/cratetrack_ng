import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/auth/auth_repository.dart';
import 'core/theme/app_theme.dart';
import 'data/crate_repository.dart';
import 'presentation/pages/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = CrateRepository();
  await repository.init();
  final authRepository = AuthRepository();
  await authRepository.init();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: AppColors.background,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  runApp(CrateTrackApp(repository: repository, authRepository: authRepository));
}

class CrateTrackApp extends StatelessWidget {
  final CrateRepository repository;
  final AuthRepository authRepository;
  const CrateTrackApp({super.key, required this.repository, required this.authRepository});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CrateTrack NG',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      home: SplashPage(authRepository: authRepository, crateRepository: repository),
    );
  }
}
