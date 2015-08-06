Pod::Spec.new do |s|

  s.name            = 'CKPromise'
  s.version         = '1.2.0'
  s.summary         = 'An implementation of Promises/A+ specification for ObjectiveC'
  s.homepage        = 'https://github.com/cristik/CKPromise'
  s.source          = { :git => 'https://github.com/cristik/CKPromise.git', :tag => s.version.to_s }
  s.license         = { :type => 'MIT', :file => 'License.txt' }

  s.authors = {
    'Cristian Kocza'   => 'cristik@cristik.com',
  }

  s.ios.deployment_target = '5.0'
  s.osx.deployment_target = '10.7'

  s.source_files = 'CKPromise/**/*.{h,m}'
  s.requires_arc = true

end

