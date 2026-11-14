package com.brixel.kameti

import com.brixel.kameti.domain.KametiDependencies

/** A release build has no sample data: it always talks to the real backend. */
internal fun demoDependencies(): KametiDependencies? = null
