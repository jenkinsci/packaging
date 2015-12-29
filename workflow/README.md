# How to use the installer test workflows

There are two full workflow here that may be of interest.

Workflows intended for library use include javadoc style comments for shared functions explaining parameters. 

Workflows for direct use as a full flow (from SCM) are parameterized workflows, and include a header explaining the necessary parameters. 


## installertest.groovy: shared library of functions to run dockerized tests

- Most people will want to use execute_install_testset to run a set of tests in parallel using multiple containers
- Each test starts up a slightly customized container mimicking a stripped down linux VM, with the Jenkins user set up as a sudoer
- Installation tests are structured as a series of shell commands to run, with each command run in the container (which has the workspace mounted as a docker volume)
- Caution: you can't use single quotes in your arguments, you will need to use double quotes because of how commands are passed in
- Each command may have a name set, and each command's output will be archived to testresults


## full-installertest-flow.groovy: a full test flow for testing Jenkins packaging on linux

- This contains a set of shell commands to verify jenkins installation and service behavior
- Depends on the sudo docker images
- To use this, you will need a set of built debian, rpm, and suse packages uploaded to specific URLs 
- It is quite easy to customize this workflow if packages are already built locally earlier in the flow