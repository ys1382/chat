package com.example.data

import android.content.Context
import android.content.SharedPreferences
import android.os.Handler
import android.os.Looper
import grpc.PscrudGrpc
import io.grpc.ManagedChannelBuilder
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.asExecutor

/**
 * Dependency Injection container at the application level.
 */
interface AppContainer {
    val grpcClient: PscrudGrpc.PscrudStub
    val sharedPreferences: SharedPreferences
    val mainThreadHandler: Handler
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
}
