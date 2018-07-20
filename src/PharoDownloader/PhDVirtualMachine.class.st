"
I represent a Pharo virtual machine that can be used to run image.

executableRef is a reference to the script/binary to actually use to launch images.
vmBinaryRef is a reference to the vm binary (not a bash file).
"
Class {
	#name : #PhDVirtualMachine,
	#superclass : #Object,
	#instVars : [
		'executableRef',
		'vmBinaryRef'
	],
	#classVars : [
		'VMStore'
	],
	#category : #'PharoDownloader-Core'
}

{ #category : #accessing }
PhDVirtualMachine class >> directory: aFileReference [
	^ self new 
		initializeOn: aFileReference;
		yourself 
]

{ #category : #accessing }
PhDVirtualMachine class >> elfMagicNumber [
	^ ByteArray newFrom: #(127 69 76 70)
]

{ #category : #querying }
PhDVirtualMachine class >> executableName [
	^ PlatformResolver forCurrentPlatform vmExecutableName
]

{ #category : #ensuring }
PhDVirtualMachine >> ensureIsExecutable: aPath [
	"Unzipping with Pharo does not preserve unix rights and so, the pahro VM executable does not have the execution permission.
	We have to set it explicitely on Unix and OS X."
	Smalltalk os isWindows 
		ifFalse: 	[ PhDProcessWrapper waitForCommand: 'chmod u+x ' , aPath utf8Encoded asString ]
]

{ #category : #setting }
PhDVirtualMachine >> executable: aPathOrfileReference [
	executableRef := aPathOrfileReference asFileReference
]

{ #category : #accessing }
PhDVirtualMachine >> executableFolderPath [
	^ executableRef parent fullName utf8Encoded asString
]

{ #category : #accessing }
PhDVirtualMachine >> executablePath [
	^ executableRef fullName utf8Encoded asString
]

{ #category : #testing }
PhDVirtualMachine >> ifValid: aBlockClosure [ 
	(executableRef isNotNil and: [ vmBinaryRef isNotNil ])
		ifTrue: [ aBlockClosure value ]
]

{ #category : #intialization }
PhDVirtualMachine >> initializeOn: aFolder [
	| executables |
	executables := aFolder allChildrenMatching: self class executableName.
	Smalltalk os isUnix
		ifTrue: [ executables select: #isFile thenDo: [ :fileRef | self ensureIsExecutable: fileRef fullName ].
			"On linux, either the VM exe is at the top level or a bash script at the top level has to be used"
			executableRef := executables
				detect: [ :fileRef | fileRef parent = aFolder ]
				ifNone: [ PhDExecutableNotFoundError signalKind: 'executable' inPath: aFolder fullName ].
			vmBinaryRef := executables
				detect: [ :fileRef | fileRef binaryReadStreamDo: [ :stream | (stream next: 4) = self class elfMagicNumber ] ]
				ifNone: [ PhDExecutableNotFoundError signalKind: 'VM binary' inPath: aFolder fullName ] ]
		ifFalse:
			[ executableRef := vmBinaryRef := executables detect: #isFile ifNone: [ PhDExecutableNotFoundError signalKind: 'executable' inPath: aFolder fullName ] ].
	self ensureIsExecutable: executableRef fullName
]

{ #category : #setting }
PhDVirtualMachine >> vmBinary: aPathOrFileReference [
	vmBinaryRef := aPathOrFileReference asFileReference
]

{ #category : #accessing }
PhDVirtualMachine >> vmFolder [
	^ vmBinaryRef parent
]

{ #category : #accessing }
PhDVirtualMachine >> vmFolderPath [
	^ self vmFolder fullName utf8Encoded asString
]
