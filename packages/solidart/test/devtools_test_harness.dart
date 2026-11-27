import 'dart:async';
import 'dart:developer' as dev;

import 'package:solidart/solidart.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

void testWithDevTools(
  String description,
  FutureOr<void> Function(VmService) body,
) {
  test(description, () async {
    final info = await dev.Service.controlWebServer(
      enable: true,
      silenceOutput: true,
    );
    final uri = info.serverWebSocketUri;
    if (uri == null) {
      markTestSkipped('The VM service is unavailable.');
      return;
    }

    final service = await vmServiceConnectUri(uri.toString());
    addTearDown(service.dispose);
    await service.streamListen(EventStreams.kExtension);

    final wasEnabled = SolidartConfig.devToolsEnabled;
    SolidartConfig.devToolsEnabled = true;
    addTearDown(() => SolidartConfig.devToolsEnabled = wasEnabled);
    await body(service);
  }, testOn: 'vm');
}
