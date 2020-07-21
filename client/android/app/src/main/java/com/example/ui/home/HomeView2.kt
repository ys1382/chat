package com.example.ui.home

import android.app.Activity
import android.os.Handler
import androidx.compose.Composable
import androidx.compose.remember
import androidx.ui.core.Modifier
import androidx.ui.foundation.Icon
import androidx.ui.foundation.Image
import androidx.ui.foundation.Text
import androidx.ui.layout.Column
import androidx.ui.layout.padding
import androidx.ui.material.*
import androidx.ui.material.icons.Icons
import androidx.ui.material.icons.filled.Menu
import androidx.ui.res.loadVectorResource
import androidx.ui.unit.dp
import com.example.chate2e.R
import com.example.db.UserRepository
import com.example.ui.Screen
import com.example.ui.component.AppDrawer
import com.example.ui.navigateTo
import grpc.PscrudGrpc

@Composable
fun HomeView2(
    activity: Activity,
    dbLocal: UserRepository, grpcClient: PscrudGrpc.PscrudStub, mainThreadHandler: Handler,
    scaffoldState: ScaffoldState = remember { ScaffoldState() }
) {
    Scaffold(
        scaffoldState = scaffoldState,
        drawerContent = {
            AppDrawer(
                currentScreen = Screen.HomeView2,
                closeDrawer = { scaffoldState.drawerState = DrawerState.Closed },
                activity = activity,
                dbLocal = dbLocal, grpcClient = grpcClient, mainThreadHandler = mainThreadHandler
            )
        },
        topAppBar = {
            TopAppBar(
                title = { Text(text = "Jetnews") },
                navigationIcon = {
                    IconButton(onClick = { scaffoldState.drawerState = DrawerState.Opened }) {
                        Icon(asset = Icons.Filled.Menu)
                    }
                },
                actions = {
                    IconButton(onClick = {
                        navigateTo(Screen.CreateNewRoom)
                    }) {
                        val vectorAsset = loadVectorResource(R.drawable.ic_add_white_24dp)
                        vectorAsset.resource.resource?.let {
                            Image(
                                asset = it
                            )
                        }
                    }
                }
            )
        },
        bodyContent = { modifier ->
            Column() {
                Surface() {

                }
                OutlinedButton(
                    onClick = {


                    },
                    modifier = Modifier.padding(16.dp) + Modifier.weight(1f)
                ) {
                    Text(text = "Login", modifier = Modifier.padding(16.dp, 8.dp, 16.dp, 8.dp))

                }
            }

        }
    )


}
