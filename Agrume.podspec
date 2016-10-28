Pod::Spec.new do |s|

  s.name         = "Agrume"
  s.version      = "3.0.3"
  s.summary      = "An iOS image viewer written in Swift."

  s.description  = <<-DESC
                   An iOS image viewer written in Swift with support for multiple images.
                   DESC

  s.homepage     = "https://github.com/JanGorman/Agrume"

  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.author             = { "Jan Gorman" => "gorman.jan@gmail.com" }
  s.social_media_url   = "http://twitter.com/JanGorman"

  s.platform     = :ios, "8.0"

  s.source       = { :git => "https://github.com/JanGorman/Agrume.git", :tag => s.version}

  s.source_files  = "Classes", "Agrume/*.swift"

end
