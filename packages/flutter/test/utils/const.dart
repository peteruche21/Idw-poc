import 'dart:convert';

import 'package:cbor/simple.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:pks_4337_sdk/pks_4337_sdk.dart';
import 'package:pks_4337_sdk/src/signer/passkey_types.dart';
import 'package:uuid/uuid.dart';
import 'package:webauthn/webauthn.dart';

String randomChallenge(PassKeysOptions options) {
  final uuid = const Uuid()
      .v5buffer(Uuid.NAMESPACE_URL, options.name, List<int>.filled(32, 0));
  return base64Url.encode(uuid);
}

Uint8List clientDataHash(PassKeysOptions options, {String? challenge}) {
  options.challenge = challenge ?? randomChallenge(options);
  final clientDataJson = jsonEncode({
    "type": options.type,
    "challenge": options.challenge,
    "origin": options.origin,
    "crossOrigin": options.crossOrigin
  });
  return Uint8List.fromList(utf8.encode(clientDataJson));
}

Uint8List clientDataHash32(PassKeysOptions options, {String? challenge}) {
  final dataBuffer = clientDataHash(options, challenge: challenge);

  /// Hashes client data using the sha256 hashing algorithm
  final sha256Hash = sha256.convert(dataBuffer);
  return Uint8List.fromList(sha256Hash.bytes);
}

const makeCredentialJson = '''{
    "authenticatorExtensions": "",
    "clientDataHash": "",
    "credTypesAndPubKeyAlgs": [
        ["public-key", -7]
    ],
    "excludeCredentials": [],
    "requireResidentKey": true,
    "requireUserPresence": true,
    "requireUserVerification": false,
    "rp": {
        "name": "",
        "id": ""
    },
    "user": {
        "name": "",
        "displayName": "",
        "id": ""
    }
  }''';

final uint8List = Uint8List.fromList([
 32, 95, 95, 99, 196, 166, 206, 189, 198, 120, 68, 183, 81, 134, 54, 126, 109, 46, 79, 25, 185, 118, 171, 10, 255, 239, 180, 233, 129, 194, 36, 53, 5, 0, 0, 0, 1
]);

AuthData decode(dynamic authData) {
  // Extract the length of the public key from the authentication data.
  final l = (authData[53] << 8) + authData[54];

  // Calculate the offset for the start of the public key data.
  final publicKeyOffset = 55 + l;

  // Extract the public key data from the authentication data.
  final pKey = authData.sublist(publicKeyOffset);

  // Extract the credential ID from the authentication data.
  final credentialId = authData.sublist(55, publicKeyOffset);

  // Extract and encode the aaGUID from the authentication data.
  final aaGUID = base64Url.encode(authData.sublist(37, 53));

  // Decode the CBOR-encoded public key and convert it to a map.
  final decodedPubKey = cbor.decode(pKey) as Map;

// Calculate the hash of the credential ID.
  final credentialHash = hexlify(keccak256(Uint8List.fromList(credentialId)));
// Extract x and y coordinates from the decoded public key.
  final x = hexlify(decodedPubKey[-2]);
  final y = hexlify(decodedPubKey[-3]);

  return AuthData(
      credentialHash, base64Url.encode(credentialId), [x, y], aaGUID);
}

AuthData decodeAttestation(Attestation attestation) {
  final attestationAsCbor = attestation.asCBOR();
  final decodedAttestationAsCbor = cbor.decode(attestationAsCbor) as Map;
  final authData = decodedAttestationAsCbor["authData"];
  final decode = _decode(authData);
  return decode;
}

AuthData _decode(dynamic authData) {
  // Extract the length of the public key from the authentication data.
  final l = (authData[53] << 8) + authData[54];

  // Calculate the offset for the start of the public key data.
  final publicKeyOffset = 55 + l;

  // Extract the public key data from the authentication data.
  final pKey = authData.sublist(publicKeyOffset);

  // Extract the credential ID from the authentication data.
  final credentialId = authData.sublist(55, publicKeyOffset);

  // Extract and encode the aaGUID from the authentication data.
  final aaGUID = base64Url.encode(authData.sublist(37, 53));

  // Decode the CBOR-encoded public key and convert it to a map.
  final decodedPubKey = cbor.decode(pKey) as Map;

// Calculate the hash of the credential ID.
  final credentialHash = hexlify(keccak256(Uint8List.fromList(credentialId)));
// Extract x and y coordinates from the decoded public key.
  final x = hexlify(decodedPubKey[-2]);
  final y = hexlify(decodedPubKey[-3]);

  return AuthData(
      credentialHash, base64Url.encode(credentialId), [x, y], aaGUID);
}