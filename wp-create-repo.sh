#!/bin/bash -e
clear

#выполнение настройки на удаленном сервере в интерактивном режиме
echo "Выполнить настройку удаленного сервера? (y/n): "
read -e install_remote_server

if [ "$install_remote_server" == "y" ]; then
	echo "Параметры ssh подключения (по умолчанию senja006@sra.webhost1.ru)"
	read -e ssh_connect
		ssh_connect=${ssh_connect:-senja006@sra.webhost1.ru}
	echo "Порт ssh подключения (по умолчанию 9999)"
	read -e ssh_port
		ssh_port=${ssh_port:-9999}
	echo "Папка проекта на удаленном сервере?: "
	read -e remote_folder
	echo "Скопировать на удаленный сервер файл wp-config.php (в отдельном окне будет запущен файл wp-copy-config.sh. После клонирования репозитория в нем нужно продолжить процесс)? (y/n): "
	read -e copy_config

	if [ "$copy_config" == "y" ]; then
		echo "Путь к корню на удаленном сервере (по умолчанию: /home/senja006)?: "
		read -e remote_path
			remote_path=${remote_path:-/home/senja006}

		dir=`pwd`
		cat >> wp-copy-config.sh <<EOL

#!/bin/bash -e
cd $dir
cp wp-config.php wp-config-temp.php
open -a "Sublime text" wp-config-temp.php
echo "Копировать файл на удаленный сервер?: "
read -e start_copy
scp -P $ssh_port $dir/wp-config-temp.php $ssh_connect:$remote_path/$remote_folder
ssh $ssh_connect -p "$ssh_port" "cd $remote_folder; mv wp-config-temp.php wp-config.php"
rm wp-config-temp.php
rm wp-copy-config.sh
EOL
		chmod +x wp-copy-config.sh
		open -a "Terminal" `pwd`/wp-copy-config.sh
	fi

	dir=`pwd`

	ssh -t $ssh_connect -p "$ssh_port" "cd $remote_folder && $(<$dir/wp-create-repo.sh)"
	#ssh -t senja006@sra.webhost1.ru -p "9999" "cd wp-vector.yarkevich.ru && $(</Users/senja006/Documents/Frontend/Wordpress/wp-vector/wp-create-repo.sh)"
	exit
fi

echo "Проект уже есть в удаленном хранилище git (github, bitbucket)? (y/n): "
read -e project_exist
echo "SSH удаленного репозитория? (bitbucket, github или др.): "
read -e gitremote
echo "Используется база данных? (y/n): "
read -e used_base
echo "Название рабочей ветки? (например, master, dev...): "
read -e branch
echo "Вызов wp-cli (например, php /home/senja006/wp-cli.phar. По умолчанию: wp)? : "
read -e alias_wp_cli
	alias_wp_cli=${alias_wp_cli:-wp}
echo "URL на другом сервере (для поиска и замены в базе)?: "
read -e old_url
echo "URL на текущем сервере (для поиска и замены в базе)?: "
read -e new_url
echo "Создать скрипт для принудительного обновления удаленного сервера? (y/n): "
read -e remote_dev_server_pull

if [ "$project_exist" == "n" ]; then
	echo "Инициализация репозитория..."
	git init

	echo "Добавлен удаленный репозиторий"
	git remote add origin $gitremote

	if [ "$used_base" == "y" ]; then
		echo "Бекап базы данных"
		$alias_wp_cli db export "wp-db-$branch.sql"
	fi

	echo "Скачать gitignore для Wordpress? (y/n): "
	read -e load_gitignore
	if [ "$load_gitignore" == "y" ]; then
		echo "Скачивание .gitignore..."
		curl -L -o '.gitignore' https://raw.githubusercontent.com/github/gitignore/master/WordPress.gitignore
		cat >> .gitignore <<EOL

!.htaccess
!wp-content/uploads/
.DS_Store
._.DS_Store
.idea

wp-install.sh
wp-options.sh
wp-create-repo.sh
EOL
	fi

	echo "Первый коммит"
	git add .
	git commit -m "Старт проекта"
	if [ "$branch" == "master" ]; then
		git push -u origin --all
	else
		git checkout -b $branch
		git merge master
		git push -u origin --all
	fi
else
	echo "Клонирование репозитория..."
	rm -r *
	git clone $gitremote .
	git checkout --track origin/$branch

	#установка базы данных
	if [ "$used_base" == "y" ]; then
		echo "Для продолжения необходимо скопировать wp-config.php и создать базу данных. Продолжать? (y/n): "
		read -e wp_config_copy

		$alias_wp_cli db import "wp-db-$branch.sql"
		$alias_wp_cli search-replace $old_url $new_url
	fi
fi

#установка хуков
if [ "$used_base" == "y" ]; then
	#перед коммитом
	echo "Настройка хука pre-commit..."
	cat >> .git/hooks/pre-commit <<EOL

#!/bin/bash -e
$alias_wp_cli db export wp-db-$branch.sql
git add wp-db-$branch.sql
EOL
	chmod +x .git/hooks/pre-commit
fi

#после pull
echo "Добавить git хук после pull для импорта базы (!!! не добавлять для master)? (y/n): "
read -e add_post_merge
if [ "$add_post_merge" == "y" ]; then
	echo "Настройка хука post-merge..."
	cat >> .git/hooks/post-merge <<EOL

#!/bin/bash -e
$alias_wp_cli db import "wp-db-$branch.sql"
$alias_wp_cli search-replace $old_url $new_url
EOL
	chmod +x .git/hooks/post-merge
fi

#создание скрипта для принудительного обновления удаленного сервера
if [ "$remote_dev_server_pull" == "y" ]; then
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
	name_file_remote_update="remote-server-update.sh"

	cat > $name_file_remote_update <<EOL

#!/bin/bash -e
#ssh $ssh_connect -p "$ssh_port" 'bash -s' < $dir/$name_file_remote_update
EOL
	if [ "$grep_markup" == "y" ]; then
		echo "Название папки с проектом (server, server-wp)?: "
		read -e local_folder

		cat >> $name_file_remote_update <<EOL

cd ..
msg=\`git log --oneline -1\`
cd $local_folder
files=\`ls | grep -v $name_file_remote_update\`
rm -r \$files
cd ..
cp -r dev/* $local_folder
cd $local_folder
git add .
git commit -m "\$msg"
git push origin $branch
#cd ..
EOL
	fi

	cat >> $name_file_remote_update <<EOL

ssh $ssh_connect -p "$ssh_port" "cd $remote_folder; git pull origin $branch"
EOL
fi


#=========================
#добавления ключа на удаленный сервер для ssh подключения
#ssh-keygen -t rsa
#ssh-copy-id -i /Users/senja006/.ssh/id_rsa.pub senja006@sra.webhost1.ru -p "9999"

#=========================
#установка wp-cli на удаленный сервер
#curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
#chmod +x wp-cli.phar

#=========================
#копирование файла на удаленный сервер
#scp -P 9999 wp-install-server.sh senja006@sra.webhost1.ru:/home/senja006/wp-test.yarkevich.ru









