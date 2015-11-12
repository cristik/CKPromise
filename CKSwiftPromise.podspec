Pod::Spec.new do |s|

  s.name            = 'CKSwiftPromise'
  s.version         = '1.5.0'
  s.summary         = 'Swift facade for CKPromise'
  s.homepage        = 'https://github.com/cristik/CKPromise'
  s.source          = { :git => 'https://github.com/cristik/CKPromise.git', :tag => s.version.to_s }
  s.license         = { :type => 'MIT', :file => 'License.txt' }

  s.authors = {
    'Cristian Kocza'   => 'cristik@cristik.com',
  }

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.10'
  
  s.dependencies = {'CKPromise' => '>= 1.5.0'}
  
  s.source_files = 'CKSwiftPromise/*.{swift}'
end

