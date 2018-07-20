"
Error thrown when Pharo Launcher did not succeed to find a Pharo binary or executable inside a given folder.
Probably, the folder should be deleted as the VM are only cached
"
Class {
	#name : #PhDExecutableNotFoundError,
	#superclass : #PhDError,
	#instVars : [
		'path',
		'kindOfApplication'
	],
	#category : #'PharoDownloader-Exceptions'
}

{ #category : #signalling }
PhDExecutableNotFoundError class >> signalKind: aKindOfApp inPath: aString [
	^ self new
		kindOfApplication: aKindOfApp;
		path: aString;
		signal
]

{ #category : #accessing }
PhDExecutableNotFoundError >> kindOfApplication: string [
	kindOfApplication := string
]

{ #category : #accessing }
PhDExecutableNotFoundError >> longDescription [
	^ 'Cannot detect Pharo ', kindOfApplication ,' in ', path, '.', String cr, 'Delete the folder and retry! It can also be due to a corruption of the downloaded file...'
]

{ #category : #accessing }
PhDExecutableNotFoundError >> name [
	^ 'Pharo Executable Not Found'
]

{ #category : #accessing }
PhDExecutableNotFoundError >> path [
	^ path
]

{ #category : #accessing }
PhDExecutableNotFoundError >> path: string [
	path := string
]
