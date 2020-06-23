package com.example.application

import android.app.Application
import android.content.Context
import com.example.data.AppContainer
import com.example.data.AppContainerImpl
import com.google.crypto.tink.Aead
import com.google.crypto.tink.Config
import com.google.crypto.tink.KeysetHandle
import com.google.crypto.tink.aead.AeadKeyTemplates
import com.google.crypto.tink.config.TinkConfig
import com.google.crypto.tink.integration.android.AndroidKeysetManager
import java.io.IOException
import java.security.GeneralSecurityException


class MyApplication : Application() {

    // AppContainer instance used by the rest of classes to obtain dependencies
    lateinit var container: AppContainer
    @JvmField
    var aead: Aead? = null
    override fun onCreate() {
        super.onCreate()
        container = AppContainerImpl(applicationContext)
        aead = try {
            TinkConfig.register();
            orGenerateNewKeysetHandle.getPrimitive(Aead::class.java)
        } catch (e: GeneralSecurityException) {
            throw RuntimeException(e)
        } catch (e: IOException) {
            throw RuntimeException(e)
        }
    }


    @get:Throws(IOException::class, GeneralSecurityException::class)
    private val orGenerateNewKeysetHandle: KeysetHandle
        private get() = AndroidKeysetManager.Builder()
            .withSharedPref(applicationContext, TINK_KEYSET_NAME, PREF_FILE_NAME)
            .withKeyTemplate(AeadKeyTemplates.AES256_GCM)
            .withMasterKeyUri(MASTER_KEY_URI)
            .build()
            .keysetHandle

    companion object {
        private const val PREF_FILE_NAME = "CK_SHARED_PREF"
        private const val TINK_KEYSET_NAME = "hello_world_keyset"
        private const val MASTER_KEY_URI = "android-keystore://hello_master_key"
    }
}
