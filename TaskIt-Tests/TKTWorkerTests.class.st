Class {
	#name : #TKTWorkerTests,
	#superclass : #TKTTestCase,
	#category : 'TaskIt-Tests-Worker'
}

{ #category : #tests }
TKTWorkerTests >> testWorkerExceptionIsHandledByExceptionHandler [

	| error worker |
	worker := TKTWorker new.
	worker exceptionHandler: (TKTTestExceptionHandler new).
	worker start.
	
	error := Error new.
	worker schedule: [ error signal ].
	
	"We wait until the error is signaled, trapped and we have it."
	100 milliSeconds wait.
	self assert: worker exceptionHandler error equals: error
]

{ #category : #tests }
TKTWorkerTests >> testWorkerProcessDiesAfterStop [

	| worker future |
	worker := TKTWorker new.
	worker start.
	worker stop.
	future := TKTFuture doing: [ [ worker isRunning ] whileTrue: [ 50 milliSeconds wait ] ].
	future synchronizeTimeout: 2 seconds.
	self deny: worker isRunning
]

{ #category : #tests }
TKTWorkerTests >> testWorkerProcessDiesAfterWorkerAndAllFuturesAreCollected [
	| worker future process waitFuture1 waitFuture2 |
	worker := TKTWorker new.
	worker start.
	process := worker process.
	
	waitFuture1 := TKTFuture doing: [ [ process isRunning ] whileTrue: [ 50 milliSeconds wait ] ].
	waitFuture2 := TKTFuture doing: [ [ process isRunning ] whileTrue: [ 50 milliSeconds wait ] ].
	
	future := worker future: [ 10 milliSeconds wait ].
	
	
	worker := nil.
	Smalltalk garbageCollect.
	self should: [waitFuture1 synchronizeTimeout: 200 milliSeconds] raise: TKTTimeoutException.
	self assert: process isRunning.
	
	future := nil.
	Smalltalk garbageCollect.
	waitFuture2 synchronizeTimeout: 400 milliSeconds.
	
	self deny: process isRunning.
]

{ #category : #tests }
TKTWorkerTests >> testWorkerProcessDiesAfterWorkerIsCollected [
	| worker future process |
	worker := TKTWorker new.
	worker start.
	process := worker process.
	worker := nil.
	7 timesRepeat: [ Smalltalk garbageCollect ].
	future := TKTFuture doing: [ [ process isRunning ] whileTrue: [ 50 milliSeconds wait ] ].
	future synchronizeTimeout: 2 seconds.
	self deny: process isRunning
]

{ #category : #tests }
TKTWorkerTests >> testWorkerProcessIsWorkingUntilAllTasksAreDone [
	| worker process waitFuture |
	
	self timeLimit: 10 minutes. 
	worker := TKTWorker new.
	worker start.
	process := worker process.
	waitFuture := TKTFuture doing: [ [ process isRunning ] whileTrue: [ 50 milliSeconds wait ] ].
	worker schedule: [ 100 milliSeconds wait ].
	self assert: process taskQueue size equals: 1.
	50 milliSeconds wait.
	self assert: process taskQueue size equals: 0.
	worker := nil.
	Smalltalk garbageCollect.
	50 milliSeconds wait.
	Smalltalk garbageCollect.
	self assert: process taskQueue size equals: 0.
	self assert: process isRunning.
	waitFuture waitForCompletion: 10 second.
	self deny: process isRunning
]

{ #category : #tests }
TKTWorkerTests >> testWorkerRunsAlwaysInSameProcess [

	| worker hash futures hashes |
	worker := TKTWorker new.
	worker start.
	
	futures := (1 to: 10) collect: [ :i | worker future: [ hash := Processor activeProcess identityHash ] ].
	hashes := futures collect: [ :each | each synchronizeTimeout: 1 hour ].
	
	self assert: hashes asSet size equals: 1
]

{ #category : #tests }
TKTWorkerTests >> testWorkerRunsInSeparateProcess [

	| worker hash future |
	worker := TKTWorker new.
	worker start.
	
	future := worker future: [ hash := Processor activeProcess identityHash ].
	future waitForCompletion: 1 hour.
	
	self assert: hash ~= Processor activeProcess identityHash.
]