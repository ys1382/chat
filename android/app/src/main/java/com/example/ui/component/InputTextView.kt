package com.example.ui.component

import androidx.compose.Composable
import androidx.compose.getValue
import androidx.compose.setValue
import androidx.compose.state
import androidx.ui.core.Modifier
import androidx.ui.foundation.Text
import androidx.ui.foundation.TextFieldValue
import androidx.ui.graphics.Color
import androidx.ui.layout.fillMaxWidth
import androidx.ui.layout.padding
import androidx.ui.material.FilledTextField
import androidx.ui.unit.dp

@Composable
fun FilledTextInputComponent(lable: String, placeholder: String): String {
    var textValue by state { TextFieldValue("") }
    FilledTextField(
        value = textValue,
        onValueChange = { textValue = it },
        label = { Text(lable) },
        placeholder = { Text(placeholder) },
        modifier = Modifier.padding(16.dp) + Modifier.fillMaxWidth(),
        activeColor = Color.Gray
    )
    return textValue.text
}