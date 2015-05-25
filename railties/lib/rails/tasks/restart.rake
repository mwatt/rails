desc "Restart app by touching tmp/restart.txt"
task :restart do
  Dir.mkdir('tmp') unless File.directory('tmp')
  FileUtils.touch('tmp/restart.txt')
end
