import 'package:app_ui/app_ui.dart';
import 'package:campusconnect/app/app.dart';
import 'package:campusconnect/auth/forgot_password/cubit/forgot_password_cubit.dart';
import 'package:campusconnect/auth/forgot_password/widgets/forgot_password_email_formfield.dart';
import 'package:campusconnect/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ForgotPasswordForm extends StatelessWidget {
  const ForgotPasswordForm({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ForgotPasswordCubit, ForgotPasswordState>(
      listener: (context, state) {
        if (state.status.isSuccess) {
          openSnackBar(
            SnackbarMessage.success(
              title: context.l10n.verificationTokenSentText(state.email.value),
            ),
          );
        }
        if (state.status.isError) {
          openSnackBar(
            SnackbarMessage.error(
              title: forgotPasswordStatusMessage[state.status]!.title,
              description:
                  forgotPasswordStatusMessage[state.status]?.description,
            ),
            clearIfQueue: true,
          );
        }
      },
      listenWhen: (previous, current) => previous.status != current.status,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          ForgotPasswordEmailFormField(),
        ],
      ),
    );
  }
}
