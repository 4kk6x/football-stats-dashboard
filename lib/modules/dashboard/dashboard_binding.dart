import 'package:get/get.dart';
import 'dashboard_controller.dart';

/// GetX Binding for the Dashboard module.
///
/// Lazily injects [FootballController] only when the Dashboard route
/// is first navigated to — no wasted memory on startup.
class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FootballController>(() => FootballController());
  }
}
