desc "Restart app by touching tmp/restart.txt"
task :restart do
  unless File.directory?('tmp')
    Dir::mkdir('tmp')
  end
  FileUtils.touch('tmp/restart.txt')
end
