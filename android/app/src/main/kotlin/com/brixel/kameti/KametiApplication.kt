package com.brixel.kameti

import android.app.Activity
import android.app.Application
import android.os.Bundle
import com.brixel.kameti.ui.KConnectivity
import java.lang.ref.WeakReference

class KametiApplication : Application() {
    /** `null` when `KametiConfig.json` is missing: the app shows how to fix it. */
    val config: AppConfig? by lazy { AppConfig.load(this) }

    /** `null` without a config. */
    val container: AppContainer? by lazy { config?.let { AppContainer(it, this) { resumedActivity.get() } } }

    /** The activity on screen, to show the Google sign-in sheet from. */
    private var resumedActivity = WeakReference<Activity>(null)

    override fun onCreate() {
        super.onCreate()
        KConnectivity.start(this)
        registerActivityLifecycleCallbacks(object : ActivityLifecycleCallbacks {
            override fun onActivityResumed(activity: Activity) {
                resumedActivity = WeakReference(activity)
            }

            override fun onActivityPaused(activity: Activity) {
                if (resumedActivity.get() === activity) resumedActivity.clear()
            }

            override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) = Unit
            override fun onActivityStarted(activity: Activity) = Unit
            override fun onActivityStopped(activity: Activity) = Unit
            override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) = Unit
            override fun onActivityDestroyed(activity: Activity) = Unit
        })
    }
}
