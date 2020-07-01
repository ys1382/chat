package com.example.db

import com.example.model.User
import kotlinx.coroutines.Deferred

interface UserDataSource {
    fun getUserByUserId(userId: Int): User?
    fun getUserByName(userName: String?): User?
    fun allUser(): MutableList<User>?
    fun insertUser(users: User)
    fun deleteUser(user: User)
    fun deleteAllUser()
    fun updateUser(users: User)
}