import 'package:flutter_bloc/flutter_bloc.dart';

class ManagePasswordCubit extends Cubit<bool> {
  ManagePasswordCubit() : super(true);

  void changeScreen({required bool showForgotPassword}) =>
      emit(showForgotPassword);
}
