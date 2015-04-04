* `spec/*_spec.rb`: tests written with serverspec. They run on your hosts, ssh into VirtualBox and inspect the state.
* `provision`:  shell scripts that `vagrant provision` runs inside VirtualBox to install packages.
* `base`: build base images. Packages that are being tested get installed on them.