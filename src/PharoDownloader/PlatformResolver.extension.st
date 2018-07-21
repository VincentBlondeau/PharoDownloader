Extension { #name : #PlatformResolver }

{ #category : #'*PharoDownloader' }
PlatformResolver >> launcherUserFilesLocation [
	"Where to put the user files (images, virtual machines) for the pharo launcher"
	^ self documents / 'Pharo'
]

{ #category : #'*PharoDownloader' }
PlatformResolver >> vmExecutableName [
	self subclassResponsibility
]
