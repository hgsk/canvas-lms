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

module UserNotesHelper
  def pageless(total_pages, url=nil)
    opts = {
      :totalPages => total_pages,
      :url        => url,
      :loaderHtml => '
<div id="pageless-loader" style="display:none;text-align:center;width:100%;">
  <div class="msg" style="color: #666;font-size:2em">Loading more entries</div>
  <img src="/images/load.gif" title="load" alt="loading more results" style="margin: 10px auto" />
</div>'
    }
    
    javascript_tag("$('#user_note_list').pageless(#{opts.to_json});")
  end
end
