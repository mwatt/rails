desc "Restart app by touching tmp/restart.txt"
task :restart do
  Rake.application.invoke_task(:add_tmp_if_missing)
  FileUtils.touch('tmp/restart.txt')
end

task :add_tmp_if_missing do
  FileUtils.mkdir_p('tmp')
end
