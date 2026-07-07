import 'package:get/get.dart';
import '../modules/dashboard/dashboard_binding.dart';
import '../modules/dashboard/dashboard_screen.dart';
import 'app_routes.dart';

/// Central registry of all application routes.
abstract class AppPages {
  static const String initial = AppRoutes.dashboard;

  static final List<GetPage> routes = [
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardScreen(),
      binding: DashboardBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    // Future pages go here:
    // GetPage(
    //   name: AppRoutes.teamDetail,
    //   page: () => const TeamDetailScreen(),
    //   binding: TeamDetailBinding(),
    // ),
  ];
}
