package com.example.ui.home

import android.app.Activity
import android.content.SharedPreferences
import androidx.compose.Composable
import androidx.compose.remember
import androidx.ui.core.Modifier
import androidx.ui.foundation.AdapterList
import androidx.ui.foundation.Icon
import androidx.ui.foundation.Image
import androidx.ui.foundation.Text
import androidx.ui.foundation.shape.corner.RoundedCornerShape
import androidx.ui.graphics.Color
import androidx.ui.layout.*
import androidx.ui.layout.ColumnScope.weight
import androidx.ui.layout.RowScope.weight
import androidx.ui.material.*
import androidx.ui.material.icons.Icons
import androidx.ui.material.icons.filled.Menu
import androidx.ui.res.loadVectorResource
import androidx.ui.text.TextStyle
import androidx.ui.text.style.TextAlign
import androidx.ui.unit.dp
import androidx.ui.unit.sp
import com.example.demojetpackcompose.R
import com.example.ui.*
import com.example.ui.component.AppDrawer

@Composable
fun HomeView2(
    activity: Activity,
    sharedPreferences: SharedPreferences,
    scaffoldState: ScaffoldState = remember { ScaffoldState() }
) {
    Scaffold(
        scaffoldState = scaffoldState,
        drawerContent = {
            AppDrawer(
                currentScreen = Screen.HomeView2,
                closeDrawer = { scaffoldState.drawerState = DrawerState.Closed },
                activity = activity,
                sharedPreferences = sharedPreferences
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
                    AdapterListingScrollableComponent(
                        getPersonList()
                    )
                }
                OutlinedButton(
                    onClick = {
                        getPersonList().add(1, Person("A", 34))

                    },
                    modifier = Modifier.padding(16.dp) + Modifier.weight(1f)
                ) {
                    Text(text = "Login", modifier = Modifier.padding(16.dp, 8.dp, 16.dp, 8.dp))

                }
            }

        }
    )


}

@Composable
fun AdapterListingScrollableComponent(personList: List<Person>) {
    // AdapterList is a vertically scrolling list that only composes and lays out the currently
    // visible items. This is very similar to what RecylerView tries to do as it's more optimized
    // than the VerticalScroller.
    AdapterList(data = personList, modifier = Modifier.fillMaxHeight()) { person ->
        // TODO(vinaygaba) Replace this with an index callback once its available.
        val index = personList.indexOf(person)
        // Row is a composable that places its children in a horizontal sequence. You
        // can think of it similar to a LinearLayout with the horizontal orientation.
        // In addition, we pass a modifier to the Row composable. You can think of
        // Modifiers as implementations of the decorators pattern that  are used to
        // modify the composable that its applied to. In this example, we configure the
        // Row to occupify the entire available width using Modifier.fillMaxWidth() and also give
        // it a padding of 16dp.
        Row(modifier = Modifier.padding(16.dp) + Modifier.fillMaxWidth()) {
            // Card composable is a predefined composable that is meant to represent the card surface as
            // specified by the Material Design specification. We also configure it to have rounded
            // corners and apply a modifier.
            Card(
                shape = RoundedCornerShape(4.dp), color = colors[index % colors.size],
                modifier = Modifier.fillMaxWidth()
            ) {
                // Text is a predefined composable that does exactly what you'd expect it to -
                // display text on the screen. It allows you to customize its appearance using
                // the style property.
                Text(
                    person.name, style = TextStyle(
                        color = Color.Black,
                        fontSize = 20.sp,
                        textAlign = TextAlign.Center
                    ), modifier = Modifier.padding(16.dp)
                )
            }
        }
    }
}