class Newsletter < Page
  validates_presence_of :url, :subject
end
