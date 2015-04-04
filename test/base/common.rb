# -*- mode: ruby -*-
# vim: set ft=ruby ts=2 sts=2 sw=2 :

def box(config,name,image)
  config.vm.define(name) do |node|
    node.vm.box = image
    node.vm.provision :shell, path:"#{name}.sh"
  end

  config.push.define "atlas" do |push|
    push.app = "kohsuke/#{name}-java"
  end
end
