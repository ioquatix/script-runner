#!/usr/bin/env ruby

$stdout.write "Give me some love: "
input = $stdin.gets.chomp!

if input =~ /love/i
	puts "Yeah baby!"
	puts DATA.read
else
	puts "..."
end

__END__

.            .--.
\\          //\\ \
.\\        ///_\\\\
:/>`      /(| `|'\\\
 Y/\      )))\_-_/((\
  \ \    ./'_/ " \_`\)
   \ \.-" ._ \   /   \
    \ _.-" (_ \Y/ _) |
     "      )" | ""/||
         .-'  .'  / ||
        /    `   /  ||
       |    __  :   ||_
       |   / \   \ '|\`
       |  |   \   \
       |  |    `.  \
       |  |      \  \
       |  |       \  \
       |  |        \  \
       |  |         \  \
       /__\          |__\
       /.|    DrS.    |.\_
      `-''            ``--'