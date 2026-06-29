# frozen_string_literal: true

ENV["VAGRANT_DEFAULT_PROVIDER"] ||= "virtualbox"

Vagrant.configure("2") do |config|
  build_disk = File.expand_path("build/opencloud-freebsd-builder-data.vdi", __dir__)
  build_disk_mb = ENV.fetch("FREEBSD_BUILD_DISK_MB", "262144")
  vagrant_key = File.expand_path("build/vagrant-insecure-private-key", __dir__)
  bundled_key = Dir[File.expand_path("/opt/vagrant/embedded/gems/gems/vagrant-*/keys/vagrant")].sort.last

  if bundled_key && !File.exist?(vagrant_key)
    require "fileutils"
    FileUtils.mkdir_p(File.dirname(vagrant_key))
    FileUtils.cp(bundled_key, vagrant_key)
    File.chmod(0600, vagrant_key)
  end

  config.vm.box = ENV.fetch("FREEBSD_BOX", "j0sch7/freebsd-15.1-builder")
  config.vm.box_version = ENV.fetch("FREEBSD_BOX_VERSION", ">= 15.1.2")
  config.vm.hostname = "opencloud-freebsd-builder"
  config.ssh.username = "vagrant"
  config.ssh.insert_key = false
  config.ssh.private_key_path = vagrant_key
  config.ssh.shell = "/bin/sh"
  config.ssh.sudo_command = "sudo %c"
  config.vm.boot_timeout = 300
  config.vm.graceful_halt_timeout = 30
  config.vm.communicator = "ssh"

  config.vm.synced_folder ".", "/vagrant", disabled: true
  config.vm.network "forwarded_port", guest: 22, host: 2222, id: "ssh", auto_correct: false

  config.vm.provider "virtualbox" do |vb|
    vb.cpus = ENV.fetch("FREEBSD_CPUS", "8").to_i
    vb.memory = ENV.fetch("FREEBSD_MEMORY", "6144").to_i
    unless File.exist?(build_disk)
      vb.customize ["createmedium", "disk", "--filename", build_disk, "--size", build_disk_mb, "--format", "VDI"]
    end
    vb.customize [
      "storageattach", :id,
      "--storagectl", "SATA Controller",
      "--port", "1",
      "--device", "0",
      "--type", "hdd",
      "--medium", build_disk
    ]
  end

  config.vm.provision "file",
    source: "scripts/box-provision.sh",
    destination: "/tmp/box-provision.sh"
  config.vm.provision "shell",
    privileged: true,
    inline: "/bin/sh /tmp/box-provision.sh"
end
