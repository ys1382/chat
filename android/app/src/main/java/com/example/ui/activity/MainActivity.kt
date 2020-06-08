package com.example.ui.activity

import android.content.SharedPreferences
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.compose.Composable
import androidx.ui.animation.Crossfade
import androidx.ui.core.setContent
import androidx.ui.foundation.Icon
import androidx.ui.foundation.Image
import androidx.ui.foundation.Text
import androidx.ui.material.IconButton
import androidx.ui.material.MaterialTheme
import androidx.ui.material.Surface
import androidx.ui.material.TopAppBar
import androidx.ui.material.icons.Icons
import androidx.ui.material.icons.filled.Menu
import androidx.ui.res.loadVectorResource
import androidx.ui.tooling.preview.Preview
import com.example.application.MyApplication
import com.example.demojetpackcompose.R
import com.example.model.Room
import com.example.ui.ChatStatus
import com.example.ui.Screen
import com.example.ui.home.CreateNewRoom
import com.example.ui.home.HomeView
import com.example.ui.home.HomeView2
import com.example.ui.home.RoomDetail
import com.example.ui.navigateTo
import grpc.PscrudGrpc

class MainActivity : AppCompatActivity() {

    lateinit var grpcClient: PscrudGrpc.PscrudStub
    lateinit var sharedPreferences : SharedPreferences

    val rooms = mutableListOf<Room>()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val appContainer = (application as MyApplication).container
        grpcClient = appContainer.grpcClient
        sharedPreferences = appContainer.sharedPreferences

        setContent {
            DrawerAppComponent()
        }
    }

    @Composable
    fun DrawerAppComponent() {
        Crossfade(ChatStatus.currentScreen) { screen ->
            Surface(color = MaterialTheme.colors.background) {
                when (screen) {
                    is Screen.Home -> HomeView(rooms,this,sharedPreferences)
                    is Screen.HomeView2 -> HomeView2(this,sharedPreferences)
                    is Screen.CreateNewRoom -> CreateNewRoom(rooms)
                    is Screen.RoomDetail -> RoomDetail(screen.roomId, grpcClient)
                }
            }
        }
    }
}

