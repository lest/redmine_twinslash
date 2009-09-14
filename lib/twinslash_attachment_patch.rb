require_dependency 'attachment'

module TwinslashAttachmentPatch
  def self.included(base)
    base.extend(ClassMethods)

    base.class_eval do
      unloadable

      class << self
        alias_method_chain :disk_filename, :twinslash
      end
    end
  end

  module ClassMethods
    def disk_filename_with_twinslash(filename)
      df = disk_filename_without_twinslash(filename)
      base = Attachment.storage_path
      dir = df[0..3]
      dir_path = base + '/' + dir
      Dir.mkdir(dir_path) unless File.exists?(dir_path)
      df = dir + '/' + df
      df.gsub(/^([\d\/]+)_/, '\1' + DateTime.now.strftime("%N") + '_')
    end
  end
end
