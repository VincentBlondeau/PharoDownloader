Class {
	#name : #BaselineOfPharoDownloader,
	#superclass : #BaselineOf,
	#category : #BaselineOfPharoDownloader
}

{ #category : #baselines }
BaselineOfPharoDownloader >> baseline: spec [
	<baseline>
	spec
		for: #common
		do: [ spec
				project: 'OSProcess'
					with: [ spec
						className: #ConfigurationOfOSProcess;
						versionString: #stable;
						loads: #('Core with Output');
						repository: 'http://www.squeaksource.com/MetacelloRepository' ];
				project: 'ProcessWrapper'
					with: [ spec
						className: #ConfigurationOfProcessWrapper;
						versionString: #bleedingEdge;
						loads: #('Core');
						repository: 'http://smalltalkhub.com/mc/hernan/ProcessWrapper/main/' ].
			spec
				package: #PharoDownloader with: [ spec requires: #('OSProcess' 'ProcessWrapper') ];
				package: #'PharoDownloader-Tests' with: [ spec requires: #(#PharoDownloader) ].
			spec group: 'Default' with: #(#'PharoDownloader' #'PharoDownloader-Tests') ]
]
