import 'package:app_ui/app_ui.dart';
import 'package:campusconnect/auth/forgot_password/cubit/forgot_password_cubit.dart';
import 'package:campusconnect/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/shared.dart';

class ForgotPasswordEmailFormField extends StatefulWidget {
  const ForgotPasswordEmailFormField({super.key});

  @override
  State<ForgotPasswordEmailFormField> createState() => _EmailFormFieldState();
}

class _EmailFormFieldState extends State<ForgotPasswordEmailFormField> {
  late Debouncer _debouncer;
  late FocusNode _focusNode;
  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_focusListener);
    _debouncer = Debouncer();
  }

  void _focusListener() {
    if (!_focusNode.hasFocus) {
      context.read<ForgotPasswordCubit>().onEmailUnfocused();
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _focusNode..removeListener(_focusListener)..dispose();
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emailError = context.select((ForgotPasswordCubit cubit) => cubit.state.email.errorMessage);
    return AppTextField(
      filled: true,
      errorText: emailError,
      focusNode: _focusNode,
      hintText: context.l10n.emailText,
      textInputType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      onChanged: (value) => _debouncer.run(() {
        context.read<ForgotPasswordCubit>().onEmailChanged(value);
      }),
    );
  }
}
