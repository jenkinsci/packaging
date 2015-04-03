#!/usr/bin/ruby
# Windows enforces four-component version number, so this maps 4 digit version number in Jenkins like 1.424.0.1 to 3 digits by combining the last 2.
v=ARGV[0]
x=v.split(".")
if (x.length<=2)
	puts v
else
	v = x[0..1].join(".")+"."+String(Integer(x[2])*1000+Integer(x[3]||0)*10);
	puts v;
end
	
  
