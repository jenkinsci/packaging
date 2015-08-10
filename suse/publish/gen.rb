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

