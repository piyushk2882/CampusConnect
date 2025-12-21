import 'package:app_ui/app_ui.dart';
import 'package:campusconnect/auth/forgot_password/change_password/cubit/change_password_cubit.dart';
import 'package:campusconnect/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/shared.dart';

class ChangePasswordOtpFormField extends StatefulWidget {
  const ChangePasswordOtpFormField({super.key});

  @override
  State<ChangePasswordOtpFormField> createState() => _ChangePasswordFieldState();
}

class _ChangePasswordFieldState extends State<ChangePasswordOtpFormField> {
  late Debouncer _debouncer;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _debouncer = Debouncer();
    final cubit = context.read<ChangePasswordCubit>()..resetState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        cubit.onOtpUnfocused();
      }
    });
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final otpError = context.select(
      (ChangePasswordCubit cubit) => cubit.state.otp.errorMessage,
    );
    final isLoading = context.select(
      (ChangePasswordCubit cubit) => cubit.state.status.isLoading,
    );

    return AppTextField(
      filled: true,
      focusNode: _focusNode,
      hintText: context.l10n.otpText,
      enabled: !isLoading,
      textInputAction: TextInputAction.next,
      textInputType: TextInputType.number,
      autofillHints: const [AutofillHints.oneTimeCode],
      onChanged: (v) => _debouncer.run(
        () => context.read<ChangePasswordCubit>().onOtpChanged(v),
      ),
      errorText: otpError,
    );
  }
}
