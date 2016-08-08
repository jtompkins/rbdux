Gem::Specification.new do |s|
  s.name        = 'rbdux'
  s.version     = '0.2'
  s.date        = '2016-08-08'
  s.summary     = "A simple one-way dataflow library, inspired by Redux"
  s.authors     = ["Joshua Tompkins"]
  s.email       = 'josh@joshtompkins.com'
  s.files       = [
                    "lib/rbdux.rb",
                    "lib/rbdux/action.rb",
                    "lib/rbdux/store.rb",
                    "lib/rbdux/errors.rb",
                    "lib/rbdux/middleware/thunk.rb",
                    "lib/rbdux/stores/memory_store.rb",
                    "lib/rbdux/stores/immutable_memory_store.rb"
                  ]
  s.homepage    =
    'https://github.com/jtompkins/rbdux'
  s.license       = 'MIT'
end
