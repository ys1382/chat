package com.example.db

import androidx.room.*
import com.example.model.User

@Dao
interface UserDAO {
    @Query("SELECT * FROM users WHERE id = :userId")
    fun getUserByUserId(userId: Int): User?

    @Query("SELECT * FROM users WHERE first_name LIKE :userName")
    fun getUserByName(userName: String?): MutableList<User>?

    @Query("SELECT * FROM users")
    fun allUser(): MutableList<User>?

    @Insert
    fun insertUser(users: User)

    @Delete
    fun deleteUser(user: User)

    @Query("DELETE FROM users")
    fun deleteAllUser()

    @Update
    fun updateUser(users: User?)
}