Extension { #name : #UnixResolver }

{ #category : #'*PharoDownloader' }
UnixResolver >> launcherUserFilesLocation [
	"Documents folder is not a standard on Unix. Put files in the $HOME directory"
	^ self home / 'Pharo'
]

{ #category : #'*PharoDownloader' }
UnixResolver >> vmExecutableName [
	^ 'pharo'
]
