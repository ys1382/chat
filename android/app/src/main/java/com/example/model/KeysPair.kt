package com.example.model

import androidx.room.ColumnInfo
import androidx.room.Embedded
import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "keys")
class KeysPair {
    @PrimaryKey(autoGenerate = true)
    private var mId = 0

    @ColumnInfo(name = "private_key")
    var privateKey: String? = null

    @ColumnInfo(name = "pub_key")
    var pub_key: String? = null


    fun getmId(): Int {
        return mId
    }

    fun setmId(mId: Int) {
        this.mId = mId
    }

}