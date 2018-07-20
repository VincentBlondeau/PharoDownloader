"
I represent download errors.
"
Class {
	#name : #PhDDownloadError,
	#superclass : #PhDError,
	#instVars : [
		'url'
	],
	#category : #'PharoDownloader-Exceptions'
}

{ #category : #signalling }
PhDDownloadError class >> signalUrl: anUrl [
	^ self new
		setUrl: anUrl;
		signal
]

{ #category : #accessing }
PhDDownloadError >> longDescription [
	^ 'Error downloading ', (url printStringLimitedTo: 100)
]

{ #category : #accessing }
PhDDownloadError >> name [
	^ 'network error'
]

{ #category : #initialization }
PhDDownloadError >> setUrl: anUrl [	
	url := anUrl
]
