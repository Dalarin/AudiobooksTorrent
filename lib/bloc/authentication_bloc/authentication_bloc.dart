import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:proxies/proxies.dart';
import '../../rutracker/models/proxy.dart' as m;

import '../../providers/storage_manager.dart';
import '../../rutracker/page-provider.dart';
import '../../rutracker/rutracker.dart';

part 'authentication_event.dart';

part 'authentication_state.dart';

class AuthenticationBloc extends Bloc<AuthenticationEvent, AuthenticationState> {
  late final RutrackerApi rutrackerApi;

  AuthenticationBloc() : super(AuthenticationInitial()) {
    on<ApplicationStarted>((event, emit) => _applicationStarted(event, emit));
    on<Authentication>((event, emit) => _authentication(event, emit));
  }

  void _applicationStarted(
    ApplicationStarted event,
    Emitter<AuthenticationState> emit,
  ) async {
    try {
      emit(AuthenticationLoading());
      _initDirectory("torrents");
      _initDirectory("books");
      m.Proxy? proxy = await StorageManager.readProxy();
      proxy ??= m.Proxy.standartProxy;
      String? cookies = await StorageManager.readData("cookies");
      SimpleProxyProvider proxyProvider = SimpleProxyProvider(
        proxy.host,
        proxy.port,
        proxy.username,
        proxy.password,
      );
      PageProvider pageProvider = await PageProvider.create(proxyProvider: proxyProvider);
      rutrackerApi = RutrackerApi(pageProvider: pageProvider);
      if (cookies != null) {
        print('cookies no tnull');
        bool loggedIn = await rutrackerApi.restoreCookies(cookies);
        if (loggedIn) {
          emit(AuthenticationSuccess());
        } else {
          emit(AuthenticationInitial());
        }
      } else {
        emit(AuthenticationInitial());
      }
    } on Exception catch (exception) {
      emit(AuthenticationError(message: exception.message));
    }
  }

  Future<void> _initDirectory(String subPath) async {
    Directory path = await getApplicationDocumentsDirectory();
    final Directory directory = Directory('${path.path}/$subPath/');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
  }

  _authentication(
    Authentication event,
    Emitter<AuthenticationState> emit,
  ) async {
    try {
      emit(AuthenticationLoading());
      if (event.password.isEmpty || event.username.isEmpty) {
        emit(const AuthenticationError(message: 'Заполните все поля и попробуйте снова'));
      } else {
        m.Proxy? proxy = await StorageManager.readProxy();
        proxy ??= m.Proxy.standartProxy;
        bool authenticated = await rutrackerApi.login(
          event.username,
          event.password,
        );
        if (authenticated == true) {
          emit(AuthenticationSuccess());
        } else {
          emit(const AuthenticationError(message: 'Неверный логин и/или пароль'));
        }
      }
    } on Exception catch (exception) {
      emit(AuthenticationError(message: exception.message));
    }
  }
}


extension ExceptionMessage on Exception {

  String get message {
    if (toString().contains("Exception:")) {
      return toString().substring(10);
    }
    return toString();
  }
}