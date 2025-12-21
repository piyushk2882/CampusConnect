import 'package:app_ui/app_ui.dart';
import 'package:campusconnect/auth/cubit/manage_password_cubit.dart';
import 'package:campusconnect/auth/forgot_password/change_password/widgets/widgets.dart';
import 'package:campusconnect/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChangePasswordView extends StatelessWidget {
  const ChangePasswordView({super.key});

  void _confirmGoBack(BuildContext context) => context.confirmAction(
    fn: () => context.read<ManagePasswordCubit>().changeScreen(
      showForgotPassword: true,
    ),
    title: context.l10n.goBackConfirmationText,
    content: context.l10n.loseAllEditsText,
    noText: context.l10n.cancelText,
    yesText: context.l10n.goBackText,
    yesTextStyle: context.labelLarge?.apply(color: AppColors.blue),
  );

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      onPopInvokedWithResult: (didPop, result) { // Add the 'result' parameter
        if (didPop) return;
        _confirmGoBack(context);
      },
      releaseFocus: true,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(context.l10n.changePasswordText),
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.adaptive.arrow_back),
          onPressed: () => _confirmGoBack(context),
        ),
      ),
      body: AppConstrainedScrollView(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.xlg),
        child: Column(
        children: const [
          Gap.v(AppSpacing.xxxlg * 3),
          Expanded(child: Column(
            children: [
                  ChangePasswordForm(),
                  Gap.v(AppSpacing.md),
                  ChangePasswordButton(),
            ],
          ))
        ],
      )),
    );
  }
}