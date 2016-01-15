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
def run_shell_test(String imageName, def shellCommands, def stepNames=null) {
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
          
          String argument = 'bash -c \'set -o pipefail; '+cmd+" | tee \"testresults/$fileName-$name"+'.log'+'" \''
          sh argument
        }
      } catch (Exception ex) {
        archive("testresults/$fileName"+'*.log')
        throw ex
      }
      archive("testresults/$fileName"+'*.log')
    }
  } 
}


/** Install tests are a set of ["dockerImage:version", [shellCommand,shellCommand...]] entries
* They will need sudo-able containers to install
* @param stepNames Names for each step (if not supplied, the index of the step will be used)
*/
def execute_install_testset(def coreTests, def stepNames=null) {
  // Within this node, execute our docker tests
  def parallelTests = [:]
  sh 'rm -rf testresults'
  sh 'mkdir testresults'
  for (int i=0; i<coreTests.size(); i++) {
    def imgName = coreTests[i][0]
    def tests = coreTests[i][1]
    parallelTests[imgName] = {
      try {
       run_shell_test(imgName, tests, stepNames)
      } catch(Exception e) {
        // Keep on trucking so we can see the full failures list
        echo "$e"
        error("Test for $imgName failed")
      }
    }
  }
  parallel parallelTests
}

return this
