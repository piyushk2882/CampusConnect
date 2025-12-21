import 'package:get_it/get_it.dart';
import 'package:shared/src/config/app_flavor.dart';

final GetIt getIt = GetIt.instance;

void setupDi({required AppFlavor appFlavor}) {
  getIt.registerSingleton(appFlavor);

}


