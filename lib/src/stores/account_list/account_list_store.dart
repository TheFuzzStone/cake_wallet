import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/src/domain/common/wallet.dart';
import 'package:cake_wallet/src/domain/monero/monero_wallet.dart';
import 'package:cake_wallet/src/domain/monero/account.dart';
import 'package:cake_wallet/src/domain/monero/account_list.dart';
import 'package:cake_wallet/src/domain/services/wallet_service.dart';

part 'account_list_store.g.dart';

class AccountListStore = AcountListStoreBase with _$AccountListStore;

abstract class AcountListStoreBase with Store {
  @observable
  List<Account> accounts;

  AccountList _accountList;
  StreamSubscription<Wallet> _onWalletChangeSubscription;
  // StreamSubscription<List<Account>> _onSubaddressesChangeSubscription;

  AcountListStoreBase({@required WalletService walletService}) {
    accounts = [];

    if (walletService.currentWallet != null) {
      _onWalletChanged(walletService.currentWallet);
    }

    _onWalletChangeSubscription =
        walletService.onWalletChange.listen(_onWalletChanged);
  }

  @override
  void dispose() {
    // if (_onSubaddressesChangeSubscription != null) {
    //   _onSubaddressesChangeSubscription.cancel();
    // }

    _onWalletChangeSubscription.cancel();
    super.dispose();
  }

  Future updateAccountList() async {
    await _accountList.refresh(accountIndex: 0);
    accounts = await _accountList.getAll();
  }

  Future addAccount({String label} ) async {
    await _accountList.addAccount(label: label);
    await updateAccountList();
  }

  Future _onWalletChanged(Wallet wallet) async {
    // if (_onSubaddressesChangeSubscription != null) {
    //   _onSubaddressesChangeSubscription.cancel();
    // }

    if (wallet is MoneroWallet) {
      _accountList = wallet.getAccountList();
      // _onSubaddressesChangeSubscription = _accountList.subaddresses
      //     .listen((subaddress) => subaddresses = subaddress);
      await updateAccountList();

      return;
    }

    print('Incorrect wallet type for this operation (AccountList)');
  }
}