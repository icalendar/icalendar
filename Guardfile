guard :test do
  watch(%r{^test/.*test_.+\.rb$})
  watch('test/test_helper.rb')  { 'test' }

  watch(%r{^lib/icalendar/(.+)\.rb}) { |m| "test/test_#{m[1]}.rb" }
  watch(%r{^lib/icalendar/components/(.+)\.rb}) { |m| "test/components/test_#{m[1]}.rb" }
end