import 'package:app_ui/app_ui.dart';
import 'package:campusconnect/auth/signup/cubit/sign_up_cubit.dart';
import 'package:campusconnect/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/shared.dart';

class FullNameFormField extends StatefulWidget {
  const FullNameFormField({super.key});

  @override
  State<FullNameFormField> createState() => _EmailFormFieldState();
}

class _EmailFormFieldState extends State<FullNameFormField> {
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
      context.read<SignUpCubit>().onFullNameUnfocused();
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
    final fullNameError = context.select((SignUpCubit cubit) => cubit.state.fullName.errorMessage);
    
    return AppTextField(
      filled: true,
      errorText: fullNameError,
      focusNode: _focusNode,
      hintText: context.l10n.nameText,
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.words,
      enabled: !isLoading,
      autofillHints: const [AutofillHints.givenName],
      onChanged: (value) => _debouncer.run(() {
        context.read<SignUpCubit>().onFullNameChanged(value);
      }),
    );
  }
}
