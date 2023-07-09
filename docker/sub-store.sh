#!/bin/sh

gitPath="/"
rootPath="/Sub-Store"
backend="$rootPath/Back"
web="$rootPath/Front"

echo -e "======================== 1、更 新 仓 库 ========================\n"

    cd "$rootPath/Front" && git reset --hard && git pull 
    sleep 2s
    cd "$rootPath/Back" && git reset --hard && git pull
    sleep 2s
    cd "$rootPath/Docker" && git reset --hard && git pull
    sleep 2s

echo -e "==============================================================\n"

echo -e "======================== 2. 启动nginx ========================\n"

    if [ ! -f "/etc/nginx/conf.d/front.conf" ] && [ ALLOW_IP ]; then
        echo -e "生成 nginx 配置文件\n"
        envsubst 'allow ${ALLOW_IP};deny all;' < /etc/nginx/conf.d/front.template > /etc/nginx/conf.d/front.conf    
    fi    
    nginx -s reload 2>/dev/null || nginx -c /etc/nginx/nginx.conf

echo -e "==============================================================\n"

echo -e "======================== 3、启动后端接口 ========================\n"

    # cp -r "$rootPath/Back" "$rootPath"
    cd "$backend" && pnpm install && pnpm build
    pm2 start sub-store.min.js --name "sub-store" --source-map-support --time

echo -e "==============================================================\n"

echo -e "======================== 4、启动 Sub-Store 界面 ========================\n"
    # cp -r "$rootPath/Front" "$rootPath"
    cd "$web"

    echo -e "删除自带后端地址，追加配置环境变量配置的后端地址\n"

    sed -i "/ENV/d" "$web/.env.production"
    if [ DOMAIN ]; then 
        echo "VITE_API_URL = '${DOMAIN}'" >>"$web/.env.production"
    fi    

    echo -e "执行编译前端静态资源\n"    
    cd "$web" && pnpm install && pnpm build
    echo -e "结束编译，UI 界面已生成\n"

echo -e "==============================================================\n"

pm2 log sub-store
exec "$@"
