require 'fileutils'

namespace :twinslash do
  desc 'Migrate attachments'
  task :migrate_attachments => :environment do
    base = Attachment.storage_path
    Attachment.find_in_batches(:conditions => ['NOT disk_filename LIKE ?', '____/%']) do |attaches|
      for attach in attaches
        df = attach.disk_filename
        df_path = base + '/' + df
        dir = df[0..3]
        dir_path = base + '/' + dir
        Dir.mkdir(dir_path) unless File.exists?(dir_path)
        FileUtils.mv(df_path, dir_path, :force => true)
        attach.disk_filename = dir + '/' + df
        attach.save
      end
    end
  end
end
