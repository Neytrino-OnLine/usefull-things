#!/bin/sh

VERSION="beta 0"
CRON_FILE='/opt/var/spool/cron/crontabs/root'
COLUNS="`stty -a | awk -F"; " '{print $3}' | grep "columns" | awk -F" " '{print $2}'`"

function headLine	#1 - заголовок	#2 - скрыть полосу под заголовком	#3 - добавить пустые строки для прокрутки
	{
	if [ -n "$3" ];then
		local COUNTER=24
		while [ "$COUNTER" -gt "0" ];do
			echo -e "\033[30m█\033[39m"
			local COUNTER=`expr $COUNTER - 1`
		done
	fi
	if [ "`expr $COLUNS / 2 \* 2`" -lt "$COLUNS" ];then
		local WIDTH="`expr $COLUNS / 2 \* 2`"
		local PREFIX=' '
	else
		local WIDTH=$COLUNS
		local PREFIX=""
	fi
	if [ -n "$1" ];then
		clear
		local TEXT=$1
		local LONG=`echo ${#TEXT}`
		local SIZE=`expr $WIDTH - $LONG`
		local SIZE=`expr $SIZE / 2`
		local FRAME=`awk -v i=$SIZE 'BEGIN { OFS=" "; $i=" "; print }'`
		if [ "`expr $LONG / 2 \* 2`" -lt "$LONG" ];then
			local SUFIX=' '
		else
			local SUFIX=""
		fi
		echo -e "\033[30m\033[47m$PREFIX$FRAME$TEXT$FRAME$SUFIX\033[39m\033[49m"
	else
		echo -e "\033[30m\033[47m`awk -v i=$COLUNS 'BEGIN { OFS=" "; $i=" "; print }'`\033[39m\033[49m"
	fi
	if [ -n "$MODE" -a -n "$1" -a -z "$2" ];then
		local LONG=`echo ${#MODE}`
		local SIZE=`expr $COLUNS - $LONG - 1`
		echo "`awk -v i=$SIZE 'BEGIN { OFS=" "; $i=" "; print }'`$MODE"
	elif [ -z "$MODE" -a -n "$1" -a -z "$2" ];then
		echo ""
	fi
	}

function messageBox	#1 - текст	#2 - цвет
	{
	local TEXT=$1
	local COLOR=$2
	local LONG=`echo ${#TEXT}`
	if [ ! "$LONG" -gt "`expr $COLUNS - 4`" ];then
		local TEXT="│ $TEXT │"
		local SIZE=`expr $COLUNS - $LONG - 4`
		local SIZE=`expr $SIZE / 2`
		local SPACE=`awk -v i=$SIZE 'BEGIN { OFS=" "; $i=" "; print }'`
	else
		local LONG=`expr $COLUNS - 4`
		local SPACE=""
	fi
	if [ "$COLUNS" = "80" ];then
		echo -e "$COLOR$SPACE┌─`awk -v i=$LONG 'BEGIN { OFS="─"; $i="─"; print }'`─┐\033[39m\033[49m"
		echo -e "$COLOR$SPACE$TEXT\033[39m\033[49m"
		echo -e "$COLOR$SPACE└─`awk -v i=$LONG 'BEGIN { OFS="─"; $i="─"; print }'`─┘\033[39m\033[49m"
	else
		echo -e "$COLOR$SPACE□-`awk -v i=$LONG 'BEGIN { OFS="-"; $i="-"; print }'`-□\033[39m\033[49m"
		echo -e "$COLOR$SPACE$TEXT\033[39m\033[49m"
		echo -e "$COLOR$SPACE□-`awk -v i=$LONG 'BEGIN { OFS="-"; $i="-"; print }'`-□\033[39m\033[49m"
	fi
	}

function showText	#1 - текст	#2 - цвет
	{
	local TEXT=`echo "$1" | awk '{gsub(/\\\t/,"____")}1'`
	local TEXT=`echo -e "$TEXT"`
	local STRING=""
	local SPACE=""
	IFS=$' '
	for WORD in $TEXT;do
			local WORD_LONG=`echo ${#WORD}`
			local STRING_LONG=`echo ${#STRING}`
			if [ "`expr $WORD_LONG + $STRING_LONG + 1`" -gt "$COLUNS" ];then
				echo -e "$2$STRING\033[39m\033[49m" | awk '{gsub(/____/,"    ")}1'
				local STRING=$WORD
			else
				local STRING=$STRING$SPACE$WORD
				local SPACE=" "
			fi
	done
	echo -e "$2$STRING\033[39m\033[49m" | awk '{gsub(/____/,"    ")}1'
	}

function copyRight	#1 - название	#2 - год
	{
	if [ "`date +"%C%y"`" -gt "$2" ];then
		local YEAR="-`date +"%C%y"`"
	fi
	local COPYRIGHT="© $2$YEAR rino Software Lab."
	local SIZE=`expr $COLUNS - ${#1} - ${#VERSION} - ${#COPYRIGHT} - 3`
	read -t 1 -n 1 -r -p " $1 $VERSION`awk -v i=$SIZE 'BEGIN { OFS=" "; $i=" "; print }'`$COPYRIGHT" keypress
	}

function fileBrowse	#1 - путь к текущей папке
	{
	local LIST=`ls "$1" | awk '{print NR":\t"$0}'`
	if [ -z "$LIST" ];then
		messageBox "Папка пуста." "\033[91m"
		exit
	fi
	showText "Выберите файл или папку в \"$1\":"
	echo ""
	echo "$LIST" | awk -F"\t" '{print "\t"$1, $2}'
	echo ""
	read -r -p "Ваш выбор:"
	echo ""
	REPLY=`echo "$LIST" | grep "^\$REPLY:"`
	if [ -n "$REPLY" ];then
		local SELECTED_PATH=`echo "$REPLY" | awk -F"\t" '{print $2}'`
	if [ -f "$1/$SELECTED_PATH" ];then
		REPLY="$1/$SELECTED_PATH"
	elif [ -d "$1/$SELECTED_PATH" ];then
		fileBrowse "$1/$SELECTED_PATH"
	fi
	fi
	}

function relogin
	{
	showText "\tДля того чтобы изменения вступили в силу - нужно повторно войти в систему..."
	echo ""
	echo "Войти в систему повторно?"
	echo -e "\t1: Да"
	echo -e "\t0: Нет (по умолчанию)"
	echo ""
	read -r -p "Ваш выбор:"
	echo ""
	if [ "$REPLY" = "1" ];then
		rm -rf /opt/bin/ata-setup
		login
	fi
	}

function aliasAdd
	{
	echo "Выберите файл, который нужно будет синхронизировать..."
	local LIST=`ls /tmp/mnt`
	local LIST=`ls /tmp/mnt | awk '{print $0"\ttmp/mnt/"$0}'`
	local LIST=`echo -e "Встроенное хранилище\topt\n$LIST" | awk '{print NR":\t"$0}'`
	echo ""
	echo "$LIST" | awk -F"\t" '{print "\t"$1, $2}'
	echo ""
	read -r -p "Ваш выбор:"
	echo ""
	REPLY=`echo "$LIST" | grep "^\$REPLY:"`
	if [ -n "$REPLY" ];then
		local SELECTED_PATH=`echo "$REPLY" | awk -F"\t" '{print "/"$3}'`
		if [ -d "$SELECTED_PATH" ];then
			fileBrowse "$SELECTED_PATH"
		fi
	fi
	FILE_PATH=$REPLY
	read -r -p "Введите псевдоним для выполнения:"
	echo ""
	if [ -n "$REPLY" ];then
		FILE_START=$REPLY
	else
		messageBox "Псевдоним не задан." "\033[91m"
		exit
	fi
	read -r -p "Введите псевдоним для синхронизации:"
	if [ -n "$REPLY" ];then
		FILE_SYNC=$REPLY
	else
		messageBox "Псевдоним не задан." "\033[91m"
		exit
	fi
	TEMP_PATH="/tmp/`basename $FILE_PATH`"
	echo "alias $FILE_SYNC='cat $FILE_PATH > $TEMP_PATH;chmod +x $TEMP_PATH;clear' #ata" >> /opt/etc/profile
	echo "alias $FILE_START='$TEMP_PATH' #ata" >> /opt/etc/profile
	
	messageBox "Настройка завершена."
	echo ""
	relogin
	}

function aliasDelete
	{
	echo "Удаление псевдонимов..."
	local TEMP=`cat /opt/etc/profile | grep -v '#ata$'`
	echo "$TEMP" > /opt/etc/profile
	messageBox "Псевдонимы - удалёны."
	echo ""
	relogin
	}

function mainMenu
	{
	headLine "Add Test Alias"
	if [ -n "`cat /opt/etc/profile | grep "#ata$"`" ];then
			showText "\tВ конфигурации уже есть настроенные псевдонимы."
			echo ""
			echo -e "\t1: Добавить ещё"
			echo -e "\t2: Удалить все"
			echo -e "\t0: Отмена (по умолчанию)"
			echo ""
			read -r -p "Ваш выбор:"
			echo ""
			if [ "$REPLY" = "1" ];then
				aliasAdd
			elif [ "$REPLY" = "2" ];then
				aliasDelete
			fi
	else
		aliasAdd
	fi
	headLine
	copyRight "ATA" "2025"
	clear
	rm -rf /opt/bin/ata-setup
	exit
	}

echo;while [ -n "$1" ];do
case "$1" in

-d)	headLine "USB-Storage Reconnect"
	aliasDelete
	exit
	;;

-s)	headLine "USB-Storage Reconnect"
	aliasAdd
	exit
	;;

*) headLine "Add Test Alias"
	messageBox "Введён некорректный ключ." "\033[91m"
	echo ""
	echo "Доступные ключи:
	-a: Добавление псевдонимов
	-d: Удаление всех добавленных псевдонимов"
	exit
	;;
	
esac;shift;done
mainMenu