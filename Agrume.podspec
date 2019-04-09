Pod::Spec.new do |s|

  s.name          = "Agrume"
  s.version       = "5.3.1"
  s.summary       = "An iOS image viewer written in Swift."
  s.swift_version = "5.0"

  s.description   = <<-DESC
                    An iOS image viewer written in Swift with support for multiple images.
                    DESC
                   
  s.homepage      = "https://github.com/JanGorman/Agrume"
                   
  s.license       = { :type => "MIT", :file => "LICENSE" }
                   
  s.author           = { "Jan Gorman" => "gorman.jan@gmail.com" }
  s.social_media_url = "https://twitter.com/JanGorman"

  s.platform      = :ios, "9.0"

  s.source        = { :git => "https://github.com/JanGorman/Agrume.git", :tag => s.version}

  s.source_files  = "Classes", "Agrume/*.swift"
  
  s.dependency "SwiftyGif"

end
