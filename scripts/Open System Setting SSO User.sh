#!/bin/zsh
username=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }')
open "x-apple.systempreferences:com.apple.Users-Groups-Settings.extension?showinfo*user:${username}"