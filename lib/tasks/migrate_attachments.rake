require 'fileutils'

namespace :twinslash do
  desc 'Migrate attachments'
  task :migrate_attachments => :environment do
    base = Attachment.storage_path
    for attach in Attachment.find(:all, :conditions => ['NOT disk_filename LIKE ?', '____/%'])
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
