// CONSTANTS AND CONFIG

/**
 * Gets the standard, non-platform specific test scripts and args.
 *
 * @param artifactName The name of the artifact we'll be testing
 * @param jenkinsPort the port to test on.
 *
 * @return a list of maps of script and args to run after installation on all distros.
 */
private List standardScripts(String artifactName, String jenkinsPort) {
  return [
      [
          "generic",
          "service-check.sh",
          "${artifactName} ${jenkinsPort}"
      ]
  ]
}

/**
 * Gets the per-platform scripts and arguments.
 *
 * @return a map with platform as key and a list of script/args maps as value.
 */
private List platformScripts(String platform) {
  def platScripts = [
      [
          "deb",
          "debian.sh",
          "installers/deb/*.deb"
      ],
      [
          "rpm",
          "centos.sh",
          "installers/rpm/*.rpm"
      ],
      [
          "suse",
          "suse.sh",
          "installers/suse/*.rpm"
      ]
  ]

  for (int i = 0; i < platScripts.size(); i++) {
    if (platScripts.get(i)?.get(0)?.equals(platform)) {
      return platScripts.get(i)
    }
  }
  return null
}

/**
 * Get information on OSes to test that belong to a given category (or all)
 *
 * @param category Category of OSes to find - if null, returns all.
 * @return A map with OS names as keys and information about those OSes (image name, platform and category) as values.
 */
private def osesToTest(String category) {
  def osDefs = [
      [
          "ubuntu-14.04",
          "sudo-ubuntu:14.04",
          "deb",
          "core"
      ],
      [
          "ubuntu-15.04",
          "sudo-ubuntu:15.04",
          "deb",
          "extended"
      ],
      [
          "debian-wheezy",
          "sudo-debian:wheezy",
          "deb",
          "extended"
      ],
      [
          "centos-6",
          "sudo-centos:6",
          "rpm",
          "core"
      ],
      [
          "centos-7",
          "sudo-centos:7",
          "rpm",
          "extended"
      ],
      [
          "opensuse-13.2",
          "sudo-opensuse:13.2",
          "suse",
          "extended"
      ]
  ]

  def matches = []
  for (int i = 0; i < osDefs.size(); i++) {
    def thisOs = osDefs.get(i)
    // We're using lists rather than maps because serializable pain.
    // Category is the 4th entry in the OS list.
    if (thisOs[3] == null || thisOs[3].equals(category)) {
      matches.add(thisOs)
    }
  }

  return matches
}

// END CONSTANTS AND CONFIG

// Replace colons in image with hyphens and append text
String convertImageNameToString(String imageName, String append="") {
    return (imageName+append).replaceAll(':','-')
}

/**
 * Extracts the components from an {@code 'artifact://full/path/to/job/buildNr#artifact.ext'} type url.
 * @param url the url
 */
@NonCPS
def getComponentsFromArtifactUrl(String url) {
    def pattern = /^artifact:\/\/([\/\w-_\. ]+)\/(\d+)\/{0,1}#([\/\w-_\.]+)$/
    def matcher = url =~ pattern
    if (matcher) {
        return [
            item: matcher.group(1),
            run: matcher.group(2),
            artifact: matcher.group(3)
        ]
    } else {
        throw new MalformedURLException("Expected format: 'artifact://full/path/to/job/buildNr#dir/artifact.ext' but got '${url}'")
    }
}

/**
 * Downloads an arifact to the workspace for further use in the flow.
 * This is a stripped down version of a CloudBees workflow utility function
 * It has been generified to use with artifacts besides jenkins.war (for packaging use)
 * 
 * Caveats:
 * Needs to run inside a node block, and does not stash the artifact (avoids issues with big artifacts)
 * For smaller artifacts, you may wish to stash them
 * @param url the url to download
 *              {@code 'artifact://' will be downloaded via CopyArtifact build step},
 *              Example: {@code 'artifact://full/path/to/job/buildNr#artifact.ext'}.
 *              Anything else will be downloaded via wget
 */
def fetchArtifact(String url) {
  if (url == null) {
    fail 'required parameter url is missing'
  } else if (url.startsWith("artifact://")) {
    echo "Fetching ${url} as artifact."
    def comp = this.getComponentsFromArtifactUrl(url)
    step([$class: 'CopyArtifact', filter: comp.artifact, projectName: comp.item, flatten: true, selector: [$class: 'SpecificBuildSelector', buildNumber: comp.run]])
  } else {
      echo "Fetching ${url} as URL file."
      sh "wget -q ${url}"
  }
}

// Pull down the artifacts, must run in a node block
def fetchInstallers(String debFileUrl, String rpmFileUrl, String suseFileUrl) {
 sh 'rm -rf installers'
 dir('installers') {
   sh 'rm -rf deb rpm suse'
   dir('deb') {
      fetchArtifact(debFileUrl)
   }
   dir('rpm') {
      fetchArtifact(rpmFileUrl)
   }
   dir('suse') {
      fetchArtifact(suseFileUrl)
   }
  }
}

/** Runs a series of shell commands inside a docker image
* The output of each command set is saved to a specific file and archived
* Errors are propagated back up the chain. 
* @param imageName docker image name to use (must support sudo, based off the sudoable images)
* @param shellCommands List of (string) shell commands to run within the container
* @param stepNames List of names for each shell command step, optional
*                    (if not supplied, then the step # will be used)
*/
def runShellTest(String imageName, def shellCommands, def stepNames=null) {
  withEnv(['HOME='+pwd()]) { // Works around issues not being able to find docker install
    def img = docker.image(imageName)
    def fileName = convertImageNameToString(imageName,"-testOutput-")
    img.inside() {  // Needs to be root for installation to work
      try {
        for(int i=0; i<shellCommands.size(); i++) {
          String cmd = shellCommands.get(i)
          def name = (stepNames != null && i < stepNames.size()) ? stepNames.get(i) : i
          
          // Workaround for two separate and painful issues
          // One, in shells, piped commands return the exit status of the last command
          // This means that errors in our actual command get eaten by the success of the tee we use to log
          // Thus, failures would get eaten and ignored. 
          // Setting pipefail in bash fixes this by returning the first nonsuccessful exit in the pipe

          // Second, the sh workflow step often will use the default posix shell
          // The default posix shell does not support pipefail, so we have to invoke bash to get it
          
          String argument = "${cmd} | tee \"testresults/${fileName}-${name}.log\""
          sh argument
        }
      } catch (Exception ex) {
        // And archive the test results once we're done.
        step([$class: 'JUnitResultArchiver', keepLongStdio: true, testResults: "results/*.xml"])
        archive("testresults/$fileName"+'*.log')
        throw ex
      }
      // And archive the test results once we're done.
      step([$class: 'JUnitResultArchiver', keepLongStdio: true, testResults: "results/*.xml"])
      archive("testresults/$fileName"+'*.log')
    }
  } 
}


/**
 * Install tests are a set of ["dockerImage:version", [shellCommand,shellCommand...]] entries
 * They will need sudo-able containers to install
 *
 * @param testOSList a list of OS information (filtered from osesToTest(category))
 * @param scriptPath the path to the scripts for replacing
 * @param artifactName The name of the artifact to test
 * @param jenkinsPort The port to run the test Jenkins on
 * @param stepNames Names for each step (if not supplied, the index of the step will be used)
*/
def executeInstallTestset(List testOSList, String scriptPath, String artifactName, String jenkinsPort, def stepNames=null) {
  // Within this node, execute our docker tests
  def parallelTests = [:]
  sh 'rm -rf testresults'
  sh 'rm -rf results'
  sh 'mkdir testresults'
  sh 'mkdir results'
  for (int i = 0; i < testOSList.size(); i++) {
    def osDef = testOSList.get(i)
    if (osDef != null) {
      // OS name is index 0 element.
      def osName = osDef.get(0)
      // Image name is index 1 element.
      def imgName = osDef.get(1)
      // OS Platform is index 2 element.
      def osPlatform = osDef.get(2)

      def tests = []

      def scriptsToRun = []
      scriptsToRun.add(platformScripts(osPlatform))
      def genericScripts = standardScripts(artifactName, jenkinsPort)

      for (int k = 0; k < genericScripts.size(); k++) {
        scriptsToRun.add(genericScripts.get(k))
      }

      for (int j = 0; j < scriptsToRun.size(); j++) {
        def scriptToRun = scriptsToRun.get(j)
        // Since we can't use Maps due to serialization fun, we're faking it with lists, so scriptToRun[0] is the "platform", while
        // scriptToRun[1] and [2] are the script name and arguments, respectively.
        tests << shellScriptForDistro(osName, scriptPath, scriptToRun[1], scriptToRun[2])
      }

      parallelTests[osName] = {
        try {
          runShellTest(imgName, tests, stepNames)
        } catch (Exception e) {
          // Keep on trucking so we can see the full failures list
          echo "${e}"
          echo("Test for ${osName} failed")
        }
      }
    }
  }

  parallel parallelTests
}

/** Runs the Jenkins installer tests
*   Note: MUST be inside a node block! 
*   Installers are in installers/deb/*.deb, installers/rpm/*.rpm, installers/suse/*.rpm
*
*  @param packagingTestBranch branch of packaging repo to use for test + docker images
*  @param artifactName jenkins artifactName
*  @param jenkinsPort port to use for speaking to jenkins (default 8080)
*/
void runJenkinsInstallTests(String packagingTestBranch='master', 
    String artifactName='jenkins', String jenkinsPort='8080', boolean runExtended=false) {
  // Set up
  String scriptPath = 'packaging-docker/installtests'
  String checkCmd = "sudo $scriptPath/service-check.sh $artifactName $jenkinsPort"

  // Run the actual work
  sh 'rm -rf packaging-docker'
  dir('packaging-docker') {
    git branch: packagingTestBranch, url: 'https://github.com/jenkinsci/packaging.git'
  }
  
  // Build the sudo dockerfiles
  stage 'Build sudo dockerfiles'
  withEnv(['HOME='+pwd()]) {
      sh 'packaging-docker/docker/build-sudo-images.sh'
  }
  
  stage 'Run Installation Tests'
  String[] stepNames = ['install', 'servicecheck']
  try {
    this.executeInstallTestset(osesToTest("core"), scriptPath, artifactName, jenkinsPort, stepNames)
    if (runExtended) {
      this.executeInstallTestset(osesToTest("extended"), scriptPath, artifactName, jenkinsPort, stepNames)  
    }
  } catch (Exception ex) {
    throw ex
  } finally {
    sh 'rm -rf installers || true'
  }
}

/** Fetch jenkins artifacts and run installer tests
*  @param dockerNodeLabel Docker node label to use to run this flow
*  @param rpmUrl, suseUrl, debUrl:  artifact URLs to fetch packes from
*/
void fetchAndRunJenkinsInstallerTest(String dockerNodeLabel, String rpmUrl, String suseUrl, String debUrl,
  String packagingTestBranch='master', String artifactName='jenkins', String jenkinsPort='8080') {

  timestampedNode(dockerNodeLabel) {
    stage 'Fetch Installer'
    this.fetchInstallers(debUrl, rpmUrl, suseUrl)

    this.runJenkinsInstallTests(packagingTestBranch, artifactName, jenkinsPort)
  }
}

/**
 * Generates a properly named, distinct to this platform and test step shell script in the workspace.
 * This is needed for sh2ju's output to actually be meaningful.
 *
 * @param distro
 * @param scriptPath
 * @param baseScript
 * @param args
 * @return the script to actually execute
 */
String shellScriptForDistro(String distro, String scriptPath, String baseScript, String args) {
    String newPath = "${scriptPath}/${distro}-${baseScript}"
    sh "cp ${scriptPath}/${baseScript} ${newPath}"
    return "sudo ${newPath} ${args}"
}

// Runs the given body within a Timestamper wrapper on the given label.
def timestampedNode(String label, Closure body) {
  node(label) {
    wrap([$class: 'TimestamperBuildWrapper']) {
      body.call()
    }
  }
}


return this
