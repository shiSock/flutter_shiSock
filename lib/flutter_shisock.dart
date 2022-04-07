/// A library which is used to create and maintain connection between the shiSock Engine.
/// It is used to send and receive data from the shiSock Engine. It is basically a utility
/// library for the shiSock Engine. It can be used to flutter to create chat applications
/// very easily.
/// [ Wriiten By: Shikhar Yadav | Github username: ShikharY10 ]
/// For more information visite the official shiSock github repo, name the of the repo is shiSock.
library flutter_shisock;

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:crypton/crypton.dart';

/// This class contains the function which is used to cryptography
/// purposes.
class _InternalAuthClass {
  Uint8List RB = Uint8List.fromList("sdf".codeUnits);

  /// Converts the rsa public key to formatted pem formate.
  /// Takes [RSAKeypair] as the only argument and it is compulsory.
  String pubtopem(RSAKeypair rsaKeypair) {
    String pem = base64.encode(rsaKeypair.publicKey.toFormattedPEM().codeUnits);
    return pem;
  }

  /// Create a signature using the ```Uint8List``` bytes and ```RSAKeypair```.
  /// Return a map of type ```Map<String, dynamic>```
  /// which contains the hash digest which is used to create the signature
  /// and the signature itself. The hash digest will be of type ```List<int>```
  /// and the signature will of type ```Uint8List```
  Future<Map<String, dynamic>> signature(RSAKeypair rsaKeypair,
      [Uint8List? ranb]) async {
    Uint8List _rb;
    if (ranb != null) {
      _rb = ranb;
    } else {
      _rb = _getRandUint8List(16);
    }
    final algorithm = Sha256();
    final hash = await algorithm.hash(_rb);
    Uint8List signature = rsaKeypair.privateKey.createSHA256Signature(_rb);

    Map<String, dynamic> ret = {};
    ret["signature"] = signature;
    ret["hash"] = hash.bytes;
    return ret;
  }

  /// Encrypt the data that is provided using ```RSA Algorithm``` using
  /// the public key from the ```RSAKeypair```. Returns ciphertext of type
  /// ```String```.
  String rsaEncrypt(RSAKeypair keyPair, String data) {
    String cipherText = keyPair.publicKey.encrypt(data);
    return cipherText;
  }

  /// Decrypt the data that is provided using ```RSA Algorithm``` using
  /// the private key from the ```RSAKeypair```. Returns plaintext of type
  /// ```Uint8List```.
  Uint8List rsaDecrypt(RSAKeypair keyPair, Uint8List cipherText) {
    Uint8List plainText = keyPair.privateKey.decryptData(cipherText);
    return plainText;
  }

  /// Encrypt the data using the ```AES Algorithm``` with ```GCM``` and ```256 bites```
  /// cipher. Takes data of type ```List<int>``` and the secretBox of type ```SecretBox```
  /// as the only arguments. Returns the cipherText of type ```Uint8List```. The ciphertext
  /// contains ```nonce``` from ```0-11 bits``` and last the ```16 bits``` of ciphertext
  ///  contains the ```mac```, the middle of both nonce and mac is the actual the ciphertext.
  Future<Uint8List> aesEncrypt(List<int> data, SecretKey secretKey) async {
    final algorithm = AesGcm.with256bits();

    final secretBox = await algorithm.encrypt(
      data,
      secretKey: secretKey,
      nonce: _getRandUint8List(12),
    );
    return secretBox.concatenation();
  }

  /// Decrypt the data using the ```AES Algorithm``` with ```GCM``` and ```256 bites``` cipher.
  /// Takes ciphertext of type ```Uint8List``` and the secretBox of type ```SecretBox``` as
  /// the arguments. Returns the plaintext of type ```List<int>```.
  Future<List<int>> aesDecrypt(
      Uint8List cipherText, SecretKey secretKey) async {
    final algorithm = AesGcm.with256bits();
    SecretBox secretBox =
        SecretBox.fromConcatenation(cipherText, nonceLength: 12, macLength: 16);

    final plainText = await algorithm.decrypt(secretBox, secretKey: secretKey);

    return plainText;
  }
}

/// Generate the random ```Uint8List``` of length which is provided as argument.
Uint8List _getRandUint8List(int len) {
  var random = Random.secure();
  var values = List<int>.generate(len, (i) => random.nextInt(255));
  return Uint8List.fromList(values);
}

class ShiSockListener {
  /// For storing the specific detail about the client. It will store information like _id, _aeskey, etc.
  final Map<String, dynamic> _naniDict = {};

  /// Used with ```_naniDict``` to store the client's _id.  It is of type ```String```.
  final String _id = "id";

  /// Used with ```_naniDict``` to store the client's _aeskey.  It is of type ```SecretKey```.
  final String _aeskey = "aeskey";

  /// Used with ```_naniDict``` to store the client's _rsakey.  It is of type ```RSAKeypair```.'
  final String _rsaKeyPair = "rsakeypair";

  /// Used with ```_naniDict``` to store the client's socket object.  It is of type ```Socket```.'
  final String _socket = "sock";

  /// Used with ```_naniDict``` to store the client's authentication status. It is of type ```bool```.
  final String _isAuth = "isAuthenticated";

  /// A ```_InternalAuthClass``` class object used for cryptography purposes.
  final _InternalAuthClass _shivani = _InternalAuthClass();

  /// ```_listenerFuncs``` is a list which is used to store the callback function of
  ///  ```Listen function```. It store the function with channel on which we are listening.
  final List<Map<String, dynamic>> _listenerFuncs = [];

  /// Used to store the channel the registered and on which client will listen for data.
  final List<String> _channel = ["main", "INTERNAL"];

  ///
  // final Map<String, List<Map<String, String>>> _listenerData = {};

  /// Used to store the authentication status of client.
  bool _isAuthenticated = false;

  /// Used to temporarily store the data and function before the authentication of client.
  final List<dynamic> _funcStkBefAuth = [];

  /// Constructor of the class, it equally calling the function which in turn call another
  /// function that will create and maintain the connection with the server.
  ShiSockListener(String address, int port) {
    _connect(address, port);
  }

  /// This function create new channels on which client and server can communicate.
  ///
  /// There are one default channel which is created by shiSock inself can be
  /// used for all kind of communications.
  /// [channels] should be of type "list of string", meaning we can create multiple
  /// channels just with one call to [createChannel] function.
  ///
  /// Example:
  /// ```
  /// createChannel(channels: ["one", "two", "three"])
  /// ```
  void createChannel({required List<String> channels}) {
    if (_channel.length > 2) {
      print("createChannel is already being called once");
    } else {
      _channel.addAll(channels);
    }
  }

  /// The Actual the function which responsible for connecting with the server.
  void _connect(String address, int port) async {
    Future<Socket> socket = Socket.connect(address, port);
    socket.then((sock) {
      _handler(sock);
    });
  }

  /// It is a internal function used the glabl send function to send the dat to the server.
  /// It takes ```data``` of type ```String``` and ```sock``` of type ```Socket```.
  /// It returns a integer which indicates how much bits have been written to the server.
  Future<int> _sender(String data, Socket sock) async {
    if (data.length < 1024) {
      sock.add(data.codeUnits);
      await sock.flush();
      return data.length;
    }
    int len_data = data.length;
    int send_len = 1024 - "$len_data~~".length;
    String pre = "$len_data~~${data.substring(0, send_len)}";
    sock.add(pre.codeUnits);
    await sock.flush();
    int n = pre.length;
    len_data = len_data - send_len;

    while (len_data > 0) {
      String preB;
      if (len_data >= 1024) {
        preB = data.substring(send_len, send_len + 1024);
      } else {
        preB = data.substring(send_len, send_len + len_data);
      }
      sock.add(preB.codeUnits);
      await sock.flush();
      n = preB.length;
      send_len += n;
      len_data -= n;
    }
    return send_len;
  }

  /// This function is used to prepare the data in correct format before passing it to the
  /// internal ```_sender``` function. It takes two arguments: ```data``` of type ```String``` and ```channel```
  /// of type ```string```
  Future<String> _prepare_data(String data, String channel) async {
    DateTime now = DateTime.now();
    Map<String, String> d = {
      "tp": "E-DSP",
      "nm": _naniDict[_id],
      "dttm": now.toString(),
      "dt": data,
      "chnl": channel,
    };
    String jsonData = jsonEncode(d);

    Uint8List secretBoxJson =
        await _shivani.aesEncrypt(jsonData.codeUnits, _naniDict[_aeskey]);

    Map<String, String> mainThree = {
      "tp": "auth-E-DSP",
      "md": "~~",
      "cj": base64.encode(secretBoxJson)
    };

    String mainThreeJson = jsonEncode(mainThree);
    String res = base64.encode(mainThreeJson.codeUnits);
    return "$res.${res.length}.~|||~";
  }

  /// This is the main the function which listen for that data from server.
  /// Once the data is handled by this function it be stored in the _listenerFuncs list with
  /// the correct channel. It lots of important things like authentiating the client by the
  /// server, once the server is authenticated the _handler function allow his all the features
  /// to be used. Once the client is authenticated, the authenticating block will handled the restriction
  /// that it will not get axecuted the whole life cycle of the client.
  /// It take only one argument ```sock``` of type ```Socket```. It kept alive through the
  /// program/client life cycle.
  void _handler(Socket sock) async {
    // preparing the initial proporsal for getting authenticated by server...

    _naniDict[_rsaKeyPair] = RSAKeypair.fromRandom();
    _naniDict[_aeskey] = SecretKey(_getRandUint8List(32));
    _naniDict[_isAuth] = false;

    bool isAuthenticated = false;

    Uint8List confirmationS3 = _getRandUint8List(20);

    Map<String, dynamic> signData =
        await _shivani.signature(_naniDict[_rsaKeyPair]);
    Uint8List signature = signData["signature"];
    List<int> hashD = signData["hash"];

    Map<String, dynamic> data = {
      "spubk": _shivani.pubtopem(_naniDict[_rsaKeyPair]),
      "sn": signature,
      "hs": hashD,
    };
    String jsonData = jsonEncode(data);
    String base64Data = base64.encode(jsonData.codeUnits);

    Map<String, String> parent = {
      "tp": "auth-step-1",
      "md": "~~",
      "cj": base64Data,
    };

    String mainJson = jsonEncode(parent);
    String mainJsonbase64 = base64.encode(mainJson.codeUnits);
    await _sender(mainJsonbase64, sock);

    sock.listen((List<int> event) async {
      Iterable<int> e = event.getRange(0, event.length - 1);
      String response = utf8.decode(e.toList());
      Uint8List mainJson = base64.decode(response);
      Map<String, dynamic> main = jsonDecode(String.fromCharCodes(mainJson));

      if (!isAuthenticated) {
        if (main["tp"] == "auth-step-2" && main["md"] == "~~") {
          Uint8List childJsonCipher = base64.decode(main["cj"] ?? "null");
          Uint8List childJson =
              _shivani.rsaDecrypt(_naniDict[_rsaKeyPair], childJsonCipher);
          dynamic childTwo = jsonDecode(String.fromCharCodes(childJson));
          String aes = childTwo["aesk"];
          Uint8List conf = base64.decode(childTwo["cm"]);

          _naniDict[_aeskey] = SecretKey(base64.decode(aes));
          _naniDict[_id] = childTwo["id"];

          // final algorithm = Sha256();
          // final hash = await algorithm.hash(conf);
          Map<String, dynamic> signData = await _shivani.signature(
              _naniDict[_rsaKeyPair], Uint8List.fromList(conf));

          Map<String, dynamic> childThree = {
            "cm": confirmationS3,
            "hs": signData["hash"],
            "sn": signData["signature"]
          };

          String childThreeJson = jsonEncode(childThree);

          Uint8List child3Jsonbase64 = await _shivani.aesEncrypt(
              childThreeJson.codeUnits, _naniDict[_aeskey]);

          Map<String, String> mainThree = {
            "tp": "auth-step-3",
            "md": "~~",
            "cj": base64.encode(child3Jsonbase64)
          };

          String mainThreeJson = jsonEncode(mainThree);
          String main3JsonBase64 = base64.encode(mainThreeJson.codeUnits);
          int n = await _sender(main3JsonBase64, sock);
        } else if (main["tp"] == "auth-step-4" && main["md"] == "~~") {
          Uint8List childJsonCipher = base64.decode(main["cj"] ?? "null");

          List<int> childFourJson =
              await _shivani.aesDecrypt(childJsonCipher, _naniDict[_aeskey]);

          Map<String, dynamic> childFour =
              jsonDecode(String.fromCharCodes(childFourJson));

          final sha256_S4 = Sha256();
          final hash_S3 = await sha256_S4.hash(confirmationS3);
          String encoded_hash_S4 = base64.encode(hash_S3.bytes);

          if (childFour["hs"] == encoded_hash_S4) {
            isAuthenticated = true;
            _naniDict[_isAuth] = true;
            _naniDict[_socket] = sock;
            // print("Authenticated...");
            _isAuthenticated = true;
            if (!_funcStkBefAuth.isEmpty) {
              _funcStkBefAuth.forEach((value) {
                final fn = value[0];
                fn(value[1][0], value[1][1]);
              });
            }
          }
        }
      } else {
        if (main["tp"] == "auth-E-DSP" && main["md"] == "~~") {
          Uint8List childJsonCipher = base64.decode(main["cj"] ?? "null");
          List<int> dspData =
              await _shivani.aesDecrypt(childJsonCipher, _naniDict[_aeskey]);
          Map<String, dynamic> childFour =
              jsonDecode(String.fromCharCodes(dspData));
          if (childFour["tp"] == "E-DSP") {
            String channel = childFour["chnl"] ?? "unknown";
            for (int i = 0; i < _listenerFuncs.length; i++) {
              if (_listenerFuncs[i]["channel"] == channel) {
                dynamic foundRecord = _listenerFuncs[i]["function"];
                Map<String, String> newData = {
                  "sender": childFour["nm"] ?? "unKnown",
                  "data": childFour["dt"] ?? "not found",
                  "datetime": childFour["dttm"] ?? "unknown"
                };
                foundRecord(newData, send);
                _listenerFuncs.removeAt(i);
                break;
              }
            }
          }
        }
      }
    });
  }

  /// It is used to send the data to server.
  void send(String channel, String data) async {
    if (_isAuthenticated) {
      Future<String> fData = _prepare_data(data, channel);
      fData.then((value) {
        _sender(value, _naniDict[_socket]);
      });
    } else {
      _funcStkBefAuth.add([
        send,
        [channel, data]
      ]);
    }
  }

  /// It can be used to listen for the coming the data from server on the specific channels.
  void listen(
      String channel,
      void Function(
              Map<String, String> data, void Function(String, String) sender)
          fn) {
    Map<String, dynamic> _dictData = {"channel": channel, "function": fn};
    _listenerFuncs.add(_dictData);
  }

  // For checking the whether the connection have been closed from the Engine.
  bool isClosed() {
    try {
      _naniDict[_socket].address;
    } catch (e) {
      if (e == SocketException) {
        return true;
      }
    }
    return false;
  }

  /// For closing the connection between the client and engine.
  void close() {
    _naniDict[_socket].close();
  }
}

/// This is the main class the will be used to create the client.
/// The name ```ShiSockClient``` is becouse it work as client to connect to
/// the server. In future we are planning to develop the server as well.
/// And the obivious name would be ```ShiSockServer```.
/// This class has only one function: ```connect```.
///  ```Connect``` takes only to arguments: the address of type ```string``` and
/// port of type ```int```.
/// ```Connect``` returns a ```ShiSockListener``` object.
class ShiSockClient {
  /// ```Connect``` will be used to connect to the server. It returns a ```ShiSockListener```
  /// object. It should be the first function to be called while creating the client.
  ShiSockListener connect(String address, int port) {
    ShiSockListener sock = ShiSockListener(address, port);
    return sock;
  }
}
