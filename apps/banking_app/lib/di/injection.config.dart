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
import 'package:banking_app/app/config/app_config.dart' as _i110;
import 'package:banking_app/app/debug/debug_tools.dart' as _i461;
import 'package:banking_app/app/personalization/personalization_cubit.dart'
    as _i80;
import 'package:banking_app/app/push/push_coordinator.dart' as _i981;
import 'package:banking_app/app/session_effects.dart' as _i249;
import 'package:banking_app/di/app_module.dart' as _i1038;
import 'package:core/core.dart' as _i494;
import 'package:fx_rates/fx_rates.dart' as _i951;
import 'package:get_it/get_it.dart' as _i174;
import 'package:go_router/go_router.dart' as _i583;
import 'package:injectable/injectable.dart' as _i526;
import 'package:notifications/notifications.dart' as _i327;

const String _dev = 'dev';
const String _prod = 'prod';

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
    gh.lazySingleton<_i327.PushService>(() => appModule.pushService);
    gh.lazySingleton<_i327.PushTokenRegistry>(
      () => appModule.pushTokenRegistry,
    );
    gh.lazySingleton<_i662.OnboardingRepository>(
      () => appModule.onboardingRepository(gh<_i494.KeyValueStore>()),
    );
    gh.lazySingleton<_i494.ChaosController>(
      () => appModule.chaosController,
      registerFor: {_dev},
    );
    gh.lazySingleton<_i461.FirestoreNetworkSwitch>(
      () => appModule.firestoreNetworkSwitch,
      registerFor: {_dev},
    );
    gh.lazySingleton<_i461.DebugTools>(
      () => appModule.debugTools(
        gh<_i494.ChaosController>(),
        gh<_i461.FirestoreNetworkSwitch>(),
        gh<_i327.PushService>(),
      ),
      registerFor: {_dev},
    );
    gh.lazySingleton<_i951.FxRatesRepository>(
      () => appModule.devFxRatesRepository(
        gh<_i494.ChaosController>(),
        gh<_i494.KeyValueStore>(),
      ),
      registerFor: {_dev},
    );
    gh.lazySingleton<_i951.FxRatesRepository>(
      () => appModule.prodFxRatesRepository(gh<_i494.KeyValueStore>()),
      registerFor: {_prod},
    );
    gh.lazySingleton<_i662.SessionCubit>(
      () => appModule.sessionCubit(gh<_i662.AuthRepository>()),
    );
    gh.lazySingleton<_i80.PersonalizationCubit>(
      () => appModule.personalizationCubit(
        gh<_i110.AppConfig>(),
        gh<_i662.SessionCubit>(),
        gh<_i718.AccountsRepository>(),
      ),
    );
    gh.lazySingleton<_i249.SessionEffects>(
      () => appModule.sessionEffects(
        gh<_i662.SessionCubit>(),
        gh<_i718.AccountsRepository>(),
      ),
    );
    gh.lazySingleton<_i583.GoRouter>(
      () => appModule.prodRouter(
        gh<_i662.SessionCubit>(),
        gh<_i80.PersonalizationCubit>(),
        gh<_i662.OnboardingRepository>(),
        gh<_i662.AuthRepository>(),
        gh<_i718.AccountsRepository>(),
        gh<_i951.FxRatesRepository>(),
      ),
      registerFor: {_prod},
    );
    gh.lazySingleton<_i583.GoRouter>(
      () => appModule.devRouter(
        gh<_i662.SessionCubit>(),
        gh<_i80.PersonalizationCubit>(),
        gh<_i662.OnboardingRepository>(),
        gh<_i662.AuthRepository>(),
        gh<_i718.AccountsRepository>(),
        gh<_i951.FxRatesRepository>(),
        gh<_i461.DebugTools>(),
      ),
      registerFor: {_dev},
    );
    gh.lazySingleton<_i981.PushCoordinator>(
      () => appModule.pushCoordinator(
        gh<_i662.SessionCubit>(),
        gh<_i327.PushService>(),
        gh<_i327.PushTokenRegistry>(),
        gh<_i583.GoRouter>(),
      ),
    );
    return this;
  }
}

class _$AppModule extends _i1038.AppModule {}
