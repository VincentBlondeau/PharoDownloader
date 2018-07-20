"
This class  allow to run external (OS) processes for the Pharo Launcher.
It hides some complexity to the Launcer.
OSProcess is used on Linux and OS X, while ProcessWrapper is used on Windows (OSProcess hangs on some processes on Windows and the Launcher becomes unusable).
"
Class {
	#name : #PhDProcessWrapper,
	#superclass : #Object,
	#instVars : [
		'process'
	],
	#category : #'PharoDownloader-Core'
}

{ #category : #'instance creation' }
PhDProcessWrapper class >> command: aCommand [ 
	^ Smalltalk os isWindows
			ifTrue: [ self windowsCommand: aCommand ]
			ifFalse: [ OSProcess command: aCommand ]
]

{ #category : #testing }
PhDProcessWrapper class >> isCommandAvailable: aCommand [
	Smalltalk os isWindows
		ifTrue: [ Smalltalk
				at: #ProcessWrapper
				ifPresent: [ :processWrapperClass | 
					^ (processWrapperClass new
						useStderr;
						waitForExit;
						startWithShellCommand: aCommand;
						yourself) stderrStream atEnd ].
			^ false ].
	^ (OSProcess waitForCommand: aCommand) succeeded
]

{ #category : #'instance creation' }
PhDProcessWrapper class >> waitForCommand: aCommand [ 
	^ self new
		process: ((Smalltalk os isWindows and: [ Smalltalk includesKey: #ProcessWrapper ])
			ifTrue: [ self waitForWindowsCommand: aCommand ]
			ifFalse: [ self waitForLinuxCommand: aCommand ]);
		yourself
]

{ #category : #'instance creation' }
PhDProcessWrapper class >> waitForLinuxCommand: aCommand [ 
	^ OSProcess waitForCommand: aCommand
]

{ #category : #'instance creation' }
PhDProcessWrapper class >> waitForWindowsCommand: commandString [
	| process success |
	process := (Smalltalk at: #ProcessWrapper) new.
	success := process startWithShellCommand: commandString.
	success ifFalse: [
		self error: 'command ', commandString ,' failed' ].

	success := process waitForExit.
	success ifFalse: [
		self error: 'command ', commandString ,' failed' ].
	
	process exitCode = 0 ifFalse: [
		self error: 'command ', commandString ,' failed' ].

	^ process
]

{ #category : #'instance creation' }
PhDProcessWrapper class >> windowsCommand: aCommand [
	" Run the command in the background so that the process returns immediately. 
	It prevents the process to be finalized by ProcessWrapper before the image beiing launched!.
	More information on START: https://ss64.com/nt/start.html"
	^ (Smalltalk at: #ProcessWrapper) new
		startWithShellCommand: 'START /B ', aCommand;
		yourself
]

{ #category : #accessing }
PhDProcessWrapper >> exitCode [
	^ Smalltalk os isWindows
		ifTrue: [ process exitCode ] 
		ifFalse: [ process exitStatus ]
]

{ #category : #private }
PhDProcessWrapper >> process: aProcessWrapper [ 
	process := aProcessWrapper
]

{ #category : #testing }
PhDProcessWrapper >> succeeded [
	^ Smalltalk os isWindows
		ifTrue: [ process isRunning not and: [ process exitCode == 0 ] ] 
		ifFalse: [ process succeeded ]
]
