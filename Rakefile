require 'bundler/setup'

require 'nanoc3/tasks'

namespace :assets do
  desc "Copies fonts to the output folder"
  task :fonts do
    FileUtils.mkdir_p "output/assets/fonts"
    FileUtils.cp_r "fonts/.", "output/assets/fonts"
  end
end
