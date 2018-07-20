"
I present a simple interface to an HTTP library.

My semaphore takes care of error handling when multiple downloads occur in parallel.
"
Class {
	#name : #PhDDownloadManager,
	#superclass : #Object,
	#instVars : [
		'errors',
		'semaphore'
	],
	#classVars : [
		'Default'
	],
	#category : #'PharoDownloader-Core'
}

{ #category : #accessing }
PhDDownloadManager class >> default [
	^ Default ifNil: [ self setDefault: self new ]
]

{ #category : #action }
PhDDownloadManager class >> reset [
	Default := nil
]

{ #category : #accessing }
PhDDownloadManager class >> setDefault: aDownloadManager [
	^ Default := aDownloadManager
]

{ #category : #private }
PhDDownloadManager >> displayProgressDuring: workBlock [
	"Inform user about download progression"

	UIManager default
		informUserDuring: [ :bar | 
			workBlock
				on: HTTPProgress
				do: [ :progress | 
					bar label: progress printString.
					progress isEmpty
						ifFalse: [ bar current: progress percentage ].
					progress resume ] ]
]

{ #category : #action }
PhDDownloadManager >> download: url toFile: destinationFile [
	destinationFile ensureDelete. "ensure download will not fail if zip file already exists"
	self displayProgressDuring: [ (self newHTTPClientForUrl: url) downloadTo: destinationFile ]
]

{ #category : #private }
PhDDownloadManager >> downloadFailureForUrl: url [
	semaphore critical: [ errors add: url ].
	PhDDownloadError signalUrl: url
]

{ #category : #action }
PhDDownloadManager >> downloadToPositionableStream: url mimeType: mimeType [
	"Unfortunately, Zinc (and HTTP in general) doesn't support positionable streams so well. So we have to get the whole content as a collection and stream over it."

	| client content |
	client := (self newHTTPClientForUrl: url)
		beOneShot;
		accept: mimeType;
		enforceAcceptContentType: true.
	self displayProgressDuring: [ content := client get ].
	^ content readStream
]

{ #category : #initialization }
PhDDownloadManager >> initialize [
	super initialize.
	semaphore := Semaphore forMutualExclusion.
	errors := OrderedCollection new asValueHolder.
	self reset
]

{ #category : #private }
PhDDownloadManager >> newHTTPClientForUrl: url [
	^ ZnClient new
		signalProgress: true;
		url: url;
		enforceHttpSuccess: true;
		ifFail: [ :exception | self downloadFailureForUrl: url ];
		yourself
]

{ #category : #accessing }
PhDDownloadManager >> numberOfErrors [
	^ errors size
]

{ #category : #action }
PhDDownloadManager >> reset [
	errors removeAll
]

{ #category : #announcements }
PhDDownloadManager >> whenErrorAddedDo: aBlock [
	errors whenChangedDo: aBlock 

]
