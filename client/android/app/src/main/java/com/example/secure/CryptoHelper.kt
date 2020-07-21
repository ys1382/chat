package com.example.secure

import android.text.TextUtils
import chat.Chat
import com.example.data.DataStore
import com.example.db.UserRepository
import com.example.model.User
import com.google.crypto.tink.subtle.X25519
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import com.google.protobuf.ByteString

object CryptoHelper {
    val keys = mutableMapOf<String, KeySet>()

    data class KeySend(
        var signing: ByteArray?, //Curve25519.Signing.PublicKey?
        var agreement: ByteArray //Curve25519.KeyAgreement.PublicKey
    )

    data class KeySet(
        var ourSigning: ByteArray,  //Signing.PrivateKey
        var ourAgreement: ByteArray, //KeyAgreement.PrivateKey
        var theirSigning: ByteArray?, //Signing.PublicKey?
        var theirAgreement: ByteArray? //KeyAgreement.PublicKey?
    )

    fun initKeysSession(keyPair: String?) {
        if (!TextUtils.isEmpty(keyPair)) {
            val type = object : TypeToken<MutableMap<String, KeySet>>() {}.getType()
            val listDeviceConnect: MutableMap<String, KeySet> =
                Gson().fromJson(keyPair, type)

            for ( item in listDeviceConnect){
                keys.put(item.key, item.value)
            }
        }
    }

    fun getKeySet(id: String): KeySet? {
        return keys.get(id)
    }

    fun signing(data: Chat.Handshake): ByteString {
        return data.signing
    }

    fun agreement(data: Chat.Handshake): ByteString {
        return data.agreement
    }

    fun checkHandShaked(id: String): Boolean {
        val keyset = getKeySet(id)
        if (keyset != null && keyset.theirAgreement != null) {
            return true
        }
        return false
    }


    // returns false if this is a response to the handshake we sent
    fun set(agreement: ByteArray, sender: String, dbLocal: UserRepository): Boolean {
        val key = getKeySet(sender)
        if (key != null) {
            keys[sender]!!.theirAgreement = agreement

            val currentUser = dbLocal.getUserByName(DataStore.username)
            if (!TextUtils.isEmpty(currentUser?.security)) {
                val type = object : TypeToken<MutableMap<String, KeySet>>() {}.getType()
                val listDeviceConnect: MutableMap<String, KeySet> =
                    Gson().fromJson(currentUser!!.security, type)
                listDeviceConnect.set(sender, getKeySet(sender)!!)

                currentUser.security = Gson().toJson(listDeviceConnect)
                dbLocal.updateUser(currentUser)
            } else {

                val listDeviceConnect = mutableMapOf<String, KeySet>()
                listDeviceConnect.set(sender, getKeySet(sender)!!)

                currentUser!!.security = Gson().toJson(listDeviceConnect)
                dbLocal.updateUser(currentUser)
            }


            return false
        } else {
            val privateKey = X25519.generatePrivateKey();
            val publishKey = X25519.publicFromPrivate(privateKey);

            keys[sender] = KeySet(
                privateKey,
                publishKey,
                null,
                agreement
            )

            val currentUser = dbLocal.getUserByName(DataStore.username)
            if (!TextUtils.isEmpty(currentUser?.security)) {
                val type = object : TypeToken<MutableMap<String, KeySet>>() {}.getType()
                val listDeviceConnect: MutableMap<String, KeySet> =
                    Gson().fromJson(currentUser!!.security, type)
                listDeviceConnect.set(sender, keys[sender]!!)

                currentUser.security = Gson().toJson(listDeviceConnect)
                dbLocal.updateUser(currentUser)

            } else {
                val listDeviceConnect = mutableMapOf<String, KeySet>()
                listDeviceConnect.set(sender, getKeySet(sender)!!)

                currentUser!!.security = Gson().toJson(listDeviceConnect)
                dbLocal.updateUser(currentUser)
            }
        }
        return true
    }

    fun getKeySendTo(recipient: String): KeySend {
        val key = keys[recipient]
        if (null != key) {
            return KeySend(key.ourSigning, key.ourAgreement)
        } else {
            // Generate my KeyPair
            val privateKey = X25519.generatePrivateKey()
            val publishKey = X25519.publicFromPrivate(privateKey);

            keys[recipient] = KeySet(privateKey, publishKey, null, null)
            return KeySend(privateKey, publishKey)
        }
    }

    fun getSecretKey(keySet: KeySet): ByteArray? {
        return X25519.computeSharedSecret(keySet.ourSigning, keySet.theirAgreement)
    }
}
