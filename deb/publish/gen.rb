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
You will need to explicitly install a Java runtime environment, because Java 9 does not work with Jenkins, this is the safest way to
ensure your system ends properly configured. Adding an explicit dependency requirement on Java could force installation
of undesired versions of the JVM.
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

