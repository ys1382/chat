package com.example.secure;

import java.math.BigInteger;
import java.nio.charset.StandardCharsets;
import java.util.Objects;

import javax.crypto.Cipher;
import javax.crypto.spec.IvParameterSpec;
import javax.crypto.spec.SecretKeySpec;

import static com.example.utils.UtilsKt.base64Encode;

public class CryptoChaCha20 {
    private static final String ENCRYPT_ALGO = "ChaCha20/None/NoPadding";

    private static final int KEY_LEN = 256;

    private static final int NONCE_LEN = 12; //bytes

    private static final BigInteger NONCE_MIN_VAL = new BigInteger("100000000000000000000000", 16);
    private static final BigInteger NONCE_MAX_VAL = new BigInteger("ffffffffffffffffffffffff", 16);

    private static BigInteger nonceCounter = NONCE_MIN_VAL;

    public static String encrypt(byte[] input, byte[] secretKeySpec)
            throws Exception {

        SecretKeySpec key = new SecretKeySpec(secretKeySpec,
                "ChaCha20");

        Objects.requireNonNull(input, "Input message cannot be null");
        Objects.requireNonNull(key, "key cannot be null");

        if (input.length == 0) {
            throw new IllegalArgumentException("Length of message cannot be 0");
        }

        if (key.getEncoded().length * 8 != KEY_LEN) {
            throw new IllegalArgumentException("Size of key must be 256 bits");
        }
        Cipher cipher = Cipher.getInstance(ENCRYPT_ALGO);


        byte[] nonce = getNonce();

        IvParameterSpec ivParameterSpec = new IvParameterSpec(nonce);

        cipher.init(Cipher.ENCRYPT_MODE, key, ivParameterSpec);

        byte[] messageCipher = cipher.doFinal(input);

        // Prepend the nonce with the message cipher
        byte[] ciphertextByte = new byte[messageCipher.length + NONCE_LEN];
        System.arraycopy(nonce, 0, ciphertextByte, 0, NONCE_LEN);
        System.arraycopy(messageCipher, 0, ciphertextByte, NONCE_LEN,
                messageCipher.length);
        return base64Encode(ciphertextByte);
    }

    public static String decrypt(byte[] input, byte[] secretKeySpec)
            throws Exception {

        SecretKeySpec key = new SecretKeySpec(secretKeySpec,
                "ChaCha20");

        Objects.requireNonNull(input, "Input message cannot be null");
        Objects.requireNonNull(key, "key cannot be null");

        if (input.length == 0) {
            throw new IllegalArgumentException("Input array cannot be empty");
        }
        byte[] nonce = new byte[NONCE_LEN];
        System.arraycopy(input, 0, nonce, 0, NONCE_LEN);

        byte[] messageCipher = new byte[input.length - NONCE_LEN];
        System.arraycopy(input, NONCE_LEN, messageCipher, 0, input.length - NONCE_LEN);

        IvParameterSpec ivParameterSpec = new IvParameterSpec(nonce);

        Cipher cipher = Cipher.getInstance(ENCRYPT_ALGO);
        cipher.init(Cipher.DECRYPT_MODE, key, ivParameterSpec);
        return new String(cipher.doFinal(messageCipher), StandardCharsets.UTF_8);

    }


    public static byte[] getNonce() {
        if (nonceCounter.compareTo(NONCE_MAX_VAL) == -1) {
            return nonceCounter.add(BigInteger.ONE).toByteArray();
        } else {
            nonceCounter = NONCE_MIN_VAL;
            return NONCE_MIN_VAL.toByteArray();
        }
    }

}
