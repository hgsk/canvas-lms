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
module CC
  module Rubrics
    def create_rubrics(document=nil)
      return nil unless @course.rubrics.active.count > 0
      
      if document
        rubrics_file = nil
        rel_path = nil
      else
        rubrics_file = File.new(File.join(@canvas_resource_dir, CCHelper::RUBRICS), 'w')
        rel_path = File.join(CCHelper::COURSE_SETTINGS_DIR, CCHelper::RUBRICS)
        document = Builder::XmlMarkup.new(:target=>rubrics_file, :indent=>2)
      end

      document.instruct!
      document.rubrics(
          "xmlns" => CCHelper::CANVAS_NAMESPACE,
          "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
          "xsi:schemaLocation"=> "#{CCHelper::CANVAS_NAMESPACE} #{CCHelper::XSD_URI}"
      ) do |rubrics_node|
        @course.rubrics.active.each do |rubric|
          migration_id = CCHelper.create_key(rubric)
          rubrics_node.rubric(:identifier=>migration_id) do |r_node|
            atts = [:read_only, :title, :reusable, :public, :points_possible,
                    :hide_score_total, :free_form_criterion_comments]
            atts.each do |att|
              r_node.tag!(att, rubric.send(att)) if rubric.send(att) == false || !rubric.send(att).blank?
            end
            r_node.description rubric.description if rubric.description

            r_node.criteria do |c_node|
              if rubric.data && rubric.data.length > 0
                rubric.data.each do |crit|
                  add_criterion(c_node, crit)
                end
              end
            end

          end
        end
      end

      rubrics_file.close if rubrics_file
      rel_path
    end

    def add_criterion(node, criterion)
      node.criterion do |c_node|
        c_node.criterion_id criterion[:id]
        c_node.points criterion[:points]
        c_node.mastery_points criterion[:mastery_points] if criterion[:mastery_points]
        c_node.ignore_for_scoring criterion[:ignore_for_scoring] unless criterion[:ignore_for_scoring].nil?
        c_node.description criterion[:description]
        c_node.long_description criterion[:long_description] unless criterion[:long_description].blank?
        if criterion[:learning_outcome_id].present?
          if lo = @course.learning_outcomes.find_by_id(criterion[:learning_outcome_id])
            c_node.learning_outcome_identifierref CCHelper.create_key(lo)
          end
        end

        if criterion[:ratings] && criterion[:ratings].length > 0
          c_node.ratings do |ratings_node|
            criterion[:ratings].each do |rating|
              ratings_node.rating do |rating_node|
                rating_node.description rating[:description]
                rating_node.points rating[:points]
                rating_node.criterion_id rating[:criterion_id]
                rating_node.long_description rating[:long_description] unless rating[:long_description].blank?
                rating_node.tag! :id, rating[:id]
              end
            end
          end
        end

      end
    end

  end
end