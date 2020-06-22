package com.example.data

import android.content.Context
import android.content.SharedPreferences
import android.os.Handler
import android.os.Looper
import com.google.crypto.tink.Aead
import com.google.crypto.tink.Config
import com.google.crypto.tink.KeysetHandle
import com.google.crypto.tink.aead.AeadKeyTemplates
import com.google.crypto.tink.config.TinkConfig
import com.google.crypto.tink.integration.android.AndroidKeysetManager
import grpc.PscrudGrpc
import io.grpc.ManagedChannelBuilder
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.asExecutor
import java.io.IOException
import java.security.GeneralSecurityException


/**
 * Dependency Injection container at the application level.
 */
interface AppContainer {
    val grpcClient: PscrudGrpc.PscrudStub
    val sharedPreferences: SharedPreferences
    val mainThreadHandler: Handler
    var aead: Aead
}

/**
 * Implementation for the Dependency Injection container at the application level.
 *
 * Variables are initialized lazily and the same instance is shared across the whole app.
 */
class AppContainerImpl(context: Context) : AppContainer {
    override val grpcClient: PscrudGrpc.PscrudStub by lazy {
        val channel = ManagedChannelBuilder.forAddress("10.0.2.2", 11912)
            .usePlaintext()
            .executor(Dispatchers.Default.asExecutor())
            .build()

        PscrudGrpc.newStub(channel)
    }

    override val sharedPreferences: SharedPreferences by lazy {
        context.getSharedPreferences("CK_SHARED_PREF", Context.MODE_PRIVATE)
    }

    override val mainThreadHandler: Handler by lazy {
        Handler(Looper.getMainLooper())
    }

    val orGen : KeysetHandle by lazy {
        AndroidKeysetManager.Builder()
            .withSharedPref(context, TINK_KEYSET_NAME, PREF_FILE_NAME)
            .withKeyTemplate(AeadKeyTemplates.AES256_GCM)
            .withMasterKeyUri(MASTER_KEY_URI)
            .build()
            .keysetHandle
    }

    override var aead = try {
        Config.register(TinkConfig.TINK_1_0_0)
        orGen.getPrimitive(Aead::class.java)
    } catch (e: GeneralSecurityException) {
        throw RuntimeException(e)
    } catch (e: IOException) {
        throw RuntimeException(e)
    }
    companion object {
        private const val PREF_FILE_NAME = "hello_world_pref"
        private const val TINK_KEYSET_NAME = "hello_world_keyset"
        private const val MASTER_KEY_URI = "android-keystore://hello_world_master_key"
    }
}




