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
    override fun onCreate() {
        super.onCreate()
        container = AppContainerImpl(applicationContext)
        TinkConfig.register()
    }
}
