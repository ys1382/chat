package com.example.db

import com.example.model.User
import kotlinx.coroutines.Deferred

/**
 * Created by toand on 10/16/2017.
 */
class UserLocalDataSource(val mUserDAO: UserDAO) :
    UserDataSource {

    companion object {
        private var sInstance: UserLocalDataSource? = null
        fun getInstance(userDAO: UserDAO?): UserLocalDataSource? {
            if (sInstance == null) {
                sInstance = UserLocalDataSource(userDAO!!)
            }
            return sInstance
        }
    }

    override fun getUserByUserId(userId: Int): User? {
        return mUserDAO.getUserByUserId(userId)
    }

    override fun getUserByName(userName: String?): User? {
        return mUserDAO.getUserByName(userName)
    }

    override fun allUser(): MutableList<User>? {
        return mUserDAO.allUser()
    }

    override fun insertUser(users: User) {
        return mUserDAO.insertUser(users)
    }

    override fun deleteUser(user: User) {
        return mUserDAO.deleteUser(user)
    }

    override fun deleteAllUser() {
        return mUserDAO.deleteAllUser()
    }

    override fun updateUser(user: User) {
        return mUserDAO.updateUser(user)
    }
}