// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:accounts/accounts.dart' as _i718;
import 'package:auth/auth.dart' as _i662;
import 'package:banking_app/app/session_effects.dart' as _i249;
import 'package:banking_app/di/app_module.dart' as _i1038;
import 'package:core/core.dart' as _i494;
import 'package:get_it/get_it.dart' as _i174;
import 'package:go_router/go_router.dart' as _i583;
import 'package:injectable/injectable.dart' as _i526;

const String _dev = 'dev';

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final appModule = _$AppModule();
    gh.lazySingleton<_i662.AuthRepository>(() => appModule.authRepository);
    gh.lazySingleton<_i718.AccountsRepository>(
      () => appModule.accountsRepository,
    );
    gh.lazySingleton<_i662.OnboardingRepository>(
      () => appModule.onboardingRepository(gh<_i494.KeyValueStore>()),
    );
    gh.lazySingleton<_i494.ChaosController>(
      () => appModule.chaosController,
      registerFor: {_dev},
    );
    gh.lazySingleton<_i662.SessionCubit>(
      () => appModule.sessionCubit(gh<_i662.AuthRepository>()),
    );
    gh.lazySingleton<_i583.GoRouter>(
      () => appModule.router(
        gh<_i662.SessionCubit>(),
        gh<_i662.OnboardingRepository>(),
        gh<_i662.AuthRepository>(),
      ),
    );
    gh.lazySingleton<_i249.SessionEffects>(
      () => appModule.sessionEffects(
        gh<_i662.SessionCubit>(),
        gh<_i718.AccountsRepository>(),
      ),
    );
    return this;
  }
}

class _$AppModule extends _i1038.AppModule {}
