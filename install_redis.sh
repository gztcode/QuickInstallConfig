#!/bin/bash  
  
# 用户
REDIS_USER="reids"
# Redis 版本  
REDIS_VERSION="7.0.0"  
REDIS_PORT=6379
SENTINEL_PORT=26379
# 安装目录  
CONF_DIR="/etc/redis"  
DATA_DIR="/var/lib/redis"  
LOG_DIR="/var/log/redis"  

# Redis 可执行文件目录  
REDIS_BIN="/usr/local/bin"  
  
# Redis 配置文件  
REDIS_CONF="${CONF_DIR}/redis.conf"  
SENTINEL_CONF="${CONF_DIR}/sentinel.conf"  

# 检查依赖  
echo "Checking for dependencies..."  
yum install -y gcc make wget  

# 创建 Redis 用户和组（如果尚未存在）  
echo "Creating ${REDIS_USER} user and group if they don't exist..."  
echo "Creating Redis user and group..."  
sudo groupadd ${REDIS_USER}  
sudo useradd -r -g ${REDIS_USER} -s /sbin/nologin ${REDIS_USER}  
 

# 创建必要的目录  
echo "Creating necessary directories..."  
mkdir -p "${CONF_DIR}" "${DATA_DIR}" "${LOG_DIR}"  
chown -R ${REDIS_USER}:${REDIS_USER} "${DATA_DIR}" "${LOG_DIR}"  

# 下载并解压 Redis 源代码  
echo "Downloading and extracting Redis source code..."  
cd /usr/local/src || exit 1  
find . -type f -name "redis.tar.gz" -exec rm -f {} \;
wget -nc "http://download.redis.io/releases/redis-${REDIS_VERSION}.tar.gz" -O redis.tar.gz  
tar -xzf redis.tar.gz  
cd "redis-${REDIS_VERSION}" || exit 1  
  
# 编译 Redis  
echo "Compiling Redis..."  
make  
  
# 安装 Redis  
echo "Installing Redis..."  
make install  
  
# 配置 Redis  
echo "Configuring Redis..."  
cp redis.conf "${REDIS_CONF}" 
cp sentinel.conf "${SENTINEL_CONF}"
chown ${REDIS_USER}:${REDIS_USER} "${REDIS_CONF}" "${SENTINEL_CONF}"
   
# 修改REDIS_CONF配置文件中的一些默认设置（可选）  
sed -i "s|^dir .*|dir $DATA_DIR|" "${REDIS_CONF}"
sed -i "s|^logfile .*|logfile \"$LOG_DIR/redis-$REDIS_PORT.log\"|" "${REDIS_CONF}"
sed -i "s|^dbfilename .*|dbfilename dump$REDIS_PORT.rdb|" "${REDIS_CONF}"
sed -i "s|^port .*|port $REDIS_PORT|" "${REDIS_CONF}"
sed -i "s|^pidfile .*|pidfile /var/run/redis-$REDIS_PORT.pid|" "${REDIS_CONF}"
sed -i 's/^daemonize no$/daemonize yes/' "${REDIS_CONF}"
sed -i 's/^protected-mode yes$/protected-mode no/' "${REDIS_CONF}"
sed -i 's/^bind/# bind/' "${REDIS_CONF}"

# 修改SENTINEL_CONF配置文件中的一些默认设置（可选）  
sed -i "s|^dir .*|dir $DATA_DIR|" "${SENTINEL_CONF}"
sed -i "s|^logfile .*|logfile \"$LOG_DIR/redis_$SENTINEL_PORT.log\"|" "${SENTINEL_CONF}"
# sed -i "s|^dbfilename .*|dbfilename dump$SENTINEL_PORT.rdb|" "${SENTINEL_CONF}"
sed -i "s|^port .*|port $SENTINEL_PORT|" "${SENTINEL_CONF}"
sed -i "s|^pidfile .*|pidfile /var/run/redis-sentinel-$SENTINEL_PORT.pid|" "${SENTINEL_CONF}"
sed -i 's/^daemonize no$/daemonize yes/' "${SENTINEL_CONF}"
sed -i 's/^protected-mode yes$/protected-mode no/' "${SENTINEL_CONF}"
sed -i 's/^bind/# bind/' "${SENTINEL_CONF}"



# 添加 Redis 到系统服务（使用 systemd）  
# echo "Adding Redis to systemd..."  
cat <<EOL > /etc/systemd/system/redis.service
[Unit]
Description=Redis In-Memory Data Store
After=network.target

[Service]
User=${REDIS_USER}
Group=${REDIS_USER}
ExecStart=${REDIS_BIN}/redis-server ${REDIS_CONF}
ExecStop=${REDIS_BIN}/redis-cli shutdown
Restart=always
WorkingDirectory=${DATA_DIR}
TimeoutStopSec=30

[Install]
WantedBy=multi-user.target
EOL
 


# 重新加载 systemd 配置并启动 Redis 服务  
echo "Reloading systemd configuration and starting Redis service..."  
systemctl daemon-reload  
systemctl start redis  
systemctl enable redis  
  
# 清理临时文件  
echo "Cleaning up..."  
cd ..  
rm -rf "redis-${REDIS_VERSION}" redis.tar.gz  
  
# 输出安装完成信息  
echo "Redis ${REDIS_VERSION} installed and configured successfully!"  
echo "Redis is now running as a systemd service."
echo "Redis is now running 'redis-server ${REDIS_CONF}'"
echo "Redis Sentinel is now running 'redis-sentinel ${SENTINEL_CONF}'"