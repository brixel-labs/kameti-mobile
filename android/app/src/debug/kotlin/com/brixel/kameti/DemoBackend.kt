package com.brixel.kameti

import com.brixel.kameti.domain.KametiDependencies
import com.brixel.kameti.testsupport.SampleData

/** The demo flavor's sample kametis (`android/scripts/use-env.sh demo`). Debug builds only. */
internal fun demoDependencies(): KametiDependencies? = SampleData.dependencies()
