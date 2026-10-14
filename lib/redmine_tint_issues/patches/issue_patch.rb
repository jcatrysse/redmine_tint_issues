# encoding: utf-8
#
# Redmine plugin to tint issues by age and due date
#
# Copyright © 2018-2020 Stephan Wenzel <stephan.wenzel@drwpatent.de>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#

module RedmineTintIssues
  module Patches
    module IssuePatch
    
      module InstanceMethods
      
        def css_classes(user=User.current)
          s = super(user)
          if RedmineTintIssues::Current.module_enabled?(self.project_id)
            s << self.issue_age.to_s
            s << self.issue_due.to_s
          end
          s
        end #def
        
##########################################################################################
# handle age
##########################################################################################
        
        def age_base
          RedmineTintIssues::Current.settings['age_by_creation_date'] == '0' ?  self.updated_on : self.created_on
        end
        
        def issue_age
          return is_current
        end #defined
        
        def is_current
          if !!dues_and_ages(:current_issue_age)
            base    = 
            start   = to_time(self.start_date).presence || age_base
            younger = start > dues_and_ages(:current_issue_age)
            return younger ? ' current' : is_old
          end
          return is_old
        end #def
        
        def is_old
          if !!dues_and_ages(:old_issue_age)
            start   = to_time(self.start_date).presence || age_base
            younger = start > dues_and_ages(:old_issue_age)
            return younger ? ' old' : is_older 
          end
          return is_older 
        end #def
        
        def is_older
          if !!dues_and_ages(:older_issue_age)
            start   = to_time(self.start_date).presence || age_base
            younger = start > dues_and_ages(:older_issue_age)
            return younger ? ' older' : is_veryold
          end
          return is_veryold
        end #def
        
        def is_veryold
          if !!dues_and_ages(:veryold_issue_age)
            start   = to_time(self.start_date).presence || age_base
            younger = start > dues_and_ages(:veryold_issue_age)
            return younger ? ' veryold' : ' ancient'
          end
          return %i(
            current_issue_age 
            old_issue_age 
            older_issue_age 
            veryold_issue_age
          ).any?{|age| !!dues_and_ages(age)} ? " ancient" : ""
        end #def
        
##########################################################################################
# handle due date
##########################################################################################

        def issue_due
            return is_overdue if self.due_date && !self.closed?
            return ''
        end #defined
        
        def is_overdue
          return overdue? ? ' overdue' : is_verydue
        end #def
        
        def is_verydue
          if !!dues_and_ages(:verydue_since)
            farer = self.due_date > dues_and_ages(:verydue_since)
            return farer ? is_moredue : ' verydue'
          end #if
          return is_due
        end #def
        
        def is_moredue
          if !!dues_and_ages(:moredue_since)
            farer = self.due_date > dues_and_ages(:moredue_since)
            return farer ? is_due : ' moredue'
          end #if
          return is_due
        end #def

        def is_due
          if !!dues_and_ages(:due_since)
            farer = self.due_date > dues_and_ages(:due_since)
            return farer ? ' hasduedate' : ' due'
          end #if
          return %i(
            due_since 
            moredue_since 
            verydue_since 
          ).any?{|since| !!dues_and_ages(since)} ? " hasduedate" : ""
        end #def
        
##########################################################################################
# calculate time and time differences
##########################################################################################

        def to_time( timestr )
          timestr.presence && timestr.to_time
        end #def
      
        def getpastdate( num, epoch )
          if num.present?
            case epoch
              when "hours"
                  num.to_i.hours.ago
              when "days"
                  num.to_i.days.ago
              when "weeks"
                  num.to_i.weeks.ago
              when "months"
                  num.to_i.months.ago
            end #case
          end #if
        end #def
        
        def getfuturedate( num, epoch )
          if num.present?
            case epoch
              when "hours"
                  num.to_i.hours.since.to_date
              when "days"
                  num.to_i.days.since.to_date
              when "weeks"
                  num.to_i.weeks.since.to_date
              when "months"
                  num.to_i.months.since.to_date
            end #case
          end #if
        end #def
        
##########################################################################################
# calculate once and cache date calculations
##########################################################################################

        def dues_and_ages( key )
          (RedmineTintIssues::Current.dues_and_ages ||= calculate_dues_and_ages)[key]
        end #def
        
        # thresholds are dates relative to now: calculated once per request
        def calculate_dues_and_ages
          settings = RedmineTintIssues::Current.settings
          ages = {}
          
          ages.merge!( :due_since => getfuturedate(
              settings["due_since"], 
              settings["due_since_epoch"]
            )
          )
          
          ages.merge!( :moredue_since => getfuturedate(
              settings["moredue_since"], 
              settings["moredue_since_epoch"]
            )
          )
          
          ages.merge!( :verydue_since => getfuturedate(
              settings["verydue_since"], 
              settings["verydue_since_epoch"]
            )
          )
          
          ages.merge!( :current_issue_age => getpastdate(
              settings["current_issue_age"], 
              settings["current_issue_age_epoch"]
            )
          )
          
          ages.merge!( :old_issue_age => getpastdate(
              settings["old_issue_age"], 
              settings["old_issue_age_epoch"]
            )
          )
        
          ages.merge!( :older_issue_age => getpastdate(
              settings["older_issue_age"], 
              settings["older_issue_age_epoch"]
            )
          )
          
          ages.merge!( :veryold_issue_age => getpastdate(
              settings["veryold_issue_age"], 
              settings["veryold_issue_age_epoch"]
            )
          )
          
          ages.compact!
          ages
        end #def
        
      end #module
    end #module
  end #module
end #module

# prepended, not alias_method'd: other plugins prepend to Issue#css_classes as well
unless Issue.ancestors.include?(RedmineTintIssues::Patches::IssuePatch::InstanceMethods)
    Issue.prepend(RedmineTintIssues::Patches::IssuePatch::InstanceMethods)
end
