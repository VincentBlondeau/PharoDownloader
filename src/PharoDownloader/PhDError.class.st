"
I represent a generic error encountered by the pharo downloader
"
Class {
	#name : #PhDError,
	#superclass : #Error,
	#category : #'PharoDownloader-Exceptions'
}

{ #category : #accessing }
PhDError >> longDescription [
	^ self subclassResponsibility
]

{ #category : #accessing }
PhDError >> name [
	^ self subclassResponsibility
]

{ #category : #ui }
PhDError >> uiAlert [
	UIManager default
		alert: self longDescription
		title: self name
]
