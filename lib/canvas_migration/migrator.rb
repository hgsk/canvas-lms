#
# Copyright (C) 2011 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

require 'open-uri'

class Canvas::Migrator
  include Canvas::MigratorHelper
  SCRAPE_ALL_HASH = { 'course_outline' => true, 'announcements' => true, 'assignments' => true, 'goals' => true, 'rubrics' => true, 'web_links' => true, 'learning_modules' => true, 'calendar_events' => true, 'calendar_start' => nil, 'calendar_end' => nil, 'discussions' => true, 'assessments' => true, 'question_bank' => true, 'all_files' => true, 'groups' => true, 'assignment_groups' => true, 'tasks' => true, 'wikis' => true }

  attr_accessor :course, :unzipped_file_path, :extra_settings, :total_error_count
  attr_reader :base_export_dir, :manifest, :import_objects, :settings

  def initialize(settings, migration_type)
    @settings = settings
    @settings[:migration_type] = migration_type
    @manifest = nil
    @error_count = 0
    @errors = []
    @course = {:file_map=>{}, :wikis=>[]}.with_indifferent_access
    @course[:name] = @settings[:course_name]

    return if settings[:testing]

    download_archive
    config = Setting.from_config('external_migration')
    @unzipped_file_path = Dir.mktmpdir(migration_type.to_s, config[:data_folder].presence)
    @base_export_dir = @settings[:base_download_dir] || find_export_dir
    @course[:export_folder_path] = File.expand_path(@base_export_dir)
    make_export_dir
  end

  def export
    raise "Migrator.export should have been overwritten by a sub-class"
  end

  def unzip_archive
    begin
      command = Canvas::MigratorHelper.unzip_command(@archive_file_path, @unzipped_file_path)
      logger.debug "Running unzip command: #{command}"
      zip_std_out = `#{command}`

      if $?.exitstatus == 0
        return true
      else
        #todo: error handling
        message = "Could not unzip archive file: #{zip_std_out}"
        logger.error message
      end
    rescue => e
      message = "Error unzipping archive file: #{e.message}"
      add_error "qti", message, nil, e
    end

    false
  end

  def delete_unzipped_archive
    delete_file(@unzipped_file_path)
  end

  def delete_file(file)
    if File.exists?(file)
      begin
        FileUtils::rm_rf(file)
      rescue
        Rails.logger.warn "Couldn't delete #{file} for content_migration #{@settings[:content_migration_id]}"
      end
    end
  end

  def get_full_path(file_name)
    File.join(@unzipped_file_path, file_name) if file_name
  end

  def move_archive_to(full_path)
    if @archive_file.is_a?(Tempfile)
      FileUtils.move(@archive_file.path, full_path)
    else
      FileUtils.copy(@archive_file.path, full_path)
    end
  end

  protected

  def download_archive
    config = Setting.from_config('external_migration')
    if @settings[:export_archive_path]
      @archive_file = File.open(@settings[:export_archive_path], 'rb')
    elsif @settings[:course_archive_download_url].present?
      # open-uri downloads the http response to a tempfile
      @archive_file = open(@settings[:course_archive_download_url])
    elsif @settings[:attachment_id]
      att = Attachment.find(@settings[:attachment_id])
      @archive_file = att.open(:temp_folder => config[:data_folder],
                               :need_local_file => true)
    else
      raise "No migration file found"
    end

    @archive_file_path = @archive_file.path
  end
end
