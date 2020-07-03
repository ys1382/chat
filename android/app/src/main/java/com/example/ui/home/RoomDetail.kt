package com.example.ui.home

import android.os.Handler
import android.text.TextUtils
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
import com.example.db.UserRepository
import com.example.model.Message
import com.example.secure.CryptoHelper
import com.example.secure.TinkPbe
import com.example.ui.Screen
import com.example.ui.navigateTo
import com.google.gson.Gson
import com.google.protobuf.ByteString
import grpc.PscrudGrpc
import grpc.PscrudOuterClass
import io.grpc.stub.StreamObserver


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
fun listen(grpcClient: PscrudGrpc.PscrudStub, mainThreadHandler: Handler, dbLocal: UserRepository) {
    val request = PscrudOuterClass.Request.newBuilder()
        .setSession(DataStore.session)
        .build()
    grpcClient.listen(request, object : StreamObserver<PscrudOuterClass.Publication> {
        override fun onNext(value: PscrudOuterClass.Publication?) {

            if (null != value) {

                hear(
                    value.id,
                    Chat.Chit.parseFrom(value.data),
                    grpcClient,
                    mainThreadHandler,
                    dbLocal
                )
            }

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
    mainThreadHandler: Handler, dbLocal: UserRepository
) {
    when (chit.what) {
        Chat.Chit.What.HANDSHAKE -> {
            receivedHandshake(chit.handshake, grpcClient, mainThreadHandler, dbLocal)
        }
        Chat.Chit.What.ENVELOPE -> {

            mainThreadHandler.post {
                val keySet = CryptoHelper.getKeySet(chit.envelope.from)
                val secret = keySet?.let {
                    CryptoHelper.getSecretKey(it)
                }
                Log.e("Enc", "peer: receive envelop" + Gson().toJson(keySet))
                try {
                    val strDecr = TinkPbe.decrypt(chit.envelope.payload.toStringUtf8(), secret)
                    messagesList.add(
                        Message(
                            id,
                            chit.envelope.from + " : "
                                    + strDecr.substringAfterLast("contents=\"").replace("\">", "")
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
            return
        }
    }
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
    if (CryptoHelper.checkHandShaked(recipient)) {
        Log.e("Enc", "Send Message imtermadiate")
        sendMessage(recipient, grpcClient, mainThreadHandler)
        return
    }
    val keySend = CryptoHelper.getKeySendTo(recipient)
    Log.e("Enc", "sendHandshake " + Gson().toJson(keySend.agreement))
    val handshake = Chat.Handshake.newBuilder()
        .setFrom(DataStore.username)
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
    keyConfirm: ByteArray,
    senderID: String,
    mainThreadHandler: Handler
) {
    val handshake = Chat.Handshake.newBuilder()
        .setFrom(DataStore.username)
        .setAgreement(ByteString.copyFrom(keyConfirm))
        .build()
    val chit = Chat.Chit.newBuilder()
        .setWhat(Chat.Chit.What.HANDSHAKE)
        .setHandshake(handshake)
        .build()
    try {
        sendDataAfterHandshake(grpcClient, senderID, chit.toByteString(), mainThreadHandler)
    } catch (e: Exception) {

    }
}

private fun sendDataAfterHandshake(
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
            Log.d("Enc", response?.ok.toString())
            response?.ok?.let { isSuccessful ->

            }
        }

        override fun onError(t: Throwable?) {
            Log.d("Enc", "onError")
        }

        override fun onCompleted() {
            Log.d("Enc", "onCompleted")
        }
    })

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
            Log.d("Enc", response?.ok.toString())
            response?.ok?.let { isSuccessful ->

            }
        }

        override fun onError(t: Throwable?) {
            Log.d("Enc", "onError")
        }

        override fun onCompleted() {
            Log.d("Enc", "onCompleted")
        }
    })

}

private fun receivedHandshake(
    handshake: Chat.Handshake, grpcClient: PscrudGrpc.PscrudStub,
    mainThreadHandler: Handler, dbLocal: UserRepository
) {
    val peer = handshake.from
    if (CryptoHelper.set(handshake.agreement.toByteArray(), peer, dbLocal)) {
        Log.e("Enc", "peer: resend handshake to " + peer)
        val keyResendConfirm = CryptoHelper.getKeySet(peer)!!.ourAgreement
        //for receiver resend handshake to Sender
        sendConfirmHandshake(grpcClient, keyResendConfirm, peer, mainThreadHandler)
    } else {
        Log.e("Enc", "peer: send envelop to " + peer)
        // for listen hanshake success from Receiver
        sendMessage(peer, grpcClient, mainThreadHandler)
    }

}

private fun sendMessage(
    peer: String, grpcClient: PscrudGrpc.PscrudStub,
    mainThreadHandler: Handler
) {
    val keySet = CryptoHelper.getKeySet(peer)
    val secret = keySet?.let {
        CryptoHelper.getSecretKey(it)
    }
    listMsg.get(peer)?.let {

        val msg = TinkPbe.encrypt(it.envelope.payload.toString(), secret)
        Log.e("Enc", "Msg send : " + Gson().toJson(keySet))

        val envelope = Chat.Envelope.newBuilder().setFrom(DataStore.username)
            .setPayload(ByteString.copyFromUtf8(msg))
            .setTo(peer)
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



