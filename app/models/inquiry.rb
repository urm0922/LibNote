class Inquiry < ApplicationRecord
  enum status: { draft: 0, open: 1, answered: 2, approved: 3, rejected: 4 }
end
