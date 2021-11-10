
puts "$0: #{$0}"

for n in 0 .. ARGV.size - 1
  puts "ARGV[#{n}]: #{ARGV[n]}"
end

if Object.const_defined? :MC
  puts "MC::ExePath: #{MC::ExePath}"
  puts "MC::ProgPath: #{MC::ProgPath}"
  puts "MC::IsConstructed: #{MC::IsConstructed}"
else
  puts "No MC module!"
end

puts "Done."
