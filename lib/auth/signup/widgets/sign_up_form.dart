import 'package:app_ui/app_ui.dart';
import 'package:campusconnect/app/app.dart';
import 'package:campusconnect/auth/signup/sign_up.dart';
import 'package:campusconnect/auth/signup/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SignUpForm extends StatelessWidget {
  const SignUpForm({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<SignUpCubit, SignUpState>(
      listener: (context, state) {
        if (state.submissionStatus.isError) {
          openSnackBar(
            SnackbarMessage.error(
              title:
                  signupSubmissionStatusMessage[state.submissionStatus]!.title,
              description: signupSubmissionStatusMessage[state.submissionStatus]
                  ?.description,
            ),
            clearIfQueue: true,
          );
        }
      },
      listenWhen: (previous, current) =>
          previous.submissionStatus != current.submissionStatus,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          //Email
          EmailFormField(),
          SizedBox(
            height: AppSpacing.md,
          ),
          FullNameFormField(),
          SizedBox(
            height: AppSpacing.md,
          ),
          UserNameFormField(),
          SizedBox(
            height: AppSpacing.md,
          ),
          PasswordFormField(),
        ],
      ),
    );
  }
}