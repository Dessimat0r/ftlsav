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
while true; do
	aesav="(no ae_prof.sav exists)"
	if [ -e "ae_prof.sav" ];
	then
		stat=$(stat -f "%Sm" -t "%Y-%m-%d @ %H:%M" ae_prof.sav)
		aesav=" (ae_prof.sav exists (modified $stat))"
	fi
	aesavstat=$(stat -f "%Sm" -t "%Y-%m-%d @ %H:%M" $filename)
	menuitem=$(dialog --title "FTL Save Backup" --keep-tite --no-cancel --no-ok --menu "Backup an FTL saved game to another file$aesav." 14 55 5 "Backup" "Backup saved game" "Restore" "Restore saved game" "Rename" "Rename saved game (TODO)" "Delete" "Delete saved game (TODO)" "Quit" "Quit" 2>&1 >/dev/tty)
	# Return status of non-zero indicates cancel
	if [ $? -eq 0 ]
	then
		case $menuitem in
		Backup)
			if [ -e "ae_prof.sav" ];
			then
				while true; do
					filename=$(dialog --title "Enter filename" --keep-tite --inputbox "Enter the filename for the saved game" 10 45 2>&1 >/dev/tty)
					if [ $? -eq 0 ];
					then
						filename=${filename%".ae.sav.bak"}".ae.sav.bak"
						if [ $filename != ".ae.sav.bak" ];
						then
							echo $filename
							save=true;
							if [ -e $filename ];
							then
								stat=$(stat -f "%Sm" -t "%Y-%m-%d @ %H:%M" $filename)
								dialog --yesno "A file named '$filename' already exists (modified $stat). Overwrite?" 6 60
								if [ $? -ne 0 ]; then # no
									save=false
								fi
							fi
							if [ "$save" = true ];
							then
								cp -f "ae_prof.sav" "$filename"
								dialog --msgbox "File 'ae_prof.sav' copied to file '$filename'." 5 60
								break
							fi
						else
							dialog --msgbox "Must enter a filename." 5 60
						fi
					else
						break
					fi
				done
			else
				dialog --msgbox "ae_prof.sav doesn't exist. Make sure to save your FTL game first." 5 60
			fi
			;;
		Restore)
			let i=0 # define counting variable
			w=() # define working array
			for line in `ls -1 .`
			do
				if [[ $line == *.ae.sav.bak ]]; then
					let i=$i+1
					cmp=""
					if [ -e "ae_prof.sav" ];
					then
						cmp --silent "$line" "ae_prof.sav"
						if [ $? -eq 0 ]; then
							cmp="*"
						fi
					fi
					stat=$(stat -f "%Sm" -t "%Y-%m-%d @ %H:%M" $line)
					w+=("$line" ${line%".ae.sav.bak"}$cmp" ($stat)" )
				fi
			done
			if [ ${#w[@]} -eq 0 ]
			then # no items
				dialog --msgbox "No save backups found (they must end in .ae.sav.bak)." 5 60
			else # have items
				echo ${w[@]}
				file=$(dialog --title "Select file to restore" --keep-tite --no-tags --menu "Choose a file to restore to ae_prof.sav (copied file will remain). * indicates this file has the same contents as ae_prof.sav." 15 60 10 "${w[@]}" 2>&1 >/dev/tty) # show dialog and store output
				if [ $? -eq 0 ]; then # continue
					save=true;
					if [ -e "ae_prof.sav" ];
					then
						cmp --silent "$file" "ae_prof.sav"
						if [ $? -eq 0 ]; then
							dialog --msgbox "File '$file' is the same as 'ae_prof.sav' No reason to overwrite." 6 60
							save=false
						fi
					fi
					if [ "$save" = true ];
					then
						if [ -e "ae_prof.sav" ];
						then
							aestat=$(stat -f "%Sm" -t "%Y-%m-%d @ %H:%M" "ae_prof.sav")
							svstat=$(stat -f "%Sm" -t "%Y-%m-%d @ %H:%M" "$file")
							dialog --yesno "A file named 'ae_prof.sav' already exists (modified $aestat). Overwrite with file '$file' (modified $svstat)?" 8 60
							if [ $? -ne 0 ]; then # no
								save=false
							fi
						fi	
						if [ "$save" = true ];
						then
							cp -f "$file" "ae_prof.sav"
							dialog --msgbox "File '$file' restored to 'ae_prof.sav'." 6 60
						fi
					fi
				fi
			fi
			;;
		Quit)
			break
			;; 
		esac
	else
		echo "Cancelled."
	fi
done
