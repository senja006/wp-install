#!/bin/bash -e
#ssh senja006@sra.webhost1.ru -p '9999' 'bash -s' < wp-options-server.sh

clear

#файл для установки настроек сервера
name-temp-file='tmp-options-server.sh'
echo '#!/bin/bash -e' > $name-temp-file

echo "Это настройка локального сервера? (y/n)"
read -e islocalsetup

#добавление ssh доступа к хостингу
if [ "$islocalsetup" == n ] ; then
	echo "Введите строку подключения ssh к хостингу (по умолчанию: senja006@sra.webhost1.ru -p '9999')"
	read -e sshconnect
		sshconnect=${sshconnect:-senja006@sra.webhost1.ru -p '9999'}

	echo 'Путь к папке проекта на сервере?: '
	read -e project-path

	#ssh-keygen -t rsa
	echo "Добавить ключи на хостинг для ssh доступа? (y/n): "
	read -e addkey
	if [ "$addkey" == y ] ; then
		echo "Путь к публичному файлу ключа (по умолчанию: /Users/senja006/.ssh/id_rsa.pub): "
		read -e rsapub
			rsapub=${rsapub:-/Users/senja006/.ssh/id_rsa.pub}
		ssh-copy-id -i $rsapub $sshconnect
	fi
fi

#установка wp-cli
if [ "$islocalsetup" == n ] ; then
	echo "Установить wp-cli? (y/n): "
	read -e installwpcli
	if [ "$installwpcli" == y ] ; then
		cat >> $name-temp-file <<EOL

echo "Скачиваем wp-cli..."
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar

echo "Проверка установки"
php wp-cli.phar --info

echo "alias wp='~/wp-cli.phar'" >> .bashrc
source .bashrc
EOL

	fi
fi

echo 'cd $project-path' >> $name-temp-file

#настройка репозитория
echo "SSH удаленного репозитория?: "
read -e gitremote

cat >> $name-temp-file <<EOL

echo "Скачивание .gitignore..."
curl -L -o '.gitignore' https://raw.githubusercontent.com/github/gitignore/master/WordPress.gitignore
echo ".DS_Store" >> .gitignore
echo "._.DS_Store" >> .gitignore
echo ".idea" >> .gitignore
EOL

cat >> $name-temp-file <<EOL

echo "Инициализация репозитория..."
git init
EOL

#бекап базы данных при каждом коммите
cat >> $name-temp-file <<EOL

echo "Установка локального git хука pre-commit..."
echo "#!/bin/bash -e" >> .git/hooks/pre-commit
echo "wp db export wp-db.sql" >> .git/hooks/pre-commit
echo "git add wp-db.sql" >> .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
EOL

#добавление удаленного репозитория
echo "git remote add origin $gitremote" >> $name-temp-file

#первый commit
echo "Делать стартовый коммит? (y/n): "
read -e first-commit

if [ "$first-commit" == y ] ; then
	cat >> $name-temp-file <<EOL

echo "Push в удаленный репозиторий..."
git add .
git commit -m "Старт проекта"
git checkout -b dev
git merge master
git push -u origin --all
EOL
fi

#pull
echo "Выполнить pull? (y/n): "
read -e git-pull

if [ "$git-pull" == y ] ; then
	echo "git pull origin" >> $name-temp-file
fi

#запуск файла настройки сервера
if [ "$islocalsetup" == y ] ; then
	#echo ""
	sh $name-temp-file
fi
if [ "$islocalsetup" == n ] ; then
	#echo ""
	ssh $sshconnect 'bash -s' < $name-temp-file
fi

#удаление файла
echo "Хотите настроить еще сервер? (y/n): "
read -e isother
if [ "$isother" == y ] ; then
	sh wp-options-server.sh
fi
if [ "$isother" == n ] ; then
	echo ""
	#rm $name-temp-file
fi






