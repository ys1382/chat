package com.example.secure

import com.example.utils.base64Decode
import com.example.utils.base64Encode
import com.google.crypto.tink.CleartextKeysetHandle
import com.google.crypto.tink.JsonKeysetReader
import com.google.crypto.tink.aead.AeadFactory
import java.io.IOException
import java.io.UnsupportedEncodingException
import java.nio.charset.StandardCharsets
import java.security.GeneralSecurityException
import java.security.NoSuchAlgorithmException
import java.security.spec.InvalidKeySpecException
import javax.crypto.SecretKeyFactory
import javax.crypto.spec.PBEKeySpec

object TinkPbe {
    val PW = "Password".toCharArray()
    @Throws(GeneralSecurityException::class, IOException::class)
    fun encrypt(plaintextString: String,secretKey: ByteArray?): String {
        val keyByte = pbkdf2()
        val valueString = buildValue(keyByte)
        val jsonKeyString = writeJson(valueString)
        val keysetHandleOwn =
            CleartextKeysetHandle.read(JsonKeysetReader.withString(jsonKeyString))
        val aead = AeadFactory.getPrimitive(keysetHandleOwn)
        val ciphertextByte = aead.encrypt(
            plaintextString.toByteArray(StandardCharsets.UTF_8),
            secretKey
        ) // no aad-data
        return base64Encode(ciphertextByte)
    }

    @Throws(GeneralSecurityException::class, IOException::class)
    fun decrypt(ciphertextString: String?, secretKey: ByteArray?): String {
        val keyByte = pbkdf2()
        val valueString = buildValue(keyByte)
        val jsonKeyString = writeJson(valueString)
        val keysetHandleOwn =
            CleartextKeysetHandle.read(JsonKeysetReader.withString(jsonKeyString))
        // initialisierung
        val aead = AeadFactory.getPrimitive(keysetHandleOwn)
        // verschlüsselung
        val plaintextByte =
            aead.decrypt(base64Decode(ciphertextString!!), secretKey) // no aad-data
        return String(plaintextByte, StandardCharsets.UTF_8)
    }

    @Throws(
        NoSuchAlgorithmException::class,
        InvalidKeySpecException::class,
        UnsupportedEncodingException::class
    )
    private fun pbkdf2(): ByteArray {
        val passwordSaltByte = ByteArray(16)
        val PBKDF2_ITERATIONS = 100
        val HASH_SIZE_BYTE = 256
        val spec = PBEKeySpec(
            PW,
            passwordSaltByte,
            PBKDF2_ITERATIONS,
            HASH_SIZE_BYTE
        )
        val skf =SecretKeyFactory.getInstance("PBKDF2WithHmacSHA512")
        return skf.generateSecret(spec).encoded
    }

    private fun buildValue(gcmKeyByte: ByteArray): String {
        // test for correct key length
        if (gcmKeyByte.size != 16 && gcmKeyByte.size != 32) {
            throw NumberFormatException("key is not 16 or 32 bytes long")
        }
        // header byte depends on keylength
        var headerByte =
            ByteArray(2) // {26, 16 }; // 1A 10 for 128 bit, 1A 20 for 256 Bit
        headerByte = if (gcmKeyByte.size == 16) {
            byteArrayOf(26, 16)
        } else {
            byteArrayOf(26, 32)
        }
        val keyByte = ByteArray(headerByte.size + gcmKeyByte.size)
        System.arraycopy(headerByte, 0, keyByte, 0, headerByte.size)
        System.arraycopy(gcmKeyByte, 0, keyByte, headerByte.size, gcmKeyByte.size)
        return base64Encode(keyByte)
    }

    private fun writeJson(value: String): String {
        val keyId = 1234567 // fix
        var str = "{\n"
        str = "$str    \"primaryKeyId\": $keyId,\n"
        str = "$str    \"key\": [{\n"
        str = "$str        \"keyData\": {\n"
        str =
            "$str            \"typeUrl\": \"type.googleapis.com/google.crypto.tink.AesGcmKey\",\n"
        str = "$str            \"keyMaterialType\": \"SYMMETRIC\",\n"
        str = "$str            \"value\": \"$value\"\n"
        str = "$str        },\n"
        str = "$str        \"outputPrefixType\": \"TINK\",\n"
        str = "$str        \"keyId\": $keyId,\n"
        str = "$str        \"status\": \"ENABLED\"\n"
        str = "$str    }]\n"
        str = "$str}"
        return str
    }
}