import 'dart:convert';

class PixUtils {
  /// Gera o payload do Pix Copia e Cola (EMV QRCPS-MPM)
  static String generatePixPayload({
    required String pixKey,
    required String name,
    required String city,
    required double amount,
    String? txId,
  }) {
    final String merchantName = _formatString(name, 25);
    final String merchantCity = _formatString(city, 15);
    final String amountStr = amount.toStringAsFixed(2);
    final String transactionId = txId ?? '***'; // *** indica um txId genérico

    final StringBuffer payload = StringBuffer();

    // ID 00: Payload Format Indicator
    payload.write(_buildEMV('00', '01'));

    // ID 26: Merchant Account Information
    final StringBuffer merchantAccount = StringBuffer();
    merchantAccount.write(_buildEMV('00', 'BR.GOV.BCB.PIX'));
    merchantAccount.write(_buildEMV('01', pixKey));
    payload.write(_buildEMV('26', merchantAccount.toString()));

    // ID 52: Merchant Category Code (0000 = Geral)
    payload.write(_buildEMV('52', '0000'));

    // ID 53: Transaction Currency (986 = BRL)
    payload.write(_buildEMV('53', '986'));

    // ID 54: Transaction Amount
    payload.write(_buildEMV('54', amountStr));

    // ID 58: Country Code
    payload.write(_buildEMV('58', 'BR'));

    // ID 59: Merchant Name
    payload.write(_buildEMV('59', merchantName));

    // ID 60: Merchant City
    payload.write(_buildEMV('60', merchantCity));

    // ID 62: Additional Data Field Template
    final StringBuffer additionalData = StringBuffer();
    additionalData.write(_buildEMV('05', transactionId));
    payload.write(_buildEMV('62', additionalData.toString()));

    // ID 63: CRC16 (Adiciona o ID e o tamanho, o valor é calculado depois)
    payload.write('6304');

    // Calcula o CRC16
    final String crc = _calculateCRC16(payload.toString());
    payload.write(crc);

    return payload.toString();
  }

  /// Formata um campo EMV TLV (Type-Length-Value)
  static String _buildEMV(String id, String value) {
    final String len = value.length.toString().padLeft(2, '0');
    return '$id$len$value';
  }

  /// Remove acentos e caracteres especiais para compatibilidade
  static String _formatString(String text, int maxLength) {
    // Normalização básica (pode ser melhorada com pacotes específicos)
    var formatted = text
        .replaceAll(RegExp(r'[ÁÀÂÃ]'), 'A')
        .replaceAll(RegExp(r'[áàâã]'), 'a')
        .replaceAll(RegExp(r'[ÉÈÊ]'), 'E')
        .replaceAll(RegExp(r'[éèê]'), 'e')
        .replaceAll(RegExp(r'[ÍÌÎ]'), 'I')
        .replaceAll(RegExp(r'[íìî]'), 'i')
        .replaceAll(RegExp(r'[ÓÒÔÕ]'), 'O')
        .replaceAll(RegExp(r'[óòôõ]'), 'o')
        .replaceAll(RegExp(r'[ÚÙÛ]'), 'U')
        .replaceAll(RegExp(r'[úùû]'), 'u')
        .replaceAll(RegExp(r'[Ç]'), 'C')
        .replaceAll(RegExp(r'[ç]'), 'c');

    if (formatted.length > maxLength) {
      formatted = formatted.substring(0, maxLength);
    }
    return formatted.toUpperCase(); // Pix exige maiúsculas nos nomes
  }

  /// Calcula o CRC16-CCITT (0xFFFF)
  static String _calculateCRC16(String payload) {
    int crc = 0xFFFF; // Valor inicial
    final List<int> bytes = utf8.encode(payload);

    for (int byte in bytes) {
      crc ^= (byte << 8);
      for (int i = 0; i < 8; i++) {
        if ((crc & 0x8000) != 0) {
          crc = (crc << 1) ^ 0x1021;
        } else {
          crc = crc << 1;
        }
      }
    }

    // Retorna o Hexadecimal com 4 caracteres
    return (crc & 0xFFFF).toRadixString(16).toUpperCase().padLeft(4, '0');
  }
}
