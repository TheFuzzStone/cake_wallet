import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/main.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/view_model/rescan_view_model.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/blockchain_height_widget.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cw_core/wallet_type.dart';

class RescanPage extends BasePage {
  RescanPage(this._rescanViewModel)
      : _blockchainHeightWidgetKey = GlobalKey<BlockchainHeightState>();

  @override
  String get title =>
      _rescanViewModel.isSilentPaymentsScan ? S.current.silent_payments_scanning : S.current.rescan;
  final GlobalKey<BlockchainHeightState> _blockchainHeightWidgetKey;
  final RescanViewModel _rescanViewModel;

  @override
  Widget body(BuildContext context) {
    Widget child;
    if (_rescanViewModel.wallet.type != WalletType.decred) {
      child = Padding(
        padding: EdgeInsets.only(left: 24, right: 24, bottom: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Observer(
              builder: (_) => BlockchainHeightWidget(
                key: _blockchainHeightWidgetKey,
                onHeightOrDateEntered: (value) => _rescanViewModel.isButtonEnabled = value,
                isSilentPaymentsScan: _rescanViewModel.isSilentPaymentsScan,
                isMwebScan: _rescanViewModel.isMwebScan,
                doSingleScan: _rescanViewModel.doSingleScan,
                hasDatePicker: !_rescanViewModel.isMwebScan, // disable date picker for mweb for now
                toggleSingleScan: () =>
                    _rescanViewModel.doSingleScan = !_rescanViewModel.doSingleScan,
                walletType: _rescanViewModel.wallet.type,
                bitcoinMempoolAPIEnabled: _rescanViewModel.isBitcoinMempoolAPIEnabled,
              ),
            ),
            Observer(
              builder: (_) => LoadingPrimaryButton(
                isLoading: _rescanViewModel.state == RescanWalletState.rescaning,
                text: S.of(context).rescan,
                onPressed: () async {
                  if (_rescanViewModel.isSilentPaymentsScan) {
                    return _toggleSilentPaymentsScanning(context);
                  }

                  _rescanViewModel.rescanCurrentWallet(
                      restoreHeight: _blockchainHeightWidgetKey.currentState!.height);

                  Navigator.of(context).pop();
                },
                color: Theme.of(context).colorScheme.primary,
                textColor: Theme.of(context).colorScheme.onPrimary,
                isDisabled: !_rescanViewModel.isButtonEnabled,
              ),
            )
          ],
        ),
      );
    } else {
      child = Center(
        child: Padding(
          padding: EdgeInsets.only(left: 24, right: 24, bottom: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Spacer(),
              Observer(
                builder: (_) => LoadingPrimaryButton(
                  isLoading: _rescanViewModel.state == RescanWalletState.rescaning,
                  text: S.of(context).rescan,
                  onPressed: () async {
                    await _rescanViewModel.rescanCurrentWallet(restoreHeight: 0);
                    Navigator.of(context).pop();
                  },
                  color: Theme.of(context).colorScheme.primary,
                  textColor: Theme.of(context).colorScheme.onPrimary,
                ),
              )
            ],
          ),
        ),
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: child,
    );
  }

  Future<void> _toggleSilentPaymentsScanning(BuildContext context) async {
    final height = _blockchainHeightWidgetKey.currentState!.height;

    Navigator.of(context).pop();

    final needsToSwitch =
        await bitcoin!.getNodeIsElectrsSPEnabled(_rescanViewModel.wallet) == false;

    if (needsToSwitch) {
      return showPopUp<void>(
        context: navigatorKey.currentState!.context,
        builder: (BuildContext _dialogContext) => AlertWithTwoActions(
          alertTitle: S.of(_dialogContext).change_current_node_title,
          alertContent: S.of(_dialogContext).confirm_silent_payments_switch_node,
          rightButtonText: S.of(_dialogContext).confirm,
          leftButtonText: S.of(_dialogContext).cancel,
          actionRightButton: () async {
            Navigator.of(_dialogContext).pop();

            _rescanViewModel.rescanCurrentWallet(restoreHeight: height);
          },
          actionLeftButton: () => Navigator.of(_dialogContext).pop(),
        ),
      );
    }

    _rescanViewModel.rescanCurrentWallet(restoreHeight: height);
  }
}
