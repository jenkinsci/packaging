#!/usr/bin/ruby
# generate index.html to list up debian packages

productName=ENV['PRODUCTNAME'] || "Jenkins"
artifactName=ENV['ARTIFACTNAME'] || "jenkins"
organization=ENV['ORGANIZATION'] || "jenkins-ci.org"
url=ENV['RPM_URL']

puts <<-EOS
<html>
<!-- generated. do not manually edit -->
<head> 
  <title>RedHat Repository for #{productName}</title> 
  <style> 
    TH { font-weight: bold; }
    #rpms { border-spacing:3em 0em; margin-top:2em; }
  </style> 
</head>
<body>
<h1>RedHat Linux RPM packages for #{productName}</h1>
<p>
To use this repository, run the following command:

<pre style="padding:0.5em; margin:1em; background:black; color:white">
sudo wget -O /etc/yum.repos.d/#{artifactName}.repo #{url}/#{artifactName}.repo
sudo rpm --import #{url}/#{organization}.key
</pre>

<p>
If you've previously imported the key from Jenkins, the "rpm --import" will fail because
you already have a key. Please ignore that and move on.

<p>
With that set up, the #{productName} package can be installed with:

<pre style="padding:0.5em; margin:1em; background:black; color:white">
yum install #{artifactName}
</pre>

<p>
See <a href="https://wiki.jenkins-ci.org/display/JENKINS/Installing+Jenkins+on+Red+Hat+distributions">Wiki</a> for more information, including how #{productName} is run and where the configuration is stored, etc.

<h2>Individual Package Downloads</h2>
<p>
If you need *.rpm for a specific version, use these.
<table id=rpms>
<tr>
  <th>Name</th>
  <th>Last modified</th>
  <th>Size</th>
</tr>
EOS

$: << ENV['BASE']+"/bin"
require 'list-packages.rb'
list_packages(ENV['RPMDIR'],"*.rpm",".")

puts "</body></html>"

