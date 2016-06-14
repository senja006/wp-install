echo "Параметры ssh подключения (по умолчанию senja006@sra.webhost1.ru)? :"
	read -e ssh_connect
		ssh_connect=${ssh_connect:-senja006@sra.webhost1.ru}
	echo "Порт ssh подключения (по умолчанию 9999)? : "
	read -e ssh_port
		ssh_port=${ssh_port:-9999}
	echo "Папка проекта на удаленном сервере?: "
	read -e remote_folder
	echo "Забирать верстку для удаленного сервера (это для деплоя верстки)? (y/n): "
	read -e grep_markup

	dir=`pwd`
	name_file="wp-remote-dev-pull.sh"

	cat >> $name_file <<EOL

#!/bin/bash -e
#ssh $ssh_connect -p "$ssh_port" 'bash -s' < $dir/$name_file
EOL
if [ "$grep_markup" == "y" ]; then
	cat >> $name_file <<EOL

cd ..
msg=`git log --oneline -1`
cd server
files=`ls | grep -v wp-remote-dev-pull.sh`
rm -r $files
cd ..
cp -a `pwd`/dev/* `pwd`/server/
cd server
git add .
git commit -m "$msg"
git push origin $branch
cd ..
EOL
fi

	cat >> $name_file <<EOL

ssh $ssh_connect -p "$ssh_port" "cd $remote_folder; git pull origin $branch"
EOL