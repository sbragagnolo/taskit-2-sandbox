helpers
trackInstancesOf: aClass during: aBlock

	| before |
	
	5 timesRepeat: [
		Smalltalk garbageCollect.
		100 milliSeconds wait ].
	
	before := aClass allInstances size.
	
	aBlock value.
	
	5 timesRepeat: [
		Smalltalk garbageCollect.
		100 milliSeconds wait ].
	
	self assert: before equals: aClass allInstances size.