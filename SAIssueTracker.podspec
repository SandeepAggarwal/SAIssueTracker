@version = "0.0.1"
Pod::Spec.new do |s|

  s.name         = "SAIssueTracker"
  s.version      = @version
  s.summary      = "Track the logs in your client's app"
  s.description  = <<-DESC

Client got any issue and you are unable to reproduce it? No worries, just integrate this pod in your app and ask client to just take a screenshot and voila! you will get all logs on your email.
                   DESC

  s.homepage     = "https://github.com/SandeepAggarwal/SAIssueTracker"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Sandeep Aggarwal" => "smartsandeep1129@gmail.com" }
  s.social_media_url   = "https://twitter.com/sandeepCool77"
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/SandeepAggarwal/SAIssueTracker.git", :tag => "#{s.version}" }
  s.source_files  = "Classes"
  s.requires_arc = true
  s.xcconfig = { "HEADER_SEARCH_PATHS" => "$(inherited)" }
  s.dependency "mailcore2-ios", "~> 0.6.4"

end
