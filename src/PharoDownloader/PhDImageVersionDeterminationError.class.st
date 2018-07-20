"
Error thrown when Pharo Launcher did not succeed to determine the Pharo version of the image to launch.
Probably, the run command failed.
I hold the command run to determoine the version so that it can be reused for debugging purposes.
"
Class {
	#name : #PhDImageVersionDeterminationError,
	#superclass : #PhDError,
	#instVars : [
		'command'
	],
	#category : #'PharoDownloader-Exceptions'
}

{ #category : #signalling }
PhDImageVersionDeterminationError class >> signalCommand: aCommandString [
	^ self new
		setCommand: aCommandString;
		signal
]

{ #category : #accessing }
PhDImageVersionDeterminationError >> longDescription [
	^ 'Cannot determine image version: image version file not found!' , String cr,
	'Try to run this command in a shell to get more information on the problem:', String cr,
	command 
]

{ #category : #accessing }
PhDImageVersionDeterminationError >> name [
	^ 'Image version determination error'
]

{ #category : #initialization }
PhDImageVersionDeterminationError >> setCommand: aCommandString [
	command := aCommandString reject: [ :c | c = Character cr ] "easier to run the copy/pasted command in a shell if command has only one line"
]
