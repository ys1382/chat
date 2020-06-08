//package com.example.ui.home
//import android.util.Log
//import androidx.compose.Composable
//import androidx.compose.frames.ModelList
//import androidx.compose.state
//import androidx.ui.core.Constraints
//import androidx.ui.core.Layout
//import androidx.ui.core.Measurable
//import androidx.ui.core.Modifier
//import androidx.ui.foundation.*
//import androidx.ui.foundation.shape.corner.RoundedCornerShape
//import androidx.ui.graphics.Color
//import androidx.ui.layout.*
//import androidx.ui.layout.ColumnScope.weight
//import androidx.ui.material.*
//import androidx.ui.material.icons.Icons
//import androidx.ui.material.icons.filled.ArrowBack
//import androidx.ui.material.ripple.ripple
//import androidx.ui.text.TextStyle
//import androidx.ui.text.style.TextAlign
//import androidx.ui.text.style.TextDecoration
//import androidx.ui.unit.TextUnit
//import androidx.ui.unit.dp
//import androidx.ui.unit.ipx
//import androidx.ui.unit.sp
//import com.example.data.DataStore
//import com.example.model.Message
//import com.example.ui.Screen
//import com.example.ui.component.ChatModel
//import com.example.ui.navigateTo
//import com.google.protobuf.ByteString
//import grpc.PscrudGrpc
//import grpc.PscrudOuterClass
//import io.grpc.stub.StreamObserver
//
//private var messagesList = ModelList<Message>(
//)
//val data = ChatModel(messagesList)
//
//@Composable
//fun RoomDetailCoppy(
//    roomId: String,
//    grpcClient: PscrudGrpc.PscrudStub
//) {
////    subscribe(grpcClient = grpcClient, topicName = roomId)
//
//    Column(modifier = Modifier.fillMaxWidth()) {
//        TopAppBar(
//            title = {
//                Text(text = "Room " + roomId)
//            },
//            navigationIcon = {
//                IconButton(onClick = { navigateTo(Screen.Home) }) {
//                    Icon(asset = Icons.Filled.ArrowBack)
//                }
//            }
//        )
//        Surface(color = Color(0xFFfff), modifier = Modifier.weight(1f)) {
//            // Center is a composable that centers all the child composables that are passed to it.
//            Column(modifier = Modifier.fillMaxSize()) {
//                Column(
//                    modifier = Modifier.padding(16.dp, 8.dp, 16.dp, 8.dp) + Modifier.weight(
//                        0.66f
//                    )
//                ) {
//                    messagesList.clear()
//                    messagesList.add(Message("1", "Hello"))
//                    AdapterMessagesListing(data)
//                }
//
//                Row() {
//                    var message: String = ""
//                    Surface(
//                        color = Color.LightGray,
//                        modifier = Modifier.padding(16.dp, 8.dp, 16.dp, 8.dp) + Modifier.weight(
//                            0.66f
//                        ),
//                        shape = RoundedCornerShape(4.dp)
//                    ) {
//                        message =
//                            HintEditText(modifier = Modifier.padding(16.dp) + Modifier.fillMaxWidth())
//                    }
//                    Button(modifier = Modifier.padding(4.dp), onClick = {
//                        publish(grpcClient, roomId, message)
//                    }) {
//                        Text(
//                            text = "Send",
//                            style = TextStyle(fontSize = TextUnit.Sp(16))
//                        )
//                    }
//                }
//            }
//
//        }
//    }
//
//}
//
//@Composable
//fun HintEditText(
//    hintText: String = "Next Message",
//    modifier: Modifier = Modifier,
//    textStyle: TextStyle = currentTextStyle()
//): String {
//    val state = state { TextFieldValue("") }
//    val inputField = @Composable {
//        TextField(
//            value = state.value,
//            modifier = modifier,
//            onValueChange = { state.value = it },
//            textStyle = textStyle.merge(TextStyle(textDecoration = TextDecoration.None))
//        )
//    }
//
//    Layout(
//        children = @Composable {
//            inputField()
//            Text(
//                text = hintText,
//                modifier = modifier,
//                style = textStyle.merge(TextStyle(color = Color.Gray))
//            )
//            Divider(color = Color.Black, thickness = 2.dp)
//        },
//        measureBlock = { measurables: List<Measurable>, constraints: Constraints, _ ->
//            val inputFieldPlace = measurables[0].measure(constraints)
//            val hintEditPlace = measurables[1].measure(constraints)
//            val dividerEditPlace = measurables[2].measure(
//                Constraints(constraints.minWidth, constraints.maxWidth, 2.ipx, 2.ipx)
//            )
//            layout(
//                inputFieldPlace.width,
//                inputFieldPlace.height + dividerEditPlace.height
//            ) {
//                inputFieldPlace.place(0.ipx, 0.ipx)
//                if (state.value.text.isEmpty())
//                    hintEditPlace.place(0.ipx, 0.ipx)
//                dividerEditPlace.place(0.ipx, inputFieldPlace.height)
//            }
//        })
//    return state.value.text
//}
//
//fun publish(grpcClient: PscrudGrpc.PscrudStub, topicName: String, message: String) {
//    messagesList.add(Message("1", message = message))
//
//    val data = ByteString.copyFromUtf8(message)
//
//    val request = PscrudOuterClass.PublishRequest.newBuilder()
//        .setTopic(topicName)
//        .setSession(DataStore.session)
//        .setData(data)
//        .build()
//
//    grpcClient.publish(request, object : StreamObserver<PscrudOuterClass.Response> {
//        override fun onNext(response: PscrudOuterClass.Response?) {
//            response?.ok?.let { isSuccessful ->
//                if (isSuccessful) {
//                    messagesList.add(Message("1", message = message))
//                    Log.d("messagesList", messagesList.size.toString())
//                } else
//                    Log.d("messagesList", "Fails")
//            }
//        }
//
//        override fun onError(t: Throwable?) {
//            Log.d("messagesList", "onError" + messagesList.size)
//
//        }
//
//        override fun onCompleted() {
//            Log.d("messagesList", "onCompleted")
//        }
//    })
//}
//
//fun subscribe(grpcClient: PscrudGrpc.PscrudStub, topicName: String) {
//    val request = PscrudOuterClass.SubscribeRequest.newBuilder()
//        .setTopic(topicName)
//        .setSession(DataStore.session)
//        .build()
//
//    grpcClient.subscribe(request, object : StreamObserver<PscrudOuterClass.Response> {
//        override fun onNext(response: PscrudOuterClass.Response?) {
//            response?.ok?.let { isSuccessful ->
//                if (isSuccessful) {
////                    messagesList.add(Message("", message = "You have new message..."))
////                    Log.d("ChatGRPC", "You have new message...")
//                }
//            }
//        }
//
//        override fun onError(t: Throwable?) {
//        }
//
//        override fun onCompleted() {
//        }
//    })
//}
//
//@Composable
//fun AdapterMessagesListing(dataList: ChatModel) {
//    AdapterList(
//        data = dataList.drinks,
//        modifier = Modifier.weight(1f)
//    ) { message ->
//        val index = dataList.drinks.indexOf(message)
//        Clickable(
//            onClick = { onRowClick(message.id) },
//            modifier = Modifier.ripple()
//        ) {
//            Column(
//                modifier = Modifier.padding(16.dp, 8.dp, 16.dp, 8.dp)
//                        + Modifier.fillMaxWidth()
//            ) {
//                Text(
//                    message.message, style = TextStyle(
//                        color = Color.Black,
//                        fontSize = 16.sp,
//                        textAlign = TextAlign.Center
//                    )
//                )
//            }
//        }
//    }
//}
