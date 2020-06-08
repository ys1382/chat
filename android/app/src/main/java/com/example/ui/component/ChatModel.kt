package com.example.ui.component

import androidx.compose.Model
import androidx.compose.frames.ModelList
import com.example.model.Message
data class ChatModel(
    var drinks: ModelList<Message>
)