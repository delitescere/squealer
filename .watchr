# ~/.vim/ftdetect/watchr.vim
#
# This should have only the following line in it:
#
# autocmd BufNewFile,BufRead *.watchr setf ruby
#
# This will enable vim to recognize this file as ruby code should you wish to
# edit it.
def run(cmd)
  puts cmd
  system cmd
end

def spec(file)
  run "spec -O spec/spec.opts #{file}"
end

watch("spec/.*/*_spec\.rb") do |match|
  p match[0]
  spec(match[0])
end

watch("lib/(.*/.*)\.rb") do |match|
  p match[1]
  spec("spec/#{match[1]}_spec.rb")
end

