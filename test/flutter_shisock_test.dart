import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_shisock/flutter_shisock.dart';

void main() {
  ShiSockClient client = ShiSockClient();
  ShiSockListener shiSock = client.connect("127.0.0.1", 8080);
  shiSock.send("main", "Hello From Flutter");
  shiSock.listen("main", (data, sender) {
    print("data: $data");
  });
}
