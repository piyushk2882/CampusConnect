import 'package:app_ui/app_ui.dart';
import 'package:campusconnect/auth/signup/cubit/sign_up_cubit.dart';
import 'package:campusconnect/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/shared.dart';

class UserNameFormField extends StatefulWidget {
  const UserNameFormField({super.key});

  @override
  State<UserNameFormField> createState() => _EmailFormFieldState();
}

class _EmailFormFieldState extends State<UserNameFormField> {
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
      context.read<SignUpCubit>().onUsernameUnfocused();
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_focusListener)
      ..dispose();
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select((SignUpCubit cubit) => cubit.state.submissionStatus.isLoading);
    final usernameError = context.select((SignUpCubit cubit) => cubit.state.userName.errorMessage);
    
    return AppTextField(
      filled: true,
      errorText: usernameError,
      focusNode: _focusNode,
      hintText: context.l10n.usernameText,
      textInputAction: TextInputAction.next,
      errorMaxLines: 3,
      enabled: !isLoading,
      autofillHints: const [AutofillHints.name],
      onChanged: (value) => _debouncer.run(() {
        context.read<SignUpCubit>().onUsernameChanged(value);
      }),
    );
  }
}
