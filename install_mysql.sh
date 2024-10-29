#!/bin/bash

# 设置 MySQL 默认端口和初始密码变量
DEFAULT_PORT=3306
PASSWORD=""

# 检查是否为 root 用户
if [ "$(id -u)"!= "0" ]; then
   echo "This script must be run as root."
   exit 1
fi

# 获取用户输入的端口和密码
read -p "请输入 MySQL 启动端口（默认 $DEFAULT_PORT）：" PORT
PORT=${PORT:-$DEFAULT_PORT}
read -p "请输入 MySQL 初始密码：" PASSWORD

# 安装 MySQL
yum install -y https://repo.mysql.com//mysql84-community-release-el9-1.noarch.rpm
yum search mysql-community
yum install -y mysql-community-server


# 初始化 MySQL
# mysqld --initialize --user=mysql --datadir=$DATA_DIR

# 启动 MySQL
echo "MySQL 启动中..."
systemctl start mysqld
systemctl enable mysqld

# 获取临时密码
TEMP_PASSWORD=$(grep 'temporary password' /var/log/mysqld.log | awk '{print $NF}')
echo "获取临时密码:${TEMP_PASSWORD} 并修改为新的密码:${PASSWORD}"
# 修改密码
mysql --connect-expired-password -u root -p"$TEMP_PASSWORD" -e "alter user 'root'@'localhost' identified by 'Abcd1234@'";
mysql -u root -p"Abcd1234@" -e "set global validate_password.policy=0;set global validate_password.length=4;ALTER USER 'root'@'localhost' IDENTIFIED BY '$PASSWORD';FLUSH PRIVILEGES;"

# 修改配置文件设置端口并将监听地址从 localhost 改为 0.0.0.0
sed -i "s/^port=.*/port=$PORT/" /etc/my.cnf
sed -i "s/^bind-address.*/bind-address = 0.0.0.0/" /etc/my.cnf

# 重启 MySQL 使端口生效
systemctl restart mysqld

echo "MySQL 8.0 安装完成，端口为 $PORT，初始密码为 $PASSWORD，现在可以通过 0.0.0.0 访问。"

mysql --connect-expired-password -u root -p";>WbMiDBt4:k" -e "alter user 'root'@'localhost' identified with mysql_native_password by 'Abcd1234@'";
