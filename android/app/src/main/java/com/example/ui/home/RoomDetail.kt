package com.example.ui.home

import android.os.Handler
import android.text.TextUtils
import android.util.Base64
import android.util.Log
import androidx.compose.Composable
import androidx.compose.frames.ModelList
import androidx.compose.state
import androidx.ui.core.Constraints
import androidx.ui.core.Layout
import androidx.ui.core.Measurable
import androidx.ui.core.Modifier
import androidx.ui.foundation.*
import androidx.ui.foundation.shape.corner.RoundedCornerShape
import androidx.ui.graphics.Color
import androidx.ui.layout.*
import androidx.ui.material.*
import androidx.ui.material.icons.Icons
import androidx.ui.material.icons.filled.ArrowBack
import androidx.ui.text.TextStyle
import androidx.ui.text.style.TextAlign
import androidx.ui.text.style.TextDecoration
import androidx.ui.tooling.preview.Preview
import androidx.ui.unit.TextUnit
import androidx.ui.unit.dp
import androidx.ui.unit.ipx
import androidx.ui.unit.sp
import chat.Chat
import com.example.data.DataStore
import com.example.model.Message
import com.example.secure.CryptoHelper
import com.example.ui.Screen
import com.example.ui.navigateTo
import com.google.crypto.tink.Aead
import com.google.gson.Gson
import com.google.protobuf.ByteString
import grpc.PscrudGrpc
import grpc.PscrudOuterClass
import io.grpc.stub.StreamObserver
import java.nio.charset.Charset
import java.nio.charset.StandardCharsets


private var messagesList = ModelList<Message>()
private var recipient = ""
private var listMsg = mutableMapOf<String, Chat.Chit>()

@Composable
fun RoomDetail(
    roomId: String,
    grpcClient: PscrudGrpc.PscrudStub,
    mainThreadHandler: Handler
) {
    recipient = roomId
    Column(modifier = Modifier.fillMaxWidth()) {
        TopAppBar(
            title = {
                Text(text = "Room " + roomId)
            },
            navigationIcon = {
                IconButton(
                    onClick = {
                        navigateTo(Screen.Home)
                        messagesList.clear()
                    }
                ) {
                    Icon(asset = Icons.Filled.ArrowBack)
                }
            }
        )
        Surface(color = Color(0xFFfff), modifier = Modifier.weight(1f)) {
            // Center is a composable that centers all the child composables that are passed to it.
            Column(modifier = Modifier.fillMaxSize()) {
                Column(
                    modifier = Modifier.padding(16.dp, 8.dp, 16.dp, 8.dp) + Modifier.weight(
                        0.66f
                    )
                ) {
                    MessageAdapter()
                }

                Row() {
                    var message: String = ""
                    Surface(
                        color = Color.LightGray,
                        modifier = Modifier.padding(8.dp)
                                + Modifier.weight(0.66f),
                        shape = RoundedCornerShape(4.dp)
                    ) {
                        message =
                            HintEditText(modifier = Modifier.padding(16.dp) + Modifier.fillMaxWidth())
                    }
                    Button(
                        modifier = Modifier.padding(8.dp),
                        onClick = {
                            sendMsg(grpcClient, message, roomId, mainThreadHandler)
                        }
                    ) {
                        Text(
                            text = "Send",
                            style = TextStyle(fontSize = TextUnit.Sp(16))
                        )
                    }
                }
            }

        }
    }
}

@Preview
@Composable
fun previewScreen() {
    Column(modifier = Modifier.fillMaxWidth()) {
        TopAppBar(
            title = {
                Text(text = "Room ")
            },
            navigationIcon = {
                IconButton(
                    onClick = {
                        navigateTo(Screen.Home)
                        messagesList.clear()
                    }
                ) {
                    Icon(asset = Icons.Filled.ArrowBack)
                }
            }
        )
        Surface(color = Color(0xFFfff), modifier = Modifier.weight(1f)) {
            // Center is a composable that centers all the child composables that are passed to it.
            Column(modifier = Modifier.fillMaxSize()) {
                Column(
                    modifier = Modifier.padding(16.dp, 8.dp, 16.dp, 8.dp)
                            + Modifier.weight(0.66f)
                ) {
                    MessageAdapter()
                }
                Row() {
                    Surface(
                        color = Color.LightGray,
                        modifier = Modifier.padding(8.dp) +
                                Modifier.weight(0.66f),
                        shape = RoundedCornerShape(4.dp)
                    ) {
                        HintEditText(modifier = Modifier.padding(16.dp) + Modifier.fillMaxWidth())
                    }

                    Button(
                        modifier = Modifier.padding(8.dp),
                        onClick = {}
                    ) {
                        Text(
                            text = "Send",
                            style = TextStyle(fontSize = TextUnit.Sp(16))
                        )
                    }
                }
            }

        }
    }
}

@Composable
fun HintEditText(
    hintText: String = "Next Message",
    modifier: Modifier = Modifier,
    textStyle: TextStyle = currentTextStyle()
): String {
    val state = state { TextFieldValue("") }
    val inputField = @Composable {
        TextField(
            value = state.value,
            modifier = modifier,
            onValueChange = { state.value = it },
            textStyle = textStyle.merge(TextStyle(textDecoration = TextDecoration.None))
        )
    }

    Layout(
        children = @Composable {
            inputField()
            Text(
                text = hintText,
                modifier = modifier,
                style = textStyle.merge(TextStyle(color = Color.Gray))
            )
            Divider(color = Color.Black, thickness = 2.dp)
        },
        measureBlock = { measurables: List<Measurable>, constraints: Constraints, _ ->
            val inputFieldPlace = measurables[0].measure(constraints)
            val hintEditPlace = measurables[1].measure(constraints)
            val dividerEditPlace = measurables[2].measure(
                Constraints(constraints.minWidth, constraints.maxWidth, 2.ipx, 2.ipx)
            )
            layout(
                inputFieldPlace.width,
                inputFieldPlace.height + dividerEditPlace.height
            ) {
                inputFieldPlace.place(0.ipx, 0.ipx)
                if (state.value.text.isEmpty())
                    hintEditPlace.place(0.ipx, 0.ipx)
                dividerEditPlace.place(0.ipx, inputFieldPlace.height)
            }
        })
    return state.value.text
}

// Listener message from sender
fun listen(grpcClient: PscrudGrpc.PscrudStub, mainThreadHandler: Handler, aead: Aead) {
    val request = PscrudOuterClass.Request.newBuilder()
        .setSession(DataStore.session)
        .build()
    grpcClient.listen(request, object : StreamObserver<PscrudOuterClass.Publication> {
        override fun onNext(value: PscrudOuterClass.Publication?) {
            if (null != value)
                hear(value.id, Chat.Chit.parseFrom(value.data), grpcClient, mainThreadHandler, aead)
        }

        override fun onError(t: Throwable?) {
        }

        override fun onCompleted() {
        }
    })
}

private fun hear(
    id: String,
    chit: Chat.Chit,
    grpcClient: PscrudGrpc.PscrudStub,
    mainThreadHandler: Handler, aead: Aead
) {
    when (chit.what) {
        Chat.Chit.What.HANDSHAKE -> {
            receivedHandshake(chit.handshake, grpcClient, mainThreadHandler, aead)
        }
        Chat.Chit.What.ENVELOPE -> {
            mainThreadHandler.post {
                val keySet = CryptoHelper.getKeySet(chit.envelope.from)
                val secret = keySet?.let {
                    CryptoHelper.getSecretKey(it)

                }

                try {
                    Log.e("Enc", "TEXT2 " + Gson().toJson(chit.envelope.payload))
                    Log.e("Enc", "keySet2: " + Gson().toJson(secret))
                    val text =
                        "[1,75,-92,34,-74,-51,-29,-16,104,-104,-90,51,-100,120,-67,-6,-68,-124,-20,27,-17,-43,44,113,-30,94,85,-18,-61,-109,-110,103,40,-66,44,82,-29]"
                    val seCru =
                        "[-65,-103,-36,105,-66,-73,-35,37,-91,-113,122,-22,-87,-51,-86,-82,12,-33,93,1,77,-6,-125,120,-11,52,30,34,88,100,-30,125]"
                    val strDecr = aead.decrypt(
                        Gson().fromJson(text, ByteArray::class.java),
                        Gson().fromJson(seCru, ByteArray::class.java)
                    )
                    val text2 = String(strDecr, StandardCharsets.UTF_8)
                    messagesList.add(
                        Message(
                            id,
                            chit.envelope.from + " : " + text2
                        )
                    )
                } catch (e: Exception) {
                    Log.d("print", e.message)
                }

            }

        }
        Chat.Chit.What.UNRECOGNIZED -> {

        }
    }
}


fun subscribe(grpcClient: PscrudGrpc.PscrudStub, topicName: String) {
    val request = PscrudOuterClass.SubscribeRequest.newBuilder()
        .setTopic(topicName)
        .setSession(DataStore.session)
        .build()

    grpcClient.subscribe(request, object : StreamObserver<PscrudOuterClass.Response> {
        override fun onNext(response: PscrudOuterClass.Response?) {
            response?.ok?.let { isSuccessful ->
            }
        }

        override fun onError(t: Throwable?) {
        }

        override fun onCompleted() {
        }
    })
}

@Composable
fun MessageAdapter() {
    VerticalScroller {
        Column(modifier = Modifier.fillMaxWidth()) {
            messagesList.forEach {
                Column(
                    modifier = Modifier.padding(16.dp, 8.dp, 16.dp, 8.dp)
                            + Modifier.fillMaxWidth()
                ) {
                    Text(
                        it.message, style = TextStyle(
                            color = Color.Black,
                            fontSize = 16.sp,
                            textAlign = TextAlign.Center
                        )
                    )
                }
            }
        }
    }
}

fun sendMsg(
    grpcClient: PscrudGrpc.PscrudStub,
    message: String,
    recipient: String,
    mainThreadHandler: Handler
) {
    val payload = message.apply {
        if (TextUtils.isEmpty(message)) {
            Log.d("MSG", "Empty")
            return
        }
    }
    Log.d("MSG", "Empty ?")
    val envelope = Chat.Envelope.newBuilder().setFrom(DataStore.username)
        .setPayload(ByteString.copyFromUtf8(payload))
        .setTo(recipient)
        .build()

    val chit = Chat.Chit.newBuilder().setWhat(Chat.Chit.What.ENVELOPE)
        .setEnvelope(envelope)
        .build()
    try {
        listMsg.put(recipient, chit)
        sendHandshake(grpcClient, recipient, mainThreadHandler)
    } catch (e: Exception) {
    }
}

private fun sendHandshake(
    grpcClient: PscrudGrpc.PscrudStub,
    recipient: String,
    mainThreadHandler: Handler
) {
    val keySend = CryptoHelper.getKeySendTo(recipient)
    val handshake = Chat.Handshake.newBuilder()
        .setFrom(DataStore.username)
        .setSigning(ByteString.copyFrom(keySend.signing))
        .setAgreement(ByteString.copyFrom(keySend.agreement))
        .build()
    val chit = Chat.Chit.newBuilder()
        .setWhat(Chat.Chit.What.HANDSHAKE)
        .setHandshake(handshake)
        .build()
    try {
        sendData(grpcClient, recipient, chit.toByteString(), mainThreadHandler)
    } catch (e: Exception) {

    }
}

private fun sendConfirmHandshake(
    grpcClient: PscrudGrpc.PscrudStub,
    keyConfirm: CryptoHelper.KeySend,
    senderID: String,
    mainThreadHandler: Handler
) {
    val handshake = Chat.Handshake.newBuilder()
        .setFrom(DataStore.username)
        .setSigning(ByteString.copyFrom(keyConfirm.signing))
        .setAgreement(ByteString.copyFrom(keyConfirm.agreement))
        .build()
    val chit = Chat.Chit.newBuilder()
        .setWhat(Chat.Chit.What.HANDSHAKE)
        .setHandshake(handshake)
        .build()
    try {
        sendData(grpcClient, senderID, chit.toByteString(), mainThreadHandler)
    } catch (e: Exception) {

    }
}

private fun sendData(
    grpcClient: PscrudGrpc.PscrudStub,
    recipient: String,
    data: ByteString,
    mainThreadHandler: Handler
) {

    val request = PscrudOuterClass.PublishRequest.newBuilder()
        .setTopic(recipient)
        .setSession(DataStore.session)
        .setData(data)
        .build()

    grpcClient.publish(request, object : StreamObserver<PscrudOuterClass.Response> {
        override fun onNext(response: PscrudOuterClass.Response?) {
            Log.d("MSG", response?.ok.toString())
            response?.ok?.let { isSuccessful ->

            }
        }

        override fun onError(t: Throwable?) {
            Log.d("MSG", "onError")
        }

        override fun onCompleted() {
            Log.d("MSG", "onCompleted")
        }
    })

}

private fun receivedHandshake(
    handshake: Chat.Handshake, grpcClient: PscrudGrpc.PscrudStub,
    mainThreadHandler: Handler,
    aead: Aead
) {
    val peer = handshake.from
    val signing = CryptoHelper.signing(handshake)
    val agreement = CryptoHelper.agreement(handshake)
    val keySendConfirm = CryptoHelper.KeySend(signing.toByteArray(), agreement.toByteArray())
    try {
        if (listMsg.size == 0) {
            CryptoHelper.set(keySendConfirm, peer)
            sendConfirmHandshake(grpcClient, keySendConfirm, peer, mainThreadHandler)
        } else {
            Log.d("FFF", "1111")
            if (CryptoHelper.set(keySendConfirm, peer)) {
                sendConfirmHandshake(grpcClient, keySendConfirm, peer, mainThreadHandler)
            }
            val keySet = CryptoHelper.getKeySet(handshake.from)
            listMsg.get(peer)?.let {
                val pStr =
                    ByteString.copyFromUtf8(it.envelope.payload.toStringUtf8())
                val msg = aead.encrypt(
                    pStr.toByteArray(), CryptoHelper.getSecretKey(keySet!!)
                )
                Log.e("Enc", "TEXT1 " + Gson().toJson(msg))
                Log.e("Enc", "keySet1: " + Gson().toJson(CryptoHelper.getSecretKey(keySet)))

                val envelope = Chat.Envelope.newBuilder().setFrom(DataStore.username)
                    .setPayload(ByteString.copyFrom(msg))
                    .setTo(recipient)
                    .build()

                val chit = Chat.Chit.newBuilder().setWhat(Chat.Chit.What.ENVELOPE)
                    .setEnvelope(envelope)
                    .build()

                // Sen data
                sendData(grpcClient, peer, chit.toByteString(), mainThreadHandler)
                // update message of sender to UI
                mainThreadHandler.post {
                    messagesList.add(
                        Message(
                            peer,
                            it.envelope.from + " : " + it.envelope.payload.toStringUtf8()
                        )
                    )
                }
                // Remove message sended
                listMsg.remove(peer)
            }
        }


    } catch (e: java.lang.Exception) {
    }
}



