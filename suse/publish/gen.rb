#!/usr/bin/ruby
# generate index.html to list up debian packages

productName=ENV['PRODUCTNAME'] || "Jenkins"
artifactName=ENV['ARTIFACTNAME'] || "jenkins"
url=ENV['SUSE_URL']

puts <<-EOS
<html>
<head> 
  <title>openSUSE Repository for #{productName}</title> 
  <style> 
    TH { font-weight: bold; }
    #rpms { border-spacing:3em 0em; margin-top:2em; }
  </style> 
</head>
<body>
<h1>openSUSE Linux RPM packages for #{productName}</h1>
<p>
To use this repository, run the following command:

<pre style="padding:0.5em; margin:1em; background:black; color:white">
sudo zypper addrepo -f #{url}/ #{artifactName}
</pre>

<p>
You will need to explicitly install a Java runtime environment, because Oracle's Java RPMs are incorrect and fail to register as providing a java dependency. 
Thus, adding an explicit dependency requirement on Java would force installation of the OpenJDK JVM.

<ul>
  <li>2.54 (2017-04) and newer: Java 8</li>
  <li>1.612 (2015-05) and newer: Java 7</li>
</ul>

<p>
With that set up, the #{productName} package can be installed with <tt>zypper install #{artifactName}</tt>

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
list_packages(ENV['SUSEDIR'],"*.rpm",".")


puts "</body></html>"

