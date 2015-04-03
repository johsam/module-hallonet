#!/bin/sh
# the next line restarts using wish \
exec wish "$0" -- "$@"


#############################################################################
#
# scrolled_text_create...
#
#############################################################################

proc scrolled_text_create {win} {

	set text_widget ${win}.text
	set text_v_Scroll ${win}.textvscroll
	set text_h_Scroll ${win}.texthorscroll

	text ${text_widget} -wrap none -borderwidth 1 -yscrollcommand "${text_v_Scroll} set" -xscrollcommand "${text_h_Scroll} set" -background white -relief ridge

	scrollbar ${text_v_Scroll} -width 10 -borderwidth 1 -command "${text_widget} yview"
	scrollbar ${text_h_Scroll} -width 10 -borderwidth 1 -orient horizontal -command "${text_widget} xview"

	grid columnconf ${win} 0 -weight 1
	grid rowconf ${win} 0 -weight 1
	grid ${text_h_Scroll} -in ${win} -column 0 -row 1 -columnspan 1 -rowspan 1 -sticky ew
	grid ${text_v_Scroll} -in ${win} -column 1 -row 0 -columnspan 1 -rowspan 1 -sticky ns
	grid ${text_widget} -in ${win} -column 0 -row 0 -columnspan 1 -rowspan 1 -sticky nsew

	#pack ${text_v_Scroll} -side right -fill y -padx 0
	#pack ${text_h_Scroll} -side bottom -fill x -padx 0
	#pack ${text_widget} -expand 1 -fill both -padx 0

	return ${text_widget}
}


#############################################################################
#
# expand_dir...
#
#############################################################################

proc expand_dir {dir} {
	set result $dir
	set olddir [pwd]
	set cmd "cd $dir"

	if {[catch $cmd]} {
		return ""
	}
	
	set result [pwd]

	if {[string compare "$result" "$olddir"] == 0} {
		#puts "the same"
	} else {
		#puts "new dir is $result"
	}

	catch "cd $olddir"
	return $result
}

#############################################################################
#
# busy_eval...
#
#############################################################################

proc busy_eval {script} {
	global base savedcursor

	proc busy_recursive {parent} {
		global savedcursor

		foreach win [winfo children ${parent}] {
			set oldcursor [${win} cget -cursor]

			if {[string length ${oldcursor}] > 0} {
				set savedcursor(${win}) ${oldcursor}
				${win} configure -cursor watch
				#puts "${win}---${oldcursor}---"
			}
			busy_recursive $win
		}
	}


	if {! [winfo exists ${base}.busylock]} {
		frame ${base}.busylock
		bind ${base}.busylock <KeyPress-Escape> {bell}
		bind ${base}.busylock <KeyPress> {break}
		bind ${base}.busylock <Button> {bell
			break}

		place ${base}.busylock -x -2 -y -2
		update idletasks
	}

	set fwin [focus]
	focus ${base}.busylock
	catch [grab set ${base}.busylock]

	set cursor [${base} cget -cursor]
	${base} configure -cursor watch

	busy_recursive ${base}
	update


	set status [catch {uplevel $script} result]


	foreach win [array names savedcursor] {
		if {[winfo exist ${win}]} {
			${win} configure -cursor $savedcursor(${win})
		}
		unset savedcursor(${win})
	}


	${base} configure -cursor $cursor
	grab release ${base}.busylock
	focus $fwin

	return -code $status $result
}

###############################################################################
# Return the name of a temporary file
###############################################################################

proc tmpfile {n} {
	global env
	file join "/tmp" "$env(LOGNAME)[pid]"
}

###############################################################################
# Execute a command.
# Returns "$stdout $stderr $exitcode" if exit code != 0
###############################################################################

proc run-command {cmd} {
	global opts errorCode

	set stderr ""
	set exitcode 0
	set errfile [tmpfile "r"]
	set failed [catch "$cmd 2>$errfile" stdout]

	# Read stderr output
	catch {
		set hndl [open "$errfile" r]
		set stderr [read $hndl]
		close $hndl
		file delete "$errfile"
	}
	if {$failed} {
		switch [lindex $errorCode 0] {
		"CHILDSTATUS" {
				set exitcode [lindex $errorCode 2]
			}
		"POSIX" {
				if {$stderr == ""} {
					set stderr $stdout
				}
				set exitcode -1
			}
		default {
				set exitcode -1
			}
		}
	}
	catch {file delete $errfile}
	return [list "$stdout" "$stderr" "$exitcode"]
}


#############################################################################
#
# textSearch...
#
#############################################################################

proc textSearch {w string tag} {
	if {$string == ""} {
		$w tag remove search 0.0 end
		return
	}
	set cur 1.0
	while {1} {
		set cur [$w search -count length $string $cur end]
		if {$cur == ""} {
			break
		}
		$w tag add $tag $cur "$cur + $length char"
		set cur [$w index "$cur + $length char"]
	}
}




#############################################################################
#
# tkfs_editor_output...
#
#############################################################################

proc tkfs_editor_output {fid} {
	if {[gets $fid line] < 0} {
		catch "close $fid"
	}
}


#############################################################################
#
# tkfs_exec_editor...
#
#############################################################################

proc tkfs_exec_editor {file line} {
	global base opts
	set fid -1
	
	if {$opts(usenedit) == 0} {
	set cmd "nedit-nc -noask -svrname tkfindsource -line ${line} ${file}"
	#set cmd "geany --line ${line} ${file}"
	} 
	
	if {$opts(usenedit) == 1} {
	set cmd "nedit -line ${line} ${file}"
	}

	if {$opts(usenedit) == 2} {
	set cmd "gnuclient +${line} ${file}"
	}

	catch [set fid [open "| $cmd"]]
	if {$fid != -1} {
		fileevent $fid readable "tkfs_editor_output $fid"
	} else {
		after idle {${base}.errordialog.msg configure -wraplength 10i}
		tk_dialog ${base}.errordialog "Error while executing " "\"$cmd\"..." error 0 Ok
	}
}


#############################################################################
#
# tkfs_insert_button...
#
#############################################################################

proc tkfs_insert_button {file title indexline} {
	global resultText hits

	set bname ${resultText}.b_$hits(count)
	button $bname -highlightthickness 0 -borderwidth 1 -cursor left_ptr -pady 0 -padx 0 -text "${title}" -font {Courier -12} -command "tkfs_exec_editor ${file} ${indexline}" -background palegreen1

	${resultText} window create end -window $bname
}


#############################################################################
#
# tkfs_insert_line...
#
#############################################################################

proc tkfs_insert_line {insert filename indexline} {
	global resultText hits
	set patterncount 0
	set inpattern 0
	set data {}
	set bname {}

	if {![regexp "\003" "${insert}"]} {
		${resultText} insert end ${insert}
		return
	}

	for {set l 0} {${l} < [string length ${insert}]} {incr l} {
		set c [string index ${insert} ${l}]

		if {${inpattern} == 0} {
			if {${c} == "\003"} {
				#puts "data = $data"
				incr hits(count)
				${resultText} insert end ${data}
				set data {}
				set inpattern 1
				continue
			}
			append data ${c}
		} else {
			if {${c} == "\003"} {
				#puts "bname = $bname"
				incr patterncount
				if {${patterncount} < 2} {
					tkfs_insert_button ${filename} ${bname} ${indexline}
				} else {
					${resultText} insert end ${bname} search
				}
				set bname {}
				set inpattern 0
				continue
			}
			append bname ${c}
		}
	}
	${resultText} insert end ${data}
	#puts "data = $data"
}


#############################################################################
#
# tkfs_display_result...
#
#############################################################################

proc tkfs_display_result {file pattern} {
	global fileFound resultText opts hits

	if {$opts(aborted) == 1} {
		return
	}

	set latstartline 0
	set lastendline 0
	set linelist(0) {}


	if {[file readable ${file}]} {
		set fileid [open ${file} "r"]
		set filedata [read ${fileid}]
		set linedata [split ${filedata} "\n"]
		set linecount [expr [llength $linedata] - 2]

		${resultText} insert end "${file}\n" filename
		${resultText} insert end "\n"

		for {set idx 0} {${idx} < [llength $fileFound(${file})]} {incr idx} {
			set indexline [lindex $fileFound(${file}) ${idx}]

			if {${indexline} >= $latstartline && ${indexline} <= $lastendline} {
				#puts "Skipping line $indexline"
				continue
			}

			set startline [expr ${indexline} - $opts(nlinesbefore) - 1]
			set endline [expr ${startline} + (2 * $opts(nlinesbefore)) + 1]
			set latstartline ${startline}
			set lastendline ${endline}

			#

			for {set l ${startline}} {${l} < ${endline}} {incr l} {

				if {${l} < 0} {
					#puts "Ignoring line ${l}..."
					continue
				}

				if {${l} > ${linecount}} {
					#puts "Ignoring line ${l}..."
					continue
				}


				if {[lsearch $linelist(0) ${l}] != -1} {
					#puts "Already have line ${l}..."			
					continue
				}



				lappend linelist(0) ${l}
				# remember this line nr


				set linenr [format "%-5d" [expr ${l} + 1]]
				set insert "[lindex ${linedata} ${l}]"


				${resultText} insert end "${linenr}" linenr

				catch [regsub -all ${pattern} ${insert} "\003&\003" insert]
				tkfs_insert_line ${insert} ${file} ${linenr}

				${resultText} insert end "\n"
			}


			${resultText} insert end "\n"

			if {$idx < [expr [llength $fileFound(${file})] - 1]} {
				${resultText} insert end "\n" fileseparator
				${resultText} insert end "\n"
			}

		}

		close ${fileid}
	}

	#update

}


#############################################################################
#
# tkfs_clear_result...
#
#############################################################################

proc tkfs_clear_result {} {
	global resultText progressBar

	$resultText configure -state normal
	${resultText} delete 1.0 end
		
	tkfs_gauge_value $progressBar 0
	update idletasks

	# Destroy our pop-up menu.
	if {[winfo exists .popup]} {
		destroy .popup
	}
}


#############################################################################
#
# tkfs_redisplay_result...
#
#############################################################################

proc tkfs_redisplay_result {} {
	global resultText fileFound opts hits progressBar

	set last_dir_in_menu {}
	set basedir {}
	set opts(aborted) 0
	set idx 1


	tkfs_clear_result
	tkfs_update_info "Displaying result\t(Hit Escape to abort)"

	foreach file [lsort [array names fileFound]] {

		if {$opts(aborted) == 1} {
			$resultText configure -state disabled
			return
		}

		if {[llength $fileFound(${file})] > 0} {
			set currenttextpos [${resultText} index end]
			
			set befirehits $hits(count)
			tkfs_display_result $file $opts(search_pattern)
			set afterhits $hits(count)

			# Create our pop-up menu.

			if {![winfo exists .popup]} {
				menu .popup
			}

			set what $opts(search_path)

			if {[regexp "($what)(.*)" "${file}" s1 s2 s3]} {
				catch [regsub -all "^/" ${s3} "" s3]
				set basedir [file dir $s3]

				if {${idx} > 1} {
					if {[string compare ${basedir} ${last_dir_in_menu}] != 0} {
						set last_dir_in_menu ${basedir}
						.popup add separator
					}
				}

				set last_dir_in_menu ${basedir}

				.popup add command -font {Courier -10} -label "([format "%3d" [expr $afterhits - $befirehits]]) ${s3}" -command "${resultText} yview -pickplace ${currenttextpos}"
			} else {
				.popup add command -label "([format "%3d" [expr $afterhits - $befirehits]]) ${file}" -command "${resultText} yview -pickplace ${currenttextpos}"
			}

		}
		tkfs_gauge_value $progressBar [expr ($idx * 100.0) / $hits(files)]
		incr idx
	}

	tkfs_gauge_value $progressBar 100
	tkfs_update_info ""
	$resultText configure -state disabled
}


#############################################################################
#
# tkfs_update_info...
#
#############################################################################

proc tkfs_update_info {data} {
	global infoFrame
	${infoFrame}.infoLabel config -text ${data}
	update
}



#############################################################################
#
# tkfs_expand_searchpath...
#
#############################################################################

proc tkfs_expand_searchpath {} {
	global opts searchPathEntry
	set result 0

	#puts "checking $opts(search_path)..."

	set tmp [glob -nocomplain $opts(search_path)]

	set newdir [expand_dir $tmp]
	if {[string length $newdir] > 0} {
		set tmp [glob -nocomplain $newdir]
	}


	if {[file isdirectory $tmp]} {
		catch [regsub "/$" $tmp "" tmp]
		# remove traling "/"
		#append tmp "/"
		${searchPathEntry} configure -background gray
		if {[string compare $tmp $opts(search_path)] != 0} {
			set opts(search_path) $tmp
			set opts(needscan) 1
			${searchPathEntry} icursor end
			${searchPathEntry} xview end

			#puts "new path $opts(search_path)..."
		}
	} else {
		${searchPathEntry} configure -background red
		bell
		focus ${searchPathEntry}
		set result 1
	}

	return $result
}



#############################################################################
#
# tkfs_execute_history...
#
#############################################################################

proc tkfs_execute_history {search_pattern search_path file_pattern} {
	global opts


	set opts(search_pattern) ${search_pattern}
	set opts(file_pattern) ${file_pattern}

	if {[string compare $opts(search_path) ${search_path}] != 0} {
		set opts(needscan) 1
		set opts(search_path) ${search_path}
	}

	#puts "opts(needscan) = $opts(needscan)"

	tkfs_scan_files
}



#############################################################################
#
# tkfs_add_history...
#
#############################################################################

proc tkfs_add_history {search_pattern search_path file_pattern} {
	global base opts tkfs_global_history

	set historylabel "${search_pattern} --- ${search_path} --- ${file_pattern}"


	set hindex [lsearch -exact $tkfs_global_history(hist_pattern) ${historylabel}]
	if {${hindex} != -1} {
		#	puts "Already have line ${historylabel}..."
		return

	} else {
		lappend tkfs_global_history(hist_pattern) ${historylabel}
	}


	set cmd "tkfs_execute_history {${search_pattern}} ${search_path} ${file_pattern}"




	${base}.menubar.historymenu.historypd add command -label "${historylabel}" -command $cmd
}


#############################################################################
#
# tkfs_scan_files...
#
#############################################################################

proc tkfs_scan_files {} {
	global .popup fileFound opts hits resultText

	set hits(count) 0
	set hits(files) 0
	set opts(aborted) 0
	
	
	 
	
	tkfs_add_history $opts(search_pattern) $opts(search_path) $opts(file_pattern)

	
	tkfs_clear_result

	if {$opts(needscan) == 1} {
		set opts(needscan) 0
		busy_eval "tkfs_expand_searchpath ; tkfs_find_files ; tkfs_grep_files"
	} else {
		busy_eval "tkfs_grep_files"
	}

	busy_eval "tkfs_redisplay_result"

	#textSearch ${resultText} $opts(search_pattern) search
}



#############################################################################
#
# tkfs_error...
#
#############################################################################

proc	tkfs_error {errortext} {
global resultText

${resultText} insert end "${errortext}" filename
bell
update
after 2000
}

#############################################################################
#
# tkfs_grep_files...
#
#############################################################################

proc tkfs_grep_files {} {
	global opts fileList fileFound hits 


	if {[info exists fileFound]} {
		foreach t [lsort [array names fileFound]] {
			unset fileFound($t)
		}
	}


	if {[string length $opts(search_pattern)] && [string length $fileList] && [string length $opts(file_pattern)]} {

		tkfs_update_info "Searching for pattern '$opts(search_pattern)'..."

		if {[llength ${fileList}] == 1} {
			set cmd "exec egrep -n {$opts(search_pattern)} $fileList | cut -f1 -d:"
			set result [run-command "$cmd"]
			set stdout [lindex $result 0]
			set stderr [lindex $result 1]
			set exitcode [lindex $result 2]

			if {${exitcode} == 2} {
				if {[regexp ".*syntax error.*" "${stderr}"]} {
					tkfs_error "${stderr}"
					return
				} else {

					set opts(needscan) 1
					tkfs_error "${stderr}"
					after 100 tkfs_scan_files
					return

				}
			}


			if {${exitcode} == 0} {
				set resultList [split ${stdout} "\n"]

				for {set loop 0} {$loop < [llength ${resultList}]} {incr loop} {
					set linenr [lindex ${resultList} $loop]
					#puts "---${fileList}---${linenr}---"

					if {![info exists fileFound(${fileList})]} {
						set fileFound(${fileList}) {}
					}

					lappend fileFound(${fileList}) ${linenr}
				}
			}


		} else {
			set cmd "exec egrep -n -e {$opts(search_pattern)} $fileList | cut -f1,2 -d:"
			set result [run-command "$cmd"]
			set stdout [lindex $result 0]
			set stderr [lindex $result 1]
			set exitcode [lindex $result 2]

			if {${exitcode} == 2} {
				if {[regexp ".*syntax error.*" "${stderr}"]} {
					tkfs_error "${stderr}"
					return
				} else {

					set opts(needscan) 1
					tkfs_error "${stderr}"
					after 100 tkfs_scan_files
					return

				}
			}

			if {${exitcode} == 0} {
				set resultList [split ${stdout} "\n"]
				tkfs_update_info "Scanning result..."

				for {set loop 0} {$loop < [llength ${resultList}]} {incr loop} {
					set t1 [lindex ${resultList} $loop]
					set t2 [split ${t1} ":"]
					set name [lindex ${t2} 0]
					set linenr [lindex ${t2} 1]

					#if {![info exists fileFound(${name})]} {
					#	set fileFound(${name}) {}
					#}

					lappend fileFound(${name}) ${linenr}
				}
			}
		}

	}
	set hits(files) [array size fileFound]


	#puts "found $hits(files) files containing pattern '$opts(search_pattern)'"
}

#############################################################################
#
# tkfs_find_files...
#
#############################################################################

proc tkfs_find_files {} {
	global opts fileList hits


	set hits(hits) 0
	set hits(files) 0
	set hits(total) 0
	set fileList {}

	if {[string length $opts(file_pattern)] == 0} {
		return
	}

	tkfs_update_info "Finding files matching pattern '$opts(file_pattern)'..."
	set file_pattern $opts(file_pattern)
	
	catch [regsub -all "\\|" $file_pattern " -o -name "  file_pattern]
	catch [regsub -all "\"" $file_pattern ""  file_pattern]


	set cmd "exec find $opts(search_path) ( -name $file_pattern ) -a ! -name \"*.svn-base\" -follow -type f -print"
	set result [run-command "$cmd"]
	set stdout [lindex $result 0]
	set stderr [lindex $result 1]
	set exitcode [lindex $result 2]


	#puts "cmd = '${cmd}'"
	#puts "stdout = '${stdout}'"
	#puts "stderr = '${stderr}'"
	#puts "exitcode = '${exitcode}'"


	#	Loop through list and only use items that begins with a "/"
	#	otherwise grep won't work...

	set rawfileList [split ${stdout} "\n"]

	for {set loop 0} {$loop < [llength ${rawfileList}]} {incr loop} {
		set tmp [lindex ${rawfileList} $loop]
		set c [string index ${tmp} 0]
		if {${c} == "/"} {
			lappend fileList $tmp
		}
	}



	set hits(total) [llength ${fileList}]

	#puts "found $hits(total) files matching pattern '$opts(file_pattern)'"
}


#############################################################################
#
# tkfs_optionMenu...
#
#############################################################################

proc tkfs_optionMenu {command w varName firstValue args} {
	upvar #0 $varName var

	if {![info exists var]} {
		set var $firstValue
	}

	set maxlen 0
	foreach i $args {
		if {[string length $i] > $maxlen} {
			set maxlen [string length $i]
		}
	}


	menubutton $w -textvariable $varName -indicatoron 1 -menu $w.menu -relief raised -bd 1 -highlightthickness 1 -borderwidth 1 -anchor c -width $maxlen
	#-direction flush
	menu $w.menu -tearoff 0 -borderwidth 2 -bd 1

	$w.menu add radiobutton -label $firstValue -variable $varName -command "$command"
	foreach i $args {
		$w.menu add radiobutton -label $i -variable $varName -command "$command"

	}
	return $w.menu
}

#############################################################################
#
# tkfs_select_dir...
#
#############################################################################

proc tkfs_select_dir {} {
	global opts base
	set file_types {
        { "All Files"   * }
    }

	set filename [tk_getOpenFile -parent ${base} -initialdir $opts(search_path) -filetypes $file_types -title "Pick a file to select a directory..."]

	if {$filename != ""} {
		set opts(needscan) 1
		set opts(search_path) [file dirname $filename]
		tkfs_expand_searchpath
	}
}


#############################################################################
#
# tkfs_gauge_create...
#
#############################################################################

proc tkfs_gauge_create {win {color ""}} {
	global infoFrame
	frame $win -class Gauge

	set len [option get $win length Length]

	canvas $win.display -borderwidth 0 -background white -highlightthickness 0 -width $len -height 0
	pack $win.display -expand 0

	if {$color == ""} {
		set color [option get $win color Color]
	}
	$win.display create rectangle 0 0 0 20 -outline "" -fill $color -tags bar
	$win.display create text [expr {0.5*$len}] 0 -anchor c -text "[format "%3.0f%%" 0]" -tags value

	return $win
}


#############################################################################
#
# tkfs_gauge_value...
#
#############################################################################

set gaugeconfigured 0
proc tkfs_gauge_value {win val} {
	global gaugeconfigured

	if {$val < 0 || $val > 100} {
		error "bad value \"$val\": should be 0-100"
	}

	if {$gaugeconfigured == 0} {
		set newheight [expr [winfo height [winfo parent $win]] - 8]
		$win.display configure -height $newheight
		$win.display move value 0 [expr $newheight / 2.0]
		pack $win -padx 2 -pady 2
		#update
		set gaugeconfigured 1
	}

	set msg [format "%3.0f%%" $val]
	$win.display itemconfigure value -text $msg

	set w [expr {0.01*$val*[winfo width $win.display]}]
	set h [winfo height $win.display]
	$win.display coords bar 0 0 $w $h

	update
}


#############################################################################
#
# tkfs_history_search_pattern...
#
#############################################################################

proc tkfs_history_search_pattern {{cmd  add} {value {}}} {
	global tkfshistory opts searchForEntry

	set count [llength $tkfshistory(search_pattern)]

	switch $cmd {
	add {
			if {[string length ${value}] == 0} {
				return
			}
			set hindex [lsearch -exact $tkfshistory(search_pattern) ${value}]
			if {${hindex} != -1} {
				set tkfshistory(search_pattern_idx) ${hindex}
				#puts "Already have line ${value}..."
			} else {
				lappend tkfshistory(search_pattern) $value
				set tkfshistory(search_pattern_idx) $count
			}
		}
	prev {
			incr tkfshistory(search_pattern_idx) -1
			if {$tkfshistory(search_pattern_idx) < 0} {
				set tkfshistory(search_pattern_idx) [expr $count -1]
			}
		}
	next {
			incr tkfshistory(search_pattern_idx)
			if {$tkfshistory(search_pattern_idx) >= $count} {
				set tkfshistory(search_pattern_idx) 0
			}
		}
	}

	set opts(search_pattern) [lindex $tkfshistory(search_pattern) $tkfshistory(search_pattern_idx)]
	if {[info exists searchForEntry]} {
		${searchForEntry} icursor end
		${searchForEntry} xview end
	}
	#parray tkfshistory
}


#############################################################################
#
# tkfs_help...
#
#############################################################################

proc tkfs_help {} {
puts "usage: tkfindsource.tcl pattern \[startdir\] \[-nfilepattern] \[-nc\] \[-remote rempattern <remdir>\] \[-help]"
puts "       pattern (regexp pattern to search for)"
puts "       startdir (default `pwd`)"
puts "       -nfilepattern file pattern to search for (default -n\"*.pp\")..."
puts "       -nc use nc as editor (default nedit)..."
puts "       -remote launches a second tkfindsource.tcl and search for rempattern in remdir..."
puts "          example as a macro in nedit -->myresult=shell_command(\"tkfindsource.tcl -remote \"get_selection(),\"\")<--"

puts "       -help gives this text..."

exit 1
}


#############################################################################
#
# tkfs_remote...
#
#############################################################################

proc tkfs_remote {searchfor {newPath {}} {newpattern {}}} {
	global base opts searchPatternEntry searchPathEntry

	#wm withdraw ${base}
	wm deiconify ${base}

	#catch {puts "searchfor = '${searchfor}'"}
	#catch {puts "newPath = '${newPath}'"}
	#catch {puts "newpattern = '${newpattern}'"}


	if {[string length ${newPath}] > 0} {

		set newdir [expand_dir ${newPath}]
		if {[string length ${newdir}] > 0} {
			if {[string compare ${newdir} $opts(search_path)] != 0} {
				set opts(search_path) [glob -nocomplain ${newdir}]
				set opts(needscan) 1
				if {[info exists searchPathEntry]} {
					${searchPathEntry} icursor end
					${searchPathEntry} xview end
				}
			}
		} else {
		set newpattern ${newPath}
		}

	}

	if {[string length ${newpattern}] > 0} {
		if {[string match "-n*" ${newpattern}]} {
			set newpattern [string range ${newpattern} 2 end]
		}
		if {[string compare ${newpattern} $opts(file_pattern)] != 0} {
			set opts(file_pattern) ${newpattern}
			set opts(needscan) 1
			if {[info exists searchPatternEntry]} {
				${searchPatternEntry} icursor end
				${searchPatternEntry} xview end
			}
		}
	}



	tkfs_history_search_pattern add "${searchfor}"
	tkfs_scan_files
}



#############################################################################
#
# tkfs_self_output...
#
#############################################################################

proc tkfs_self_output {fid} {
	if {[gets $fid line] < 0} {
		catch "close $fid"
	}
}


#############################################################################
#
# main...
#
#############################################################################

#tk_setPalette yellow3


option add *menubar*background #759EFF
option add *menubar*activeBackground #759EFF
option add *menubar*disabledForeground #557EaF

option add *Entry.background gray75


option add *Gauge.borderWidth 1 widgetDefault
option add *Gauge.relief sunken widgetDefault
option add *Gauge.length 100 widgetDefault
option add *Gauge.color gray widgetDefault



set opts(search_path) [glob -nocomplain "[pwd]"]
set opts(file_pattern) "*.pp"
set opts(search_pattern) ""
set opts(nlinesbefore) 2
set	opts(usenedit) 0
set opts(needscan) 1
set opts(aborted) 0

# Load our .tkfindsource from $HOME if it exists...

set homercfile [file join $env(HOME) .tkfindsource]

if {[file isfile ${homercfile}]} {
	catch {source ${homercfile}}
}



set hits(count) 0
set hits(files) 0
set hits(total) 0



set tkfshistory(search_pattern) {}
set tkfshistory(search_pattern_idx) 0

set tkfs_global_history(hist_pattern) {}


if {${argc} >= 1} {
	for {set loop 0} {$loop < [llength ${argv}]} {incr loop} {
		set tmp [lindex ${argv} $loop]
		switch -glob -- $tmp {
		-remote {
				set rem1 "[lindex ${argv} 1]"
				set rem2 "[lindex ${argv} 2]"
				set rem3 "[lindex ${argv} 3]"

				if {[lsearch [winfo interp] "tkfindsource"] != -1} {
					send tkfindsource tkfs_remote "{$rem1}" "{$rem2}" "{$rem3}"
					exit 0
				} else {
					#puts "Could not find any tkfindsource running..."
					bell

					catch [set fid [open "| tkfindsource.tcl $rem1 $rem2 $rem3"]]
					#if {$fid != -1} {
					#	fileevent $fid readable "tkfs_self_output $fid"
					#}
					exit 0
				}
				continue
			}
		-help -
		-h* -
		--help {
				tkfs_help
			}
		-nc -
		--nc {
				set opts(usenedit) 0
				continue
			}
		-n* {
				set opts(file_pattern) [string range ${tmp} 2 end]
				catch [regsub -all "\"" $opts(file_pattern) ""  opts(file_pattern)]
				continue
			}
		}

		set newdir [expand_dir $tmp]
		if {[string length $newdir] > 0} {
			set opts(search_path) [glob -nocomplain $newdir]
		} else {
			tkfs_history_search_pattern add ${tmp}
		}
	}
}


#	Now set our name so send command finds us...

tk appname tkfindsource


set tkfsversion {$Revision: 1.14 $}
catch [regsub -all {[^0-9.]} ${tkfsversion} "" tkfsversion]

set base .tkfindsource
toplevel ${base} -class Toplevel
wm withdraw .
wm withdraw ${base}

wm title ${base} "tkfindsource v${tkfsversion}"
wm protocol ${base} WM_DELETE_WINDOW {exit}

wm geometry ${base} 750x500

#	Create our menubar...

frame ${base}.menubar -borderwidth 2 -relief raised

menubutton ${base}.menubar.filemenu -anchor w -underline 0 -menu ${base}.menubar.filemenu.filepd -padx 4 -pady 3 -text File
menu ${base}.menubar.filemenu.filepd -tearoff 0
${base}.menubar.filemenu.filepd add command -accelerator Alt-Q -underline 0 -command {exit} -label Quit


menubutton ${base}.menubar.optionmenu -anchor w -underline 0 -menu ${base}.menubar.optionmenu.optionpd -padx 4 -pady 3 -text Options
menu ${base}.menubar.optionmenu.optionpd -tearoff 0
${base}.menubar.optionmenu.optionpd add radiobutton -underline 4 -value 1 -variable opts(usenedit) -label "Use nedit"
${base}.menubar.optionmenu.optionpd add radiobutton -underline 5 -value 0 -variable opts(usenedit) -label "Use nc"
${base}.menubar.optionmenu.optionpd add radiobutton -underline 5 -value 2 -variable opts(usenedit) -label "Use xemaxs"



menubutton ${base}.menubar.historymenu -anchor w -underline 0 -menu ${base}.menubar.historymenu.historypd -padx 4 -pady 3 -text History
menu ${base}.menubar.historymenu.historypd -tearoff 0
#${base}.menubar.historymenu.historypd add command -underline 4  -label "Hello..."


pack ${base}.menubar -anchor center -expand 0 -fill x -side top
pack ${base}.menubar.filemenu -in ${base}.menubar -anchor center -expand 0 -fill none -side left
pack ${base}.menubar.optionmenu -in ${base}.menubar -anchor center -expand 0 -fill none -side left
pack ${base}.menubar.historymenu -in ${base}.menubar -anchor center -expand 0 -fill none -side left

bind all <Alt-KeyPress-q> {exit}

#	Create a frame to hold our settings

set entryFrame ${base}.entryFrame
set searchPathEntry ${entryFrame}.searchPathEntry
set searchForEntry ${entryFrame}.searchForEntry
set searchPatternEntry ${entryFrame}.searchPatternEntry

frame ${entryFrame} -relief raised -borderwidth 1
pack ${entryFrame} -anchor n -fill x

label ${entryFrame}.l1 -text "Search for:"
entry ${entryFrame}.searchForEntry -borderwidth 1 -width 15 -textvariable opts(search_pattern)


#	Create an optionmenu

label ${entryFrame}.l4 -text "Lines b/a:"
tkfs_optionMenu "busy_eval tkfs_redisplay_result" ${entryFrame}.searchLinesbefore opts(nlinesbefore) 0 1 2 3 4 5 10 25


label ${entryFrame}.l2 -text "In path:"
entry ${searchPathEntry} -borderwidth 1 -textvariable opts(search_path)

button ${entryFrame}.browse -borderwidth 1 -text "Browse..." -command {tkfs_select_dir}

label ${entryFrame}.l3 -text "Pattern:"
entry ${entryFrame}.searchPatternEntry -borderwidth 1 -textvariable opts(file_pattern) -width 5


pack ${entryFrame}.l1 -side left
pack ${entryFrame}.searchForEntry -side left -padx 5


pack ${entryFrame}.l4 -side left
pack ${entryFrame}.searchLinesbefore -side left



pack ${entryFrame}.l2 -side left
pack ${searchPathEntry} -side left -fill x -expand 1

pack ${entryFrame}.browse -side left -pady 2

pack ${entryFrame}.searchPatternEntry -side right
pack ${entryFrame}.l3 -side right

focus ${entryFrame}.searchForEntry



#	Create a frame to hold our info

set infoFrame ${base}.infoFrame

frame ${infoFrame} -borderwidth 1 -relief raised
pack ${infoFrame} -fill x -side bottom



label ${infoFrame}.hitslabelValue -background white -relief sunken -anchor e -borderwidth 1 -width 5 -textvariable hits(count)
pack ${infoFrame}.hitslabelValue -side left -pady 2 -padx 2
label ${infoFrame}.hitslabel -borderwidth 1 -text "Hits in"
pack ${infoFrame}.hitslabel -side left


label ${infoFrame}.countlabelValue -background white -relief sunken -anchor e -borderwidth 1 -width 5 -textvariable hits(files)
pack ${infoFrame}.countlabelValue -side left -pady 2 -padx 2
label ${infoFrame}.countlabel -borderwidth 1 -text "files"
pack ${infoFrame}.countlabel -side left

label ${infoFrame}.totallabel -borderwidth 1 -text "out of"
pack ${infoFrame}.totallabel -side left
label ${infoFrame}.totallabelValue -background white -relief sunken -anchor e -borderwidth 1 -width 5 -textvariable hits(total)
pack ${infoFrame}.totallabelValue -side left -pady 2 -padx 2
label ${infoFrame}.pad -borderwidth 1 -text "..."
pack ${infoFrame}.pad -side left -padx 0

label ${infoFrame}.infoLabel -relief sunken -anchor w -borderwidth 1 -text ""
pack ${infoFrame}.infoLabel -side left -expand 1 -fill x -padx 0


set progressBar [tkfs_gauge_create ${infoFrame}.progressBar [lindex [. configure  -background ] end]]




#	Create a frame to hold our scrolled text

frame ${base}.textFrame -relief raised -borderwidth 1
pack ${base}.textFrame -expand 1 -fill both


set resultText [scrolled_text_create ${base}.textFrame]
${resultText} configure -exportselection 0 -font {Courier -12}
${resultText} configure -state disabled

${resultText} tag configure filename -justify left -relief raised -borderwidth 1 -background gray -font {Courier -12 bold}
${resultText} tag configure fileseparator -justify left -relief raised -borderwidth 0 -background gray95 -font {Courier -12 bold}
${resultText} tag configure search -background #ce5555 -foreground black -background gray75 -relief groove -borderwidth 1
${resultText} tag configure linenr -foreground gray75

bind ${entryFrame}.searchForEntry <Return> {
	tkfs_history_search_pattern add $opts(search_pattern)
	tkfs_expand_searchpath
	tkfs_scan_files
}

bind ${entryFrame}.searchForEntry <KeyPress-Up> {
	tkfs_history_search_pattern prev
}

bind ${entryFrame}.searchForEntry <KeyPress-Down> {
	tkfs_history_search_pattern next
}



bind ${searchPathEntry} <Return>	{set opts(needscan) 1 ; if {[tkfs_expand_searchpath] == 0} {tkfs_scan_files}}
bind ${searchPathEntry} <KeyPress>	{set opts(needscan) 1}
bind ${searchPathEntry} <Leave> 	{tkfs_expand_searchpath}
bind ${searchPathEntry} <FocusOut>	{tkfs_expand_searchpath}

bind ${entryFrame}.searchPatternEntry <Return> {set opts(needscan) 1 ; tkfs_scan_files}

bind ${entryFrame}.searchPatternEntry <KeyPress> "set opts(needscan) 1"




# Pop up our menu on rightmost button.
bind all <Button-3> {

	# Get global X position of app.
	set gx [winfo rootx %W]

	# Get global Y position of app.
	set gy [winfo rooty %W]

	# Add to local mouse positon.
	set mx [expr $gx + %x]
	set my [expr $gy + %y]

	# Display popup menu.
	if {[winfo exists .popup]} {
		tk_popup .popup $mx $my
	}
}


bind all <KeyPress-Escape> {
	set opts(aborted) 1
	tkfs_update_info "Aborted..."
}



update idletasks
wm deiconify ${base}
update







#############################################################################
#
# Ready to roll...
#
#############################################################################


${searchForEntry} icursor end
${searchForEntry} xview end


${searchPathEntry} icursor end
${searchPathEntry} xview end



after idle tkfs_gauge_value $progressBar 100

if {[string length $opts(search_pattern)] > 0} {
	after idle tkfs_scan_files
}





