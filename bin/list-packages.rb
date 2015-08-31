# generate index.html to list packages
require 'time'
require 'rubygems'
require 'net/sftp' # gem install net-sftp
                   # apt-get install libopenssl-ruby1.8

# generate a list of packages as a table
def list_packages(path,glob,rel)
	# user name and server name
	u,s=ENV['PKGSERVER'].split("@")

    Net::SFTP.start(s,u) do |sftp|
        debs = [];
        sftp.dir.glob(path,glob) { |f| debs << f }
        
        p=/^[^_-]+/
        
        debs.sort {|x,y| y.name.gsub(p,"")<=>x.name.gsub(p,"")}.each do |f|
            puts "<tr><td><a href='#{rel}/#{f.name}'>#{f.name}</a></td>"
            
            t=Time.at(f.attributes.mtime).strftime('%Y/%m/%d')
            mb = ((f.attributes.size/(1024.0*1024))*10).floor/10.0
            puts "<td>#{t}</td><td>#{mb}M</td></tr>"
        end
    end
    puts "</table>"
end
