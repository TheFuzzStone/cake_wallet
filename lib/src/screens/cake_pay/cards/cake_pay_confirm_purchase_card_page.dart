import 'package:cake_wallet/cake_pay/cake_pay_card.dart';
import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/cake_pay/widgets/cake_pay_alert_modal.dart';
import 'package:cake_wallet/src/screens/cake_pay/widgets/image_placeholder.dart';
import 'package:cake_wallet/src/screens/cake_pay/widgets/link_extractor.dart';
import 'package:cake_wallet/src/screens/cake_pay/widgets/text_icon_button.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/src/widgets/base_alert_dialog.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/confirm_sending_bottom_sheet_widget.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/info_bottom_sheet_widget.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/src/widgets/standard_checkbox.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/cake_pay/cake_pay_purchase_view_model.dart';
import 'package:cake_wallet/view_model/send/send_view_model_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:url_launcher/url_launcher.dart';

class CakePayBuyCardDetailPage extends BasePage {
  CakePayBuyCardDetailPage(this.cakePayPurchaseViewModel);

  final CakePayPurchaseViewModel cakePayPurchaseViewModel;

  @override
  String get title => cakePayPurchaseViewModel.card.name;

  @override
  Widget? middle(BuildContext context) {
    return Text(
      title,
      textAlign: TextAlign.center,
      maxLines: 2,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
    );
  }

  @override
  Widget? trailing(BuildContext context) => null;

  bool _effectsInstalled = false;

  @override
  Widget body(BuildContext context) {
    _setEffects(context);

    final card = cakePayPurchaseViewModel.card;

    return ScrollableWithBottomSection(
      contentPadding: EdgeInsets.zero,
      content: Observer(builder: (_) {
        return Column(
          children: [
            SizedBox(height: 36),
            ClipRRect(
              borderRadius:
                  BorderRadius.horizontal(left: Radius.circular(20), right: Radius.circular(20)),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.20),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                          child: ClipRRect(
                        borderRadius: BorderRadius.horizontal(
                            left: Radius.circular(20), right: Radius.circular(20)),
                        child: Image.network(
                          card.cardImageUrl ?? '',
                          fit: BoxFit.cover,
                          loadingBuilder: (BuildContext context, Widget child,
                              ImageChunkEvent? loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(child: CircularProgressIndicator());
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              CakePayCardImagePlaceholder(),
                        ),
                      )),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Column(children: [
                          Row(
                            children: [
                              Text(
                                S.of(context).value + ':',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                '${cakePayPurchaseViewModel.amount.toStringAsFixed(2)} ${cakePayPurchaseViewModel.fiatCurrency}',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Row(
                            children: [
                              Text(
                                S.of(context).quantity + ':',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                '${cakePayPurchaseViewModel.quantity}',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Row(
                            children: [
                              Text(
                                S.of(context).total + ':',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                '${cakePayPurchaseViewModel.totalAmount.toStringAsFixed(2)} ${cakePayPurchaseViewModel.fiatCurrency}',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                              ),
                            ],
                          ),
                        ]),
                      ),
                    )
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: TextIconButton(
                label: S.of(context).how_to_use_card,
                onTap: () => _showHowToUseCard(context, card),
              ),
            ),
            SizedBox(height: 20),
            if (card.expiryAndValidity != null && card.expiryAndValidity!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(S.of(context).expiry_and_validity + ':',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            )),
                    SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.20),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          card.expiryAndValidity ?? '',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      }),
      bottomSection: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Observer(builder: (_) {
              return LoadingPrimaryButton(
                isDisabled: cakePayPurchaseViewModel.isPurchasing,
                isLoading: cakePayPurchaseViewModel.isPurchasing ||
                    cakePayPurchaseViewModel.sendViewModel.state is IsExecutingState,
                onPressed: () => confirmPurchaseFirst(context),
                text: S.of(context).purchase_gift_card,
                color: Theme.of(context).colorScheme.primary,
                textColor: Theme.of(context).colorScheme.onPrimary,
              );
            }),
          ),
          SizedBox(height: 8),
          InkWell(
            onTap: () => _showTermsAndCondition(context, card.termsAndConditions),
            child: Text(
              S.of(context).settings_terms_and_conditions,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          SizedBox(height: 16)
        ],
      ),
    );
  }

  void _showTermsAndCondition(BuildContext context, String? termsAndConditions) {
    showPopUp<void>(
        context: context,
        builder: (BuildContext context) {
          return CakePayAlertModal(
            title: S.of(context).settings_terms_and_conditions,
            content: Align(
              alignment: Alignment.bottomLeft,
              child: ClickableLinksText(
                text: termsAndConditions ?? '',
                textStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 18,
                        ) ??
                    Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 18,
                        ),
              ),
            ),
            actionTitle: S.of(context).agree,
            showCloseButton: false,
            heightFactor: 0.6,
          );
        });
  }

  Future<void> _showconfirmPurchaseFirstAlert(BuildContext context) async {
    if (!cakePayPurchaseViewModel.confirmsNoVpn ||
        !cakePayPurchaseViewModel.confirmsVoidedRefund ||
        !cakePayPurchaseViewModel.confirmsTermsAgreed) {
      await showPopUp<void>(
        context: context,
        builder: (BuildContext context) => ThreeCheckboxAlert(
          alertTitle: S.of(context).cakepay_confirm_purchase,
          leftButtonText: S.of(context).cancel,
          rightButtonText: S.of(context).confirm,
          actionLeftButton: () {
            cakePayPurchaseViewModel.isPurchasing = false;
            Navigator.of(context).pop();
          },
          actionRightButton: (confirmsNoVpn, confirmsVoidedRefund, confirmsTermsAgreed) {
            cakePayPurchaseViewModel.confirmsNoVpn = confirmsNoVpn;
            cakePayPurchaseViewModel.confirmsVoidedRefund = confirmsVoidedRefund;
            cakePayPurchaseViewModel.confirmsTermsAgreed = confirmsTermsAgreed;

            Navigator.of(context).pop();
          },
        ),
      );
    }

    if (cakePayPurchaseViewModel.confirmsNoVpn &&
        cakePayPurchaseViewModel.confirmsVoidedRefund &&
        cakePayPurchaseViewModel.confirmsTermsAgreed) {
      await purchaseCard(context);
    }
  }

  Future<void> confirmPurchaseFirst(BuildContext context) async {
    bool isLogged = await cakePayPurchaseViewModel.cakePayService.isLogged();
    if (!isLogged) {
      Navigator.of(context).pushNamed(Routes.cakePayWelcomePage);
    } else {
      cakePayPurchaseViewModel.isPurchasing = true;
      await _showconfirmPurchaseFirstAlert(context);
    }
  }

  Future<void> purchaseCard(BuildContext context) async {
    bool isLogged = await cakePayPurchaseViewModel.cakePayService.isLogged();
    if (!isLogged) {
      Navigator.of(context).pushNamed(Routes.cakePayWelcomePage);
    } else {
      try {
        await cakePayPurchaseViewModel.createOrder();
      } catch (_) {
        await cakePayPurchaseViewModel.cakePayService.logout();
      }
    }
    cakePayPurchaseViewModel.isPurchasing = false;
  }

  void _showHowToUseCard(
    BuildContext context,
    CakePayCard card,
  ) {
    showPopUp<void>(
        context: context,
        builder: (BuildContext context) {
          return CakePayAlertModal(
            title: S.of(context).how_to_use_card,
            content: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                  padding: EdgeInsets.all(10),
                  child: Text(
                    card.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                  )),
              ClickableLinksText(
                text: card.howToUse ?? '',
                textStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ) ??
                    Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                linkStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontStyle: FontStyle.italic,
                        ) ??
                    Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontStyle: FontStyle.italic,
                        ),
              ),
            ]),
            actionTitle: S.current.got_it,
          );
        });
  }

  Future<void> _showConfirmSendingAlert(BuildContext context) async {
    if (cakePayPurchaseViewModel.order == null) {
      return;
    }
    ReactionDisposer? disposer;

    disposer = reaction((_) => cakePayPurchaseViewModel.isOrderExpired, (bool isExpired) {
      if (isExpired) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        if (disposer != null) {
          disposer();
        }
      }
    });

    final order = cakePayPurchaseViewModel.order;

    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      isScrollControlled: true,
      builder: (BuildContext popupContext) {
        return ConfirmSendingBottomSheet(
          key: ValueKey('send_page_confirm_sending_dialog_key'),
          currentTheme: currentTheme,
          walletType: cakePayPurchaseViewModel.sendViewModel.walletType,
          paymentId: S.of(popupContext).payment_id,
          paymentIdValue: order?.orderId,
          expirationTime: cakePayPurchaseViewModel.formattedRemainingTime,
          titleText: S.of(popupContext).confirm_transaction,
          titleIconPath: cakePayPurchaseViewModel.sendViewModel.selectedCryptoCurrency.iconPath,
          currency: cakePayPurchaseViewModel.sendViewModel.selectedCryptoCurrency,
          amount: S.of(popupContext).send_amount,
          amountValue: cakePayPurchaseViewModel.sendViewModel.pendingTransaction!.amountFormatted,
          fiatAmountValue:
              cakePayPurchaseViewModel.sendViewModel.pendingTransactionFiatAmountFormatted,
          fee: S.of(popupContext).send_fee,
          feeValue: cakePayPurchaseViewModel.sendViewModel.pendingTransaction!.feeFormatted,
          feeFiatAmount:
              cakePayPurchaseViewModel.sendViewModel.pendingTransactionFeeFiatAmountFormatted,
          outputs: cakePayPurchaseViewModel.sendViewModel.outputs,
          onSlideComplete: () async {
            Navigator.of(popupContext).pop();
            cakePayPurchaseViewModel.sendViewModel.commitTransaction(context);
          },
        );
      },
    );
  }

  BuildContext? loadingBottomSheetContext;

  void _setEffects(BuildContext context) {
    if (_effectsInstalled) {
      return;
    }

    reaction((_) => cakePayPurchaseViewModel.sendViewModel.state, (ExecutionState state) {
      if (state is FailureState) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) showStateAlert(context, S.of(context).error, state.error);
        });
      }

      if (state is! IsExecutingState &&
          loadingBottomSheetContext != null &&
          loadingBottomSheetContext!.mounted) {
        Navigator.of(loadingBottomSheetContext!).pop();
      }

      if (state is IsExecutingState) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            showModalBottomSheet<void>(
              context: context,
              isDismissible: false,
              builder: (BuildContext context) {
                loadingBottomSheetContext = context;
                return LoadingBottomSheet(
                  titleText: S.of(context).generating_transaction,
                );
              },
            );
          }
        });
      }

      if (state is ExecutedSuccessfullyState) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await _showConfirmSendingAlert(context);
        });
      }

      if (state is TransactionCommitted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          cakePayPurchaseViewModel.sendViewModel.clearOutputs();
          if (context.mounted) showSentAlert(context);
        });
      }
    });

    _effectsInstalled = true;
  }

  void showStateAlert(BuildContext context, String title, String content) {
    if (context.mounted) {
      showPopUp<void>(
          context: context,
          builder: (BuildContext context) {
            return AlertWithOneAction(
                alertTitle: title,
                alertContent: content,
                buttonText: S.of(context).ok,
                buttonAction: () => Navigator.of(context).pop());
          });
    }
  }

  Future<void> showSentAlert(BuildContext context) async {
    if (!context.mounted) {
      return;
    }
    final order = cakePayPurchaseViewModel.order!.orderId;
    final isCopy = await showPopUp<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertWithTwoActions(
                  alertTitle: S.of(context).transaction_sent,
                  alertContent: S.of(context).cake_pay_save_order + '\n${order}',
                  leftButtonText: S.of(context).ignor,
                  rightButtonText: S.of(context).copy,
                  actionLeftButton: () => Navigator.of(context).pop(false),
                  actionRightButton: () => Navigator.of(context).pop(true));
            }) ??
        false;

    if (isCopy) {
      await Clipboard.setData(ClipboardData(text: order));
    }
  }

  void _handleDispose(ReactionDisposer? disposer) {
    cakePayPurchaseViewModel.dispose();
    if (disposer != null) {
      disposer();
    }
  }
}

class ThreeCheckboxAlert extends BaseAlertDialog {
  ThreeCheckboxAlert({
    required this.alertTitle,
    required this.leftButtonText,
    required this.rightButtonText,
    required this.actionLeftButton,
    required this.actionRightButton,
    this.alertBarrierDismissible = true,
    Key? key,
  });

  final String alertTitle;
  final String leftButtonText;
  final String rightButtonText;
  final VoidCallback actionLeftButton;
  final Function(bool, bool, bool) actionRightButton;
  final bool alertBarrierDismissible;

  bool checkbox1 = false;
  void toggleCheckbox1() => checkbox1 = !checkbox1;
  bool checkbox2 = false;
  void toggleCheckbox2() => checkbox2 = !checkbox2;
  bool checkbox3 = false;
  void toggleCheckbox3() => checkbox3 = !checkbox3;

  bool showValidationMessage = true;

  @override
  String get titleText => alertTitle;
  @override
  bool get isDividerExists => true;

  @override
  String get leftActionButtonText => leftButtonText;
  @override
  String get rightActionButtonText => rightButtonText;
  @override
  VoidCallback get actionLeft => actionLeftButton;
  @override
  VoidCallback get actionRight => () {
        actionRightButton(checkbox1, checkbox2, checkbox3);
      };

  @override
  bool get barrierDismissible => alertBarrierDismissible;

  @override
  Widget content(BuildContext context) {
    return ThreeCheckboxAlertContent(
      checkbox1: checkbox1,
      toggleCheckbox1: toggleCheckbox1,
      checkbox2: checkbox2,
      toggleCheckbox2: toggleCheckbox2,
      checkbox3: checkbox3,
      toggleCheckbox3: toggleCheckbox3,
    );
  }
}

class ThreeCheckboxAlertContent extends StatefulWidget {
  ThreeCheckboxAlertContent({
    required this.checkbox1,
    required this.toggleCheckbox1,
    required this.checkbox2,
    required this.toggleCheckbox2,
    required this.checkbox3,
    required this.toggleCheckbox3,
    Key? key,
  }) : super(key: key);

  bool checkbox1;
  void Function() toggleCheckbox1;
  bool checkbox2;
  void Function() toggleCheckbox2;
  bool checkbox3;
  void Function() toggleCheckbox3;

  @override
  _ThreeCheckboxAlertContentState createState() => _ThreeCheckboxAlertContentState(
        checkbox1: checkbox1,
        toggleCheckbox1: toggleCheckbox1,
        checkbox2: checkbox2,
        toggleCheckbox2: toggleCheckbox2,
        checkbox3: checkbox3,
        toggleCheckbox3: toggleCheckbox3,
      );

  static _ThreeCheckboxAlertContentState? of(BuildContext context) {
    return context.findAncestorStateOfType<_ThreeCheckboxAlertContentState>();
  }
}

class _ThreeCheckboxAlertContentState extends State<ThreeCheckboxAlertContent> {
  _ThreeCheckboxAlertContentState({
    required this.checkbox1,
    required this.toggleCheckbox1,
    required this.checkbox2,
    required this.toggleCheckbox2,
    required this.checkbox3,
    required this.toggleCheckbox3,
  });

  bool checkbox1;
  void Function() toggleCheckbox1;
  bool checkbox2;
  void Function() toggleCheckbox2;
  bool checkbox3;
  void Function() toggleCheckbox3;

  bool showValidationMessage = true;

  bool get areAllCheckboxesChecked => checkbox1 && checkbox2 && checkbox3;

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StandardCheckbox(
            value: checkbox1,
            caption: S.of(context).cakepay_confirm_no_vpn,
            onChanged: (bool? value) {
              setState(() {
                checkbox1 = value ?? false;
                toggleCheckbox1();
                showValidationMessage = !areAllCheckboxesChecked;
              });
            },
          ),
          StandardCheckbox(
            value: checkbox2,
            caption: S.of(context).cakepay_confirm_voided_refund,
            onChanged: (bool? value) {
              setState(() {
                checkbox2 = value ?? false;
                toggleCheckbox2();
                showValidationMessage = !areAllCheckboxesChecked;
              });
            },
          ),
          StandardCheckbox(
            value: checkbox3,
            caption: S.of(context).cakepay_confirm_terms_agreed,
            onChanged: (bool? value) {
              setState(() {
                checkbox3 = value ?? false;
                toggleCheckbox3();
                showValidationMessage = !areAllCheckboxesChecked;
              });
            },
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => launchUrl(
              Uri.parse("https://www.cakepay.com/terms/"),
              mode: LaunchMode.externalApplication,
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                S.of(context).settings_terms_and_conditions,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.primary,
                      decoration: TextDecoration.none,
                      height: 1,
                    ),
                softWrap: true,
              ),
            ),
          ),
          if (showValidationMessage)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Please confirm all checkboxes',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.errorContainer,
                      decoration: TextDecoration.none,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}
