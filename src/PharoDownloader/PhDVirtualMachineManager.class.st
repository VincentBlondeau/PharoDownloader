"
I'm in charge of selecting the appropriate Virtual Machine for a given image. If the required virtual machine is not found on disk, I will download it from http://files.pharo.org.
I determine the VM to use by reading the image file header.
"
Class {
	#name : #PhDVirtualMachineManager,
	#superclass : #Object,
	#instVars : [
		'imageFile',
		'imageFormatNumber',
		'imageVersion'
	],
	#classVars : [
		'VMStore'
	],
	#category : #'PharoDownloader-Core'
}

{ #category : #unzipping }
PhDVirtualMachineManager class >> canUseSytemZip [
	^ PhDProcessWrapper isCommandAvailable: 'unzip'
]

{ #category : #'instance creation' }
PhDVirtualMachineManager class >> forImage: aPharoImagePathOrFileReference [
	^ self new 
		imageFile: aPharoImagePathOrFileReference asFileReference;
		yourself
		
		
]

{ #category : #accessing }
PhDVirtualMachineManager class >> imageFormat32bits [
	^ 6521
]

{ #category : #accessing }
PhDVirtualMachineManager class >> imageFormat64bits [
	^ 68021
]

{ #category : #querying }
PhDVirtualMachineManager class >> imageFormatNumberFromFile: anImagePath [
	| imageFile |
	imageFile := anImagePath asFileReference.
	imageFile exists ifFalse: [
		self error: imageFile fullName, ' does not exist.' ].
	^ imageFile binaryReadStreamDo: [ :stream | self imageFormatNumberFromStream: stream ].

]

{ #category : #private }
PhDVirtualMachineManager class >> imageFormatNumberFromStream: aStream [
	| number |
	number := aStream nextLittleEndianNumber: 4.
	aStream close.
	^ number
]

{ #category : #accessing }
PhDVirtualMachineManager class >> imageFormatPreSpur [
	^ 6505
]

{ #category : #testing }
PhDVirtualMachineManager class >> is32bits: anImageFormatVersion [
	"32 bits Spur image format"

	^ anImageFormatVersion = self imageFormat32bits
]

{ #category : #testing }
PhDVirtualMachineManager class >> is64bits [
	^ PhDVirtualMachineManager is64bits: Smalltalk image imageFormatVersion
]

{ #category : #testing }
PhDVirtualMachineManager class >> is64bits: anImageFormatVersion [
	"64 bits Spur image format"

	^ anImageFormatVersion = self imageFormat64bits
]

{ #category : #testing }
PhDVirtualMachineManager class >> isPreSpur: anImageFormatVersion [
	"Pre-Spur image format"

	^ anImageFormatVersion = self imageFormatPreSpur
]

{ #category : #unzipping }
PhDVirtualMachineManager class >> pharoUnzip: aZipFileReference to: outputDirectory [
	UIManager default informUserDuring: 
		[ :bar | 
		ZipArchive new
			readFrom: aZipFileReference;
			extractAllTo: outputDirectory informing: bar overwrite: true ]
	
]

{ #category : #settings }
PhDVirtualMachineManager class >> settingsOn: aBuilder [
	<systemsettings>
	<pharoLauncherSettings>
	(aBuilder setting: #vmStoreString)
		label: 'VMs Directory' translated;
		type: #Directory;
		parent: #pharoLauncher;
		target: self;
		order: 50;
		default: (PlatformResolver forCurrentPlatform launcherUserFilesLocation / 'vms');
		description:
			'Path to the directory containing all the VMs to launcher your Pharo images.' , String cr
				, 'You must have the read/write rights on this folder.' , String cr
				, 'NOTE: This path might need to escape some whitespace characters e.g. "/Pharo\ 3.0/Pharo".' translated
]

{ #category : #unzipping }
PhDVirtualMachineManager class >> systemUnzip: aZipFileReference to: outputDirectory [
	PhDProcessWrapper 
		waitForCommand: 'unzip -o -d "' , outputDirectory fullName, '" "', aZipFileReference fullName, '"'.
]

{ #category : #unzipping }
PhDVirtualMachineManager class >> unzip: aZipFileReference to: outputDirectory [
	outputDirectory ensureCreateDirectory.
	self canUseSytemZip
		ifTrue: [ self systemUnzip: aZipFileReference to: outputDirectory ]
		ifFalse: [ self pharoUnzip: aZipFileReference to: outputDirectory ]
]

{ #category : #accessing }
PhDVirtualMachineManager class >> vmStore [
	^ VMStore ifNil: [ VMStore := (PlatformResolver forCurrentPlatform launcherUserFilesLocation / 'vms') ensureCreateDirectory ]
]

{ #category : #accessing }
PhDVirtualMachineManager class >> vmStore: anObject [
	VMStore := anObject asFileReference.
	VMStore ensureCreateDirectory
]

{ #category : #accessing }
PhDVirtualMachineManager class >> vmStoreString [
	" Used to display a nice file url in settings browser"
	^ self vmStore pathString 
]

{ #category : #accessing }
PhDVirtualMachineManager class >> vmStoreString: aFileUrl [
	" Used to display a nice file url in settings browser"
	self vmStore: aFileUrl

]

{ #category : #querying }
PhDVirtualMachineManager >> availableVirtualMachines [
	^ self availableVirtualMachinesIn: self vmStore
]

{ #category : #querying }
PhDVirtualMachineManager >> availableVirtualMachinesByImageFormat [
	^ self availableVirtualMachinesOnDiskByImageFormat
		at: Smalltalk vm imageVersionNumber asString
			ifAbsentPut: [(PhDVirtualMachine directory: Smalltalk vmBinary parent asFileReference)];
		yourself
]

{ #category : #private }
PhDVirtualMachineManager >> availableVirtualMachinesIn: aFileReference [
	| vmsOnDisk |
	vmsOnDisk := Dictionary new.
	aFileReference ensureCreateDirectory.
	aFileReference directories
		reject: [ :entry | entry basename = 'private' ]
		thenDo: [ :entry | | vm |
			vm := PhDVirtualMachine directory: entry.
			vm ifValid: [ vmsOnDisk at: entry basename put: vm ] ].
	^ vmsOnDisk
]

{ #category : #querying }
PhDVirtualMachineManager >> availableVirtualMachinesOnDiskByImageFormat [
	^ [ self availableVirtualMachinesIn: self privateVmStore] 
		on: PhDExecutableNotFoundError 
		do: [ :ex |  ex path asFileReference ensureDeleteAll. ex retry ]
]

{ #category : #private }
PhDVirtualMachineManager >> checkImageArchitecture [
	"Only warn on 64-bit Linux"
	Smalltalk os isUnix64 ifFalse: [ ^ self ]. 
	
	" Most OS are now 64-bits. Do not warn if a Pharo Launcher 32-bit tries to run a 64-bit image. "	
	(self class is64bits and: [ self class is32bits: self imageFormatNumber ])
		ifTrue: [ PhDArchitectureMismatchWarning signalLauncherArch: '64-bit' imageArch: '32-bit' ]
]

{ #category : #private }
PhDVirtualMachineManager >> compatibleVm [
	"Do not get the exact VM for the given image but only an image able to run the image to get its version number"

	^ self availableVirtualMachinesByImageFormat
		at: self imageFormatNumber asString
		ifAbsent: [ | vmPath |
			self fetchCompatibleVm.
			vmPath := self availableVirtualMachinesByImageFormat at: self imageFormatNumber asString ]
]

{ #category : #private }
PhDVirtualMachineManager >> compatibleVmUrl [
	^ self compatibleVmUrls at: self imageFormatNumber
]

{ #category : #private }
PhDVirtualMachineManager >> compatibleVmUrls [
	"50-preSpur stable is not the latest stable pre-Spur VM. 40 vm is the latest stable pre-Spur"
	^ Dictionary newFromPairs: { 
		self class imageFormatPreSpur . self vmUrlTemplate format: { '40' . '' . self downloadPathOSTypeSegment . 'stable' } .
		self class imageFormat32bits . self vmUrlTemplate format: { '70' . '' . self downloadPathOSTypeSegment . 'stable' } .
		self class imageFormat64bits . self vmUrlTemplate format: { '70' . '64' . self downloadPathOSTypeSegment . 'stable' }
	}
]

{ #category : #private }
PhDVirtualMachineManager >> downloadPathOSTypeSegment [
	| os |
	os := Smalltalk os.
	(os isMacOS or: [ os isMacOSX ]) ifTrue: [ ^ 'mac' ].	
	os isUnix ifTrue: [ ^ 'linux' ].
	os isWindows ifTrue: [ ^ 'win' ].

]

{ #category : #private }
PhDVirtualMachineManager >> fetchCompatibleVm [
	[ | targetFile | 
	targetFile := self privateVmStore / (self imageFormatNumber asString , '.zip').
	PhDDownloadManager default 
		download: self compatibleVmUrl
		toFile: targetFile.
	self class
		unzip: targetFile
		to: (self privateVmStore / self imageFormatNumber asString) ]
	on: KeyNotFound
	do: [ self error: 'No Virtual Machine available for ' , self imageFormatNumber asString, ' image format. Maybe you need to update known formats?' ]
]

{ #category : #private }
PhDVirtualMachineManager >> fetchSourcesFiles [
	| previousVersion |
	"Do not download sources for Pharo versions > 70 as they come along with the image."
	self imageVersion asInteger >= 70
		ifTrue: [ ^ self ].
	self fetchSourcesFilesFor: self imageVersion.
	"Images for alpha/beta versions (Pharo < 70) require sources for the previous version of Pharo"
	previousVersion := self imageVersion asNumber - 10.
	"But the previous version for 61 is 50, not 51"
	self imageVersion = '61'
		ifTrue: [ previousVersion := 50 ].
	"Pharo 1.0 does not exists: 2.0 => 1.4 => 1.3 => 1.2 => 1.1"
	self imageVersion = '20'
		ifTrue: [ previousVersion := 14 ].
	previousVersion < 10
		ifTrue: [ previousVersion := previousVersion + 9 ]. "bad - 10, should have done -1"
	self fetchSourcesFilesFor: previousVersion asString
]

{ #category : #private }
PhDVirtualMachineManager >> fetchSourcesFilesFor: anImageVersionString [
	[ | vmFolder sourcesZip |
	vmFolder := (self availableVirtualMachines at: self vmFileName) vmFolder.
	sourcesZip := vmFolder / ('sourcesV' , anImageVersionString , '.zip').
	PhDDownloadManager default
		download: (self sourcesFileUrlFor: anImageVersionString)
		toFile: sourcesZip.
	self class
		unzip: sourcesZip
		to: vmFolder ]
		on: KeyNotFound
		do: [ self error: 'No Sources file available for ' , anImageVersionString , ' image.' ]
]

{ #category : #private }
PhDVirtualMachineManager >> fetchVm [
	[ | targetFile | 
	targetFile := self vmStore / (self vmFileName , '.zip').
	PhDDownloadManager default 
		download: self vmUrl
		toFile: targetFile.
	self class
		unzip: targetFile
		to: (self vmStore / self vmFileName) ]
	on: KeyNotFound
	do: [ self error: 'No Virtual Machine available for ' , self imageVersion , ' image.' ]
]

{ #category : #accessing }
PhDVirtualMachineManager >> imageFile: anImagePathOrFileReference [
	imageFile := anImagePathOrFileReference asFileReference
]

{ #category : #accessing }
PhDVirtualMachineManager >> imageFormatNumber [
	^ imageFormatNumber
		ifNil: [ imageFormatNumber := self class imageFormatNumberFromFile: imageFile ]
]

{ #category : #accessing }
PhDVirtualMachineManager >> imageFormatNumber: anInteger [ 
	imageFormatNumber := anInteger
]

{ #category : #accessing }
PhDVirtualMachineManager >> imageVersion [
	"get the Pharo version of the image"

	^ imageVersion ifNil: 
		[ [ self imageVersionFromFile ]
			on: PhDImageVersionDeterminationError
			do: [ "no version file, generate it"
					[ self imageVersionFromFileWith: self imageVersionCommand ]
						on: PhDImageVersionDeterminationError
						do: [ "Command probably failed, try to run without --no-default-preferences option (not available in Pharo 2)"
								self imageVersionFromFileWith: (self imageVersionCommandWithPreferences: true) ] ] ]
]

{ #category : #accessing }
PhDVirtualMachineManager >> imageVersion: aString [ 
	imageVersion := aString
]

{ #category : #accessing }
PhDVirtualMachineManager >> imageVersionCommand [
	^ self imageVersionCommandWithPreferences: false
]

{ #category : #accessing }
PhDVirtualMachineManager >> imageVersionCommandWithPreferences: shouldUsePreferences [
	^ String
		streamContents: [ :stream | 
			stream << 'cd "' << self compatibleVm executableFolderPath << '" && '.
			Smalltalk os isUnix
				ifTrue: [ stream << 'export SQUEAK_PLUGINS="" && ' ].
			stream << $" << self compatibleVm executablePath << $"
				<<
					(Smalltalk os isUnix
						ifTrue: [ ' --nodisplay ' ]
						ifFalse: [ ' --headless ' ]) << $"
				<< imageFile fullName utf8Encoded asString
				<< '" '.
			shouldUsePreferences ifFalse: [ stream << '--no-default-preferences ' ].
			stream
				<< 'eval '
				<< $"	<< self imageVersionFileCreationInstructions << $" ]
]

{ #category : #private }
PhDVirtualMachineManager >> imageVersionFile [
	^ imageFile parent / self imageVersionFileName
]

{ #category : #private }
PhDVirtualMachineManager >> imageVersionFileCreationInstructions [
	"Pharo 6 images >= 60509 need 61 VM, even though the image states 60"
	^ '(Smalltalk imagePath asFileReference parent) / ''{1}'' 
		writeStreamDo: [ :stream | |major minor|
			major := SystemVersion current major.
			minor := SystemVersion current minor.
			(major = 6 and: [ SystemVersion current highestUpdate >= 60509 ])
				ifTrue: [ minor := 1 ].
			stream 
				<< major asString;
				<< minor asString ]'
		format: { self imageVersionFileName }
]

{ #category : #private }
PhDVirtualMachineManager >> imageVersionFileName [
	^ 'pharo.version'
]

{ #category : #accessing }
PhDVirtualMachineManager >> imageVersionFromFile [
	self imageVersionFile 
			readStreamDo: [ :stream | imageVersion := stream contents asInteger asString ]
			ifAbsent: [ PhDImageVersionDeterminationError signal: 
				('Cannot determine image version: image version file "{1}" not found!' format: { self imageVersionFile pathString }) ].
	^ imageVersion
]

{ #category : #accessing }
PhDVirtualMachineManager >> imageVersionFromFileWith: commandString [
	PhDProcessWrapper waitForCommand: commandString.
	self imageVersionFile 
			readStreamDo: [ :stream | imageVersion := stream contents asInteger asString ]
			ifAbsent: [ PhDImageVersionDeterminationError signalCommand: commandString ].
	^ imageVersion
]

{ #category : #private }
PhDVirtualMachineManager >> privateVmStore [
	"The private store is used to fetch one VM per image format and open image to determine their pharo version number (e.g. 6.0, 7.0, etc.). Then we download the latest stable VM for the given Pharo image version."
	^ (self vmStore / 'private') ensureCreateDirectory
]

{ #category : #accessing }
PhDVirtualMachineManager >> sourcesFileUrlFor: anImageVersionString [
	"$1: IMAGE_VERSION"
	^ 'https://files.pharo.org/get-files/{1}/sources.zip'
		format: {anImageVersionString}
]

{ #category : #querying }
PhDVirtualMachineManager >> vm [
	| vm |
	UIManager default
		informUserDuring: [ :bar | 
			bar label: 'Determining Image version'.
			vm := self availableVirtualMachines 
				at: self vmFileName 
				ifAbsent: 
					[ bar 
						label: 'Fetching VM to run Pharo ', self imageVersion , ' images';
						current: 25.
					self fetchVm.
					vm := self availableVirtualMachines at: self vmFileName.
					bar 
						label: 'Fetching sources files for Pharo ', self imageVersion;
						current: 50.
					self fetchSourcesFiles.
					bar 
						label: 'Running the image';
						current: 100.
					vm ]. ].
	^ vm executablePath
]

{ #category : #accessing }
PhDVirtualMachineManager >> vmFileName [
	| architecture pharoVersion |
	self checkImageArchitecture.
	architecture := (self class is64bits: self imageFormatNumber)
		ifTrue: [ 'x64' ]
		ifFalse: [ 'x86' ].
	pharoVersion  := ((self class isPreSpur: self imageFormatNumber) and: [ self imageVersion = '50' ])
		ifTrue: [ '50-preSpur' ]
		ifFalse: [ self imageVersion ].
	^ pharoVersion , '-' , architecture.
]

{ #category : #accessing }
PhDVirtualMachineManager >> vmStore [
	^ self class vmStore
]

{ #category : #private }
PhDVirtualMachineManager >> vmUrl [
	| architecture pharoVersion |
	architecture := (self class is64bits: imageFormatNumber) ifTrue: [ '64' ] ifFalse: [ '' ].
	pharoVersion  := ((self class isPreSpur: imageFormatNumber) and: [ self imageVersion = '50' ])
		ifTrue: [ '50-preSpur' ]
		ifFalse: [ self imageVersion ].
	^ self vmUrlTemplate
		format: { pharoVersion . architecture . self downloadPathOSTypeSegment . 'stable' }
]

{ #category : #private }
PhDVirtualMachineManager >> vmUrlTemplate [
	"$1: IMAGE_VERSION
	 $2: VM_ARCH
	 $3: OS
	 $4: VM_STATUS"
	^ 'https://files.pharo.org/get-files/{1}/pharo{2}-{3}-{4}.zip'
]
