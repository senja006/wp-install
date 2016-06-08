#!/bin/bash -e
clear
echo "Это локальная установка? (y/n)"
read -e islocalsetup

#скачивание composer.json
#echo "Скачивание composer.json"
#curl -L -o 'composer.json' https://raw.githubusercontent.com/senja006/wp-composer/master/composer.json

#установка composer
#echo "Установка composer"
#curl -sS https://getcomposer.org/installer | php

#установка зависимостей composer
#echo "Установка зависимостей composer"
#php composer.phar install

#скачиваем русскую версию Wordpress
echo "============================================"
echo "Скачивание Wordpress..."
echo "============================================"
wp core download --locale=ru_RU

#устанавливаем дополнительные настройки Wordpress
echo "============================================"
echo "Установка дополнительных настроек..."
echo "============================================"
cat >> wp-config-sample.php <<EOL
// disable revisions
define( 'WP_POST_REVISIONS', false );
 
// autosave interval
define( 'AUTOSAVE_INTERVAL', 240 ); // the value should be in seconds
 
// disable editing theme/plugin files from wp-admin
define( 'DISALLOW_FILE_EDIT', true );
 
// enabling "trash" for media items
define( 'MEDIA_TRASH', true );
 
// moving wp-content
// define( 'WP_CONTENT_DIR', dirname( __FILE__ ) . '/stuff' );
// define( 'WP_CONTENT_URL', 'http://exam.pl/stuff' );
 
// moving uploads
// define( 'UPLOADS', 'files' );
 
// change "emtpy trash" settings
define( 'EMPTY_TRASH_DAYS', 10 ); // 10 days

// при обновлении Wordpress пропустить обновление тем или появление после удаления
define( 'CORE_UPGRADE_SKIP_NEW_BUNDLED', true );

// ключ Wordpress
// define( 'WPCOM_API_KEY', 'YourKeyHere' );

// установка темы по умолчанию
// define( 'WP_DEFAULT_THEME', 'default-theme-folder-name' );

// запрет автоматического обновления
// define( 'AUTOMATIC_UPDATER_DISABLED', true );
EOL

#настройки
echo "============================================"
echo "Установка основных настроек..."
echo "============================================"
echo "Имя базы данных: "
read -e dbname
echo "Пользователь базы данных: "
read -e dbuser
echo "Пароль базы данных: "
read -e dbpass
echo "Префикc (wp_): "
read -e dbprefix
	dbprefix=${dbprefix:-wp_}
#создания файла настроек
mv wp-config-sample.php wp-config.php
#запись настроек в файл
perl -pi -e "s'database_name_here'"$dbname"'g" wp-config.php
perl -pi -e "s'username_here'"$dbuser"'g" wp-config.php
perl -pi -e "s'password_here'"$dbpass"'g" wp-config.php
perl -pi -e "s/\'wp_\'/\'$dbprefix\'/g" wp-config.php
#set WP salts
perl -i -pe'
  BEGIN {
    @chars = ("a" .. "z", "A" .. "Z", 0 .. 9);
    push @chars, split //, "!@#$%^&*()-_ []{}<>~\`+=,.;:/?|";
    sub salt { join "", map $chars[ rand @chars ], 1 .. 64 }
  }
  s/put your unique phrase here/salt()/ge
' wp-config.php
#create uploads folder and set permissions
mkdir wp-content/uploads
chmod 775 wp-content/uploads

#создание базы данных
echo "============================================"
echo "Создание базы данных"
echo "============================================"

echo "Создать базу данных? (y/n)"
read -e setupmysql
if [ "$setupmysql" == y ] ; then
	echo "Используется XAMPP?: "
	read -e usexampp
	echo "Администратор базы данных: "
	read -e mysqluser
	echo "Пароль администратора: "
	read -s mysqlpass
	echo "Хост (По умолчанию 'localhost'): "
	read -e mysqlhost
		mysqlhost=${mysqlhost:-localhost}

	dbsetup="create database $dbname DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;GRANT ALL PRIVILEGES ON $dbname.* TO $dbuser@$mysqlhost IDENTIFIED BY '$dbpass';FLUSH PRIVILEGES;"
	if [ "$usexampp" == y ] ; then
		/Applications/XAMPP/bin/mysql -u $mysqluser -p$mysqlpass -e "$dbsetup"
	else
		mysql -u $mysqluser -p$mysqlpass -e "$dbsetup"
	fi
	if [ $? != "0" ]; then
		echo "============================================"
		echo "[Error]: Ошибка создания базы данных."
		echo "============================================"
		exit 1
	fi
fi

#создание виртуального хоста
echo "============================================"
echo "Создание виртуального хоста"
echo "============================================"

echo "Название виртуального хоста (example.local): "
read -e localhostname

rootHost=${PWD}
cat >> /Applications/XAMPP/etc/extra/httpd-vhosts.conf <<EOL
#$localhostname
<VirtualHost *:80>
    ServerName $localhostname
    DocumentRoot "$rootHost"
    <Directory "$rootHost">
        Options Indexes FollowSymLinks Includes ExecCGI 
        AllowOverride All 
        Require all granted 
    </Directory> 
    ErrorLog "logs/site.local-error_log" 
</VirtualHost> 
EOL
sudo sh -c "echo \"127.0.0.1	$localhostname\" >> /private/etc/hosts"

#устанавливаем Wordpress
echo "============================================"
echo "Установка Wordpress"
echo "============================================"

echo "Название сайта"
read -e wptitle
echo "Логин администратора"
read -e wpadmin
echo "Пароль администратора"
read -e wpadpass
echo "Email администратора"
read -e wpemail

wp core install --url=$localhostname --title=$wptitle --admin_user=$wpadmin --admin_password=$wpadpass --admin_email=$wpemail

#удаление файлов
rm wp-install.sh








