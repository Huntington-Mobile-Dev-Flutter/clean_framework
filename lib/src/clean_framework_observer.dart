import 'dart:developer';

import 'package:clean_framework/src/providers/external_interface.dart';
import 'package:clean_framework/src/providers/gateway.dart';
import 'package:clean_framework/src/providers/use_case.dart';

/// The class to observe failures, route changes and other events.
class CleanFrameworkObserver {
  /// Default constructor.
  CleanFrameworkObserver({
    this.enableNetworkLogs = true,
  });

  /// Enables network logs.
  final bool enableNetworkLogs;

  /// Default instance of [CleanFrameworkObserver].
  ///
  /// This can be changed in following way:
  /// ```dart
  /// CleanFrameworkObserver.instance = SubClassOfCleanFrameworkObserver();
  /// ```
  static CleanFrameworkObserver instance = CleanFrameworkObserver();

  /// Called when an [error] is thrown by [ExternalInterface] for the given [request].
  void onExternalError(
    ExternalInterface externalInterface,
    Request request,
    Object error,
  ) {
    log(
      error.toString(),
      name: '${externalInterface.runtimeType}[${request.runtimeType}]',
    );
  }

  /// Called when a [failureResponse] occurs for the given [request].
  void onFailureResponse(
    ExternalInterface externalInterface,
    Request request,
    FailureResponse failureResponse,
  ) {}

  /// Called when a [failure] occurs in a gateway.
  void onFailureInput(FailureInput failure) {}

  /// Called when [location] of the route changes.
  void onLocationChanged(String location) {}
}
