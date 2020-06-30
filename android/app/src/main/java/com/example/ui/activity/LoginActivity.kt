package com.example.myapplication

import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.text.TextUtils
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.compose.Composable
import androidx.ui.core.Alignment
import androidx.ui.core.Modifier
import androidx.ui.core.setContent
import androidx.ui.foundation.Box
import androidx.ui.foundation.ContentGravity
import androidx.ui.foundation.Image
import androidx.ui.foundation.Text
import androidx.ui.graphics.Color
import androidx.ui.layout.*
import androidx.ui.material.MaterialTheme
import androidx.ui.material.OutlinedButton
import androidx.ui.res.imageResource
import androidx.ui.res.stringResource
import androidx.ui.text.TextStyle
import androidx.ui.text.font.FontWeight
import androidx.ui.tooling.preview.Preview
import androidx.ui.unit.dp
import androidx.ui.unit.sp
import com.example.application.MyApplication
import com.example.data.DataStore
import com.example.db.UserRepository
import com.example.demojetpackcompose.R
import com.example.model.User
import com.example.ui.activity.MainActivity
import com.example.ui.component.FilledTextInputComponent
import com.example.ui.lightThemeColors
import grpc.PscrudGrpc
import grpc.PscrudOuterClass
import io.grpc.stub.StreamObserver

class LoginActivity : AppCompatActivity() {

    lateinit var grpcClient: PscrudGrpc.PscrudStub
    lateinit var dbLocal: UserRepository
    lateinit var mainThreadHandler: Handler
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val appContainer = (application as MyApplication).container
        grpcClient = appContainer.grpcClient
        dbLocal = appContainer.dbLocal
        mainThreadHandler = appContainer.mainThreadHandler
        val username = dbLocal.allUser()
        username?.let {
            if (username.size > 0) {
                onLoginSuccessful(username.get(0).firstName!!, username.get(0).session!!)
            }
        }
        setContent {
            MyApp()
        }
    }

    @Composable
    fun MyApp() {
        MaterialTheme(
            colors = lightThemeColors
        ) {
            AppContent()
        }
    }

    @Composable
    fun AppContent() {
        Row(modifier = Modifier.fillMaxSize()) {
            Column(modifier = Modifier.fillMaxSize()) {
                Spacer(Modifier.preferredHeight(24.dp))

                val image = imageResource(R.drawable.phone)
                val imageModifier = Modifier
                    .preferredSize(100.dp)
                Box(
                    modifier = Modifier.fillMaxWidth(),
                    gravity = ContentGravity.Center,
                    children = {
                        Text(
                            text = stringResource(R.string.title_app),
                            style = TextStyle(fontSize = 30.sp, fontWeight = FontWeight.Bold)
                        )
                    })

                Container(Modifier.fillMaxWidth(), alignment = Alignment.TopCenter) {
                    Image(image, imageModifier)
                }

                val userName = FilledTextInputComponent("Username", "")
                val pwd = FilledTextInputComponent("Password", "")

                Row() {

                    OutlinedButton(
                        onClick = {
                            if (validateInput(userName, pwd))
                                login(userName, pwd, dbLocal)
                        },
                        modifier = Modifier.padding(16.dp) + Modifier.weight(1f)
                    ) {
                        Text(
                            text = "Login",
                            color = Color.Blue,
                            modifier = Modifier.padding(16.dp, 8.dp, 16.dp, 8.dp)
                        )
                    }

                    OutlinedButton(
                        onClick = {
                            if (validateInput(userName, pwd))
                                register(userName, pwd)
                        },
                        modifier = Modifier.padding(16.dp) + Modifier.weight(1f)
                    ) {
                        Text(
                            text = "Register",
                            color = Color.Blue,
                            modifier = Modifier.padding(16.dp, 8.dp, 16.dp, 8.dp)
                        )
                    }
                }

            }

        }

//        remember {
//            lifecycle.addObserver(LifecycleEventObserver { _, event ->
//                if (event == Lifecycle.Event.ON_RESUME) {
//                }
//            })
//        }
    }

    fun validateInput(username: String, pwd: String): Boolean {
        if (TextUtils.isEmpty(username)) {
            Toast.makeText(
                this@LoginActivity,
                "Username cannot be blank",
                Toast.LENGTH_LONG
            ).show()
            return false
        } else if (TextUtils.isEmpty(pwd)) {
            Toast.makeText(
                this@LoginActivity,
                "Password cannot be blank",
                Toast.LENGTH_LONG
            ).show()
            return false
        }
        return true
    }

    fun login(username: String, pwd: String, dbLocal: UserRepository) {
        val request = PscrudOuterClass.AuthRequest.newBuilder()
            .setUsername(username)
            .setPassword(pwd)
            .build()

        grpcClient.login(request, object : StreamObserver<PscrudOuterClass.AuthResponse> {
            override fun onNext(response: PscrudOuterClass.AuthResponse?) {
                response?.ok?.let { isSuccessful ->
                    if (isSuccessful) {
                        onLoginSuccessful(username, response.session)
                    } else {
                        onShowMsg("Something went wrong")
                    }
                }
            }

            override fun onError(t: Throwable?) {
                onShowMsg("Something went wrong")
            }

            override fun onCompleted() {
            }
        })
    }

    fun register(username: String, pwd: String) {
        val request = PscrudOuterClass.AuthRequest.newBuilder()
            .setUsername(username)
            .setPassword(pwd)
            .build()

        grpcClient.register(request, object : StreamObserver<PscrudOuterClass.AuthResponse> {
            override fun onNext(response: PscrudOuterClass.AuthResponse?) {
                response?.ok?.let { isSuccessful ->
                    if (isSuccessful) {
                        onLoginSuccessful(username, response.session)
                    } else {
                        onShowMsg("Something went wrong")

                    }
                }
            }

            override fun onError(t: Throwable?) {
                onShowMsg("Something went wrong")
            }

            override fun onCompleted() {
            }
        })
    }

    fun onLoginSuccessful(username: String, session: String) {
        // remove User
        dbLocal.deleteAllUser()
        // update user for db
        val user = User()
        user.firstName = username
        user.session = session
        dbLocal.insertUser(user)

        DataStore.session = session
        DataStore.username = username
        startActivity(Intent(this@LoginActivity, MainActivity::class.java))
        finish()
    }

    fun onShowMsg(message: String) {
        mainThreadHandler.post {
            Toast.makeText(this@LoginActivity, message, Toast.LENGTH_SHORT).show()
        }
    }

    @Preview
    @Composable
    fun previewLoginScreen() {
        MyApp()
    }
}






