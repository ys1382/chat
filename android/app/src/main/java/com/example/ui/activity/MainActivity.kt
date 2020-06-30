package com.example.ui.activity

import android.os.Bundle
import android.os.Handler
import androidx.appcompat.app.AppCompatActivity
import androidx.compose.Composable
import androidx.ui.animation.Crossfade
import androidx.ui.core.setContent
import androidx.ui.material.MaterialTheme
import androidx.ui.material.Surface
import com.example.application.MyApplication
import com.example.data.DataStore
import com.example.db.UserRepository
import com.example.model.Room
import com.example.ui.ChatStatus
import com.example.ui.Screen
import com.example.ui.home.*
import grpc.PscrudGrpc

class MainActivity : AppCompatActivity() {

    lateinit var grpcClient: PscrudGrpc.PscrudStub
    lateinit var mainThreadHandler: Handler
    lateinit var dbLocal: UserRepository
    val rooms = mutableListOf<Room>()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val appContainer = (application as MyApplication).container
        grpcClient = appContainer.grpcClient
        mainThreadHandler = appContainer.mainThreadHandler
        dbLocal =appContainer.dbLocal
        listen(grpcClient, mainThreadHandler)
        subscribe(grpcClient, DataStore.username)
        setContent {
            DrawerAppComponent()
        }
    }

    @Composable
    fun DrawerAppComponent() {
        Crossfade(ChatStatus.currentScreen) { screen ->
            Surface(color = MaterialTheme.colors.background) {
                when (screen) {
                    is Screen.Home -> HomeView(rooms, this, dbLocal,grpcClient,mainThreadHandler)
                    is Screen.HomeView2 -> HomeView2(this, dbLocal,grpcClient,mainThreadHandler)
                    is Screen.CreateNewRoom -> CreateNewRoom(rooms)
                    is Screen.RoomDetail -> RoomDetail(screen.roomId, grpcClient, mainThreadHandler)
                }
            }
        }
    }


}

