package com.example.application

import android.app.Application
import com.example.data.AppContainer
import com.example.data.AppContainerImpl

class MyApplication : Application() {

    // AppContainer instance used by the rest of classes to obtain dependencies
    lateinit var container: AppContainer

    override fun onCreate() {
        super.onCreate()
        container = AppContainerImpl(applicationContext)
    }
}
