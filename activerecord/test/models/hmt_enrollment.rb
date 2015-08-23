class HmtEnrollment < ActiveRecord::Base
  belongs_to :hmt_student
  belongs_to :hmt_course
end
