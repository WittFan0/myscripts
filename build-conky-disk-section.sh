devs=$(find /dev -maxdepth 1 -type b -name "sd[a-z]" -exec basename "{}" ";" | sort )
	if [ "$devs" ] ; then
		printf "\${voffset %s}\${color1}Disk IO \${color2}\${hr}\n\${color0}dev\${alignr 165}write\${alignr 122}read\${alignr 90}temp\n" $vspace
		for dev in $devs ; do
			printf "\${color3}%s\${alignr 110}\${color %s}\${diskio_write %s}\${alignr 50}\${color8}\${diskio_read %s}\${alignr 20}\${color %s}\${hddtemp /dev/%s}\${if_match \"\${hddtemp /dev/%s}\" != \"N/A\"}\${lua_parse deg}\${else} \${endif}\${alignr 5}\${color9}\${diskiograph %s 12,70 %s %s 0 -t -l}\n" $dev $fs_pct_color $dev $dev $fs_pct_color $dev $dev $dev $cpugd1_color $cpugd2_color
		done
	else
		printf "#\n"
	fi