import 'package:app_ui/app_ui.dart';
import 'package:campusconnect/app/app.dart';
import 'package:campusconnect/auth/auth.dart';
import 'package:campusconnect/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginForm extends StatelessWidget {
  const LoginForm({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginCubit, LoginState>(
      listener: (context, state) {
        if (state.status.isError) {
          openSnackBar(
            SnackbarMessage.error(
              title:
                  loginSubmissionStatusMessage[state.status]!.title ??
                  state.message ??
                  context.l10n.somethingWentWrongText,
              description:
                  loginSubmissionStatusMessage[state.status]?.description,
            ),
            clearIfQueue: true,
          );
        }
      },
      listenWhen: (previous, current) => previous.status != current.status,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EmailFormField(),
          SizedBox(height: AppSpacing.lg),
          PasswordFormField(),
          // Add other form fields like password, login button, etc. here
        ],
      ),
    );
  }
}
