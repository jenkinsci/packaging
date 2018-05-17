#!/usr/bin/ruby
# generate index.html to list up debian packages

productName=ENV['PRODUCTNAME'] || "Jenkins"
artifactName=ENV['ARTIFACTNAME'] || "jenkins"
organization=ENV['ORGANIZATION'] || "jenkins.io"
url=ENV['DEB_URL']

puts <<-EOS
<html>
<head>
  <title>Debian Repository for #{productName}</title>
  <style>
    TH { font-weight: bold; }
    #debs { border-spacing:3em 0em; margin-top:2em; }
  </style>
</head>
<body>
<h1>#{productName} Debian packages</h1>
<p>
This is the Debian package repository of #{productName} to automate installation and upgrade.

To use this repository, first add the key to your system:

<pre style="padding:0.5em; margin:1em; background-color:black; color:white">
wget -q -O - <a href="#{organization}.key" style="color:white">#{url}/#{organization}.key</a> | sudo apt-key add -
</pre>

Then add the following entry in your <tt>/etc/apt/sources.list</tt>:

<pre style="padding:0.5em; margin:1em; background-color:black; color:white">
deb #{url} binary/
</pre>
</p>

<p>
Note that Jenkins currently requires a Java 8 JRE. Check <a href="https://issues.jenkins-ci.org/browse/JENKINS-40689">JENKINS-40689</a>
for more details about Jenkins and Java 9 incompatibility.
</p>

<p>
If you wish to use Oracle's Java 8 JRE with this .deb package, we recommend that you do the following (adjust accordingly if you need a 32bit JRE):
<ol>
  <li>apt-get install java-package</li>
  <li>Download the Oracle Java SE Runtime Environment 8 .tar.gz file for Linux from <a href="http://www.oracle.com/technetwork/java/javase/downloads/index.html">http://www.oracle.com/technetwork/java/javase/downloads/index.html</a></li>
  <li>Build a .deb package from the downloaded JRE: make-jpkg jre-8u181-linux-x64.tar.gz</li>
  <li>Install the Oracle .deb package: dpkg -i oracle-java8-jre_8u181_amd64.deb</li>
  <li>Finally, add the jenkins repository as above and apt-get install jenkins</li>
</ol>
</p>

<p>
If you wish to use some JRE other than OpenJDK 8 or Oracle Java SE Runtime Environment 8, install it as you would normally and create a .deb package that satisfies Jenkins' requirements:
<ol>
  <li>apt-get install equivs</li>
  <li>cat << EOF > jenkins-suitable-java8-jre.control
Package: jenkins-suitable-java8-jre
Description: A fake JRE to satisfy Jenkins' packaging
 A package, which can be installed to satisfy the Jenkins' JRE dependency
 when you have a locally installed suitable JRE.

EOF
</li>
  <li>equivs-build jenkins-suitable-java8-jre.control</li>
  <li>dpkg -i jenkins-suitable-java8-jre_1.0_all.deb</li>
  <li>Finally, add the jenkins repository as above and apt-get install jenkins</li>
</ol>
</p>

<p>
<ul>
  <li>2.54 (2017-04) and newer: Java 8</li>
  <li>1.612 (2015-05) and newer: Java 7</li>
</ul>
</p>

<p>
Update your local package index, then finally install #{productName}:

<pre style="padding:0.5em; margin:1em; background-color:black; color:white">
sudo apt-get update
sudo apt-get install #{artifactName}
</pre>
</p>

<p>
See <a href="http://wiki.jenkins-ci.org/display/JENKINS/Installing+Jenkins+on+Ubuntu">Wiki</a> for more information, including notes regarding upgrade from Hudson.
</p>


<h2>Individual Package Downloads</h2>
<p>
If you need *.deb for a specific version, use these.
<table id=debs>
<tr>
  <th>Name</th>
  <th>Last modified</th>
  <th>Size</th>
</tr>
EOS

$: << ENV['BASE']+"/bin"
require 'list-packages.rb'
list_packages(ENV['DEBDIR'],"*.deb","binary")

puts "</body></html>"

