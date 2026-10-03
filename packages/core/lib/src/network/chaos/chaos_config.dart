import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Failure modes injected by the ChaosInterceptor. Only used in dev builds.
@immutable
class ChaosConfig extends Equatable {
  const ChaosConfig({
    this.enabled = false,
    this.latency = Duration.zero,
    this.failureRate = 0,
    this.offline = false,
  }) : assert(
         failureRate >= 0 && failureRate <= 1,
         'failureRate is a probability between 0 and 1',
       );

  /// Master switch: when false, requests pass through untouched.
  final bool enabled;

  /// Extra delay added to every request.
  final Duration latency;

  /// Probability (0..1) of answering with an injected HTTP 503.
  final double failureRate;

  /// Simulates no connectivity: every request fails as a connection error.
  final bool offline;

  ChaosConfig copyWith({
    bool? enabled,
    Duration? latency,
    double? failureRate,
    bool? offline,
  }) {
    return ChaosConfig(
      enabled: enabled ?? this.enabled,
      latency: latency ?? this.latency,
      failureRate: failureRate ?? this.failureRate,
      offline: offline ?? this.offline,
    );
  }

  @override
  List<Object?> get props => [enabled, latency, failureRate, offline];
}

/// Holds the live [ChaosConfig]. The debug panel writes to it and the
/// ChaosInterceptor reads it on every request, so changes apply at runtime.
class ChaosController extends ValueNotifier<ChaosConfig> {
  ChaosController([super.value = const ChaosConfig()]);
}
