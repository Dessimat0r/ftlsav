#/bin/bash
if [ -z ${FTL_DIR+x} ];
then
	echo "FTL_DIR is unset, going to detect OS and determine directory.";
	case "$OSTYPE" in
	  linux*)   echo "Found Linux..."; cd ~/.local/share/FasterThanLight/;;
	  darwin*)  echo "Found OS X..."; cd ~/Library/Application\ Support/FasterThanLight;; 
	  win*)     echo "Found Windows..."; cd %USERPROFILE%\\My Documents\\My Games\\FasterThanLight\\;;
	  cygwin*)  echo "Found Windows (Cygwin)..."; cd %USERPROFILE%\\My Documents\\My Games\\FasterThanLight\\;;
	  *)        echo "Unknown OS type, cannot continue: $OSTYPE" ; break;;
	esac
else
	echo "FTL_DIR is set to '$FTL_DIR'";
	cd $FTL_DIR;
fi
IFS=$'\n' # set field separator to newline
while true; do
	contsav="does not exist"
	aesav="does not exist"
	if [ -e "ae_prof.sav" ];
	then
		stat=$(stat -f "%Sm" -t "%Y-%m-%d @ %H:%M" ae_prof.sav)
		aesav="$stat"
	fi
	if [ -e "continue.sav" ];
	then
		stat=$(stat -f "%Sm" -t "%Y-%m-%d @ %H:%M" continue.sav)
		contsav="$stat"
	fi
	menuitem=$(dialog --title "FTL Save Backup" --keep-tite --no-cancel --no-ok --menu "Backup an FTL saved game to another file. Note that you may have a non-AE saved game. This is for AE saves only.\n(*) ae_prof.sav: $aesav\n(*) continue.sav: $contsav" 16 55 5 "Backup" "Backup saved game" "Restore" "Restore saved game" "Rename" "Rename saved game (TODO)" "Delete" "Delete saved game (TODO)" "Quit" "Quit" 2>&1 >/dev/tty)
	# Return status of non-zero indicates cancel
	if [ $? -eq 0 ]
	then
		case $menuitem in
		Backup)
			if [ -e "continue.sav" ];
			then
				while true; do
					filename=$(dialog --title "Enter filename" --keep-tite --inputbox "Enter the filename for the saved game" 10 45 2>&1 >/dev/tty)
				    res=$?
					filename="${filename#"${filename%%[![:space:]]*}"}"
				    filename="${filename%"${filename##*[![:space:]]}"}"
					if [ $res -eq 0 ];
					then
						if [ -z ${filename} ];
						then
							dialog --msgbox "Must enter a filename." 5 60
						else
							save=true;
							aeproffn=${filename%".prof.ae.sav.bak"}".prof.ae.sav.bak"
							echo $aeproffn
							if [ -e $aeproffn ];
							then
								stat=$(stat -f "%Sm" -t "%Y-%m-%d @ %H:%M" "$aeproffn")
								dialog --yesno "A file named '$aeproffn' already exists (modified $stat). Overwrite?" 6 60
								if [ $? -ne 0 ]; then # no
									save=false
								fi
							fi
							if [ "$save" = true ];
							then
								aecontfn=${filename%".cont.ae.sav.bak"}".cont.ae.sav.bak"
								echo $aecontfn
								if [ -e $aecontfn ];
								then
									stat=$(stat -f "%Sm" -t "%Y-%m-%d @ %H:%M" "$aecontfn")
									dialog --yesno "A file named '$aecontfn' already exists (modified $stat). Overwrite?" 6 60
									if [ $? -ne 0 ]; then # no
										save=false
									fi
								fi
							fi
							if [ "$save" = true ];
							then
								cp -f "ae_prof.sav" "$aeproffn"
								cp -f "continue.sav" "$aecontfn"
								dialog --msgbox "File 'ae_prof.sav' copied to file '$aeproffn'. File 'continue.sav' copied to file '$aecontfn'." 6 60
								break
							fi
						fi
					else
						break
					fi
				done
			else
				dialog --msgbox "continue.sav doesn't exist. Make sure to save your FTL game first." 5 60
			fi
			;;
		Restore)
			while true; do
				let i=0 # define counting variable
				w=() # define working array
				for line in `ls -1 .`
				do
					echo $line
					if [[ $line == *.prof.ae.sav.bak ]]; then
						filename=${line%".prof.ae.sav.bak"}
						let i=$i+1
						cmp=""
						if [ -e "ae_prof.sav" ];
						then
							cmp --silent "$line" "ae_prof.sav"
							if [ $? -eq 0 ]; then
								cmp+="p"
							fi
						fi
						if [ -e "continue.sav" ];
						then
							cmp --silent "$filename.cont.ae.sav.bak" "continue.sav"
							if [ $? -eq 0 ]; then
								cmp+="c"
							fi
						fi
						if [ -z ${cmp} ]
						then
							cmp=""
						else
							cmp=" ($cmp)"
						fi	
						stat=$(stat -f "%Sm" -t "%Y-%m-%d @ %H:%M" "$line")
						w+=("$line" ${line%".prof.ae.sav.bak"}$cmp" ($stat)" )
					fi
				done
				if [ ${#w[@]} -eq 0 ]
				then # no items
					dialog --msgbox "No save backups found. Looking for files ending in '.prof.ae.sav.bak'." 6 60
					break
				else # have items
					echo ${w[@]}
					file=$(dialog --title "Select file to restore" --keep-tite --no-tags --menu "Choose a save to restore to ae_prof.sav and continue.sav (copied files will remain). (pc) indicates this save has the same contents as ae_prof.sav and continue.sav." 15 60 10 "${w[@]}" 2>&1 >/dev/tty) # show dialog and store output
					if [ $? -eq 0 ]; then # continue
						save=true;
						contfn=${file%".prof.ae.sav.bak"}".cont.ae.sav.bak"
						if [ -ne $contfn ];
						then
							dialog --msgbox "File '$contfn' not found. Both '$file' and '$contfn' files are required." 6 60
							save=false
						fi
						if [ "$save" = true ];
						then
							if [ -e "ae_prof.sav" ];
							then
								cmp --silent "$file" "ae_prof.sav"
								if [ $? -eq 0 ]; then
									if [ -e "continue.sav" ];
									then
										cmp --silent "$contfn" "continue.sav"
										if [ $? -eq 0 ];
										then
											dialog --msgbox "File '$file' is the same as 'ae_prof.sav' and file '$contfn' is the same as 'continue.sav' (if it exists). No reason to overwrite." 8 60
											save=false
										fi
									fi
								fi
							fi
							if [ "$save" = true ];
							then
								if [ -e "ae_prof.sav" ] || [ -e "continue.sav" ];
								then
									aestat="N/A"
									svstat="N/A"
									contstat="N/A"
									contsvstat="N/A"
									if [ -e "ae_prof.sav" ]; then aestat=$(stat -f "%Sm" -t "%Y-%m-%d @ %H:%M" "ae_prof.sav"); fi
									if [ -e $file ]; then svstat=$(stat -f "%Sm" -t "%Y-%m-%d @ %H:%M" "$file"); fi
									if [ -e "continue.sav" ]; then contstat=$(stat -f "%Sm" -t "%Y-%m-%d @ %H:%M" "continue.sav"); fi
									if [ -e $contfn ]; then contsvstat=$(stat -f "%Sm" -t "%Y-%m-%d @ %H:%M" "$contfn"); fi
									dialog --yesno "Files named 'ae_prof.sav' and/or 'continue.sav' already exist (modified $aestat and $contstat respectively). Overwrite with files '$file' and '$contfn' (modified $svstat and $contsvstat respectively)?" 10 70
									if [ $? -ne 0 ]; then # no
										save=false
									fi
								fi
								if [ "$save" = true ];
								then
									line="File '$file' restored to 'ae_prof.sav'."
									cp -f "$file" "ae_prof.sav"
									if [ -e $contfn ]; then
										cp -f "$contfn" "continue.sav"
										line=" File '$contfn' restored to 'continue.sav'."
									fi
									dialog --msgbox "$line" 6 60
									break
								fi
							fi
						fi
					else
						break
					fi
				fi
			done
			;;
		Quit)
			break
			;; 
		esac
	else
		echo "Cancelled."
	fi
done
