package com.example.ui.home

import androidx.compose.Composable
import androidx.ui.core.Alignment
import androidx.ui.core.Modifier
import androidx.ui.foundation.*
import androidx.ui.graphics.Color
import androidx.ui.layout.*
import androidx.ui.layout.ColumnScope.weight
import androidx.ui.material.*
import androidx.ui.material.icons.Icons
import androidx.ui.material.icons.filled.ArrowBack
import androidx.ui.material.ripple.ripple
import androidx.ui.res.imageResource
import androidx.ui.text.TextStyle
import androidx.ui.text.style.TextAlign
import androidx.ui.unit.dp
import androidx.ui.unit.sp
import com.example.demojetpackcompose.R
import com.example.model.Message
import com.example.model.Room
import com.example.ui.Screen
import com.example.ui.navigateTo
import com.example.ui.component.FilledTextInputComponent

@Composable
fun CreateNewRoom(rooms: MutableList<Room>) {
    Column(modifier = Modifier.fillMaxWidth()) {
        TopAppBar(
            title = {
                Text(text = "Create a New Room")
            },
            navigationIcon = {
                IconButton(onClick = { navigateTo(Screen.Home) }) {
                    Icon(asset = Icons.Filled.ArrowBack)
                }
            }
        )
        Surface(color = Color(0xFFfff), modifier = Modifier.weight(1f)) {
            // Center is a composable that centers all the child composables that are passed to it.
            viewCreateNewRoom(rooms)
        }
    }
}

@Composable
fun viewCreateNewRoom(rooms: MutableList<Room>) {
    Row(modifier = Modifier.fillMaxSize()) {
        Column(modifier = Modifier.fillMaxSize()) {
            Spacer(Modifier.preferredHeight(24.dp))

            val image = imageResource(R.drawable.door)
            val imageModifier = Modifier
                .preferredSize(100.dp)

            Box(Modifier.fillMaxWidth(), gravity = Alignment.TopCenter) {
                Image(image, imageModifier)
            }
            Spacer(Modifier.preferredHeight(48.dp))

            val roomId = FilledTextInputComponent("Recipient", " ")

            Spacer(Modifier.preferredHeight(48.dp))
            Row() {

                OutlinedButton(
                    onClick = {
                        if (roomId.isNotBlank()) {
                            rooms.add(Room(roomId))
                        }
                        navigateTo(Screen.Home)
                    },
                    modifier = Modifier.padding(16.dp) + Modifier.weight(1f)
                ) {
                    Text(text = "Ok",
                        color = Color.Blue,
                        modifier = Modifier.padding(16.dp, 8.dp, 16.dp, 8.dp)
                    )
                }


                OutlinedButton(
                    onClick = { navigateTo(Screen.Home) },
                    modifier = Modifier.padding(16.dp) + Modifier.weight(1f)
                ) {
                    Text(
                        text = "Cancel",
                        color = Color.Blue,
                        modifier = Modifier.padding(16.dp, 8.dp, 16.dp, 8.dp)
                    )
                }
            }
        }
    }

}