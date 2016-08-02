Gem::Specification.new do |s|
  s.name        = 'rbdux'
  s.version     = '0.1'
  s.date        = '2016-08-02'
  s.summary     = "A simple one-way dataflow library, inspired by Redux"
  s.authors     = ["Joshua Tompkins"]
  s.email       = 'josh@joshtompkins.com'
  s.files       = [
                    "lib/rbdux.rb",
                    "lib/rbdux/action.rb",
                    "lib/rbdux/store.rb",
                    "lib/rbdux/middleware/dispatch_interceptor.rb"
                  ]
  s.homepage    =
    'https://github.com/jtompkins/rbdux'
  s.license       = 'MIT'
end
