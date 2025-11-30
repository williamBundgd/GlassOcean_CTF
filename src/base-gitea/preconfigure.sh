#!/bin/bash
if [ -f "/data/fresh_install" ]; then
    echo "Configuring Gitea..."
    
    RANDOM_PASSWORD=$(head -c 16 /dev/urandom | xxd -p)
    echo "Admin password: ${ADMIN_PASSWORD:-$RANDOM_PASSWORD}"
    su -c "gitea admin user create --username gitadmin --password ${ADMIN_PASSWORD:-$RANDOM_PASSWORD} --email gitadmin@${EMAIL_DOMAIN:-domain.local} --admin=true --must-change-password=false" git
    su -c "gitea admin user delete --id 1" git  

    rm -rf /data/gitea/sessions
    openssl genrsa -nodes -out /data/gitea/jwt/private.pem 4096

    if [ -n "$DRONE_GITEA_CLIENT_ID" ] && [ -n "$DRONE_GITEA_CLIENT_SECRET_HASH" ] && [ -n "$DRONE_GITEA_URL" ]; then
        echo "Configuring OAuth2 for Drone..."
        sqlite3 /data/gitea/gitea.db "insert into oauth2_application(uid, name, client_id, client_secret, confidential_client, redirect_uris, created_unix, updated_unix) values(0, 'DroneCI', '$DRONE_GITEA_CLIENT_ID', '$DRONE_GITEA_CLIENT_SECRET_HASH',1,'[\"$DRONE_GITEA_URL\"]', 1709123975, 1709123975);"
    fi

    # Create users from the /config/users.csv file
    if [ -f "/config/users.csv" ]; then
        echo "Creating users from /config/users.csv"
        while IFS="," read -r username email password || [ -n "$username" ]; do
            # Validate that username, email and password are not empty
            if [ -z "$username" ] || [ -z "$email" ] || [ -z "$password" ]; then
                echo "Invalid user: $username"
                continue
            fi
            password=$(echo -n "$password" | tr -d '\r')
            echo "Creating user: $username"
            su -c "gitea admin user create --username $username --password $password --email $email --must-change-password=false" git

            # Create a token for the user
            sqlite3 /data/gitea/gitea.db "insert into oauth2_grant(user_id, application_id, created_unix,updated_unix) values((select id from user where name='$username'), 3, 1709123975, 1709123975);"
        done < <(tail -n +2 /config/users.csv)
    fi

    echo "Preconfiguration done"
    /tmp/postconfigure.sh &
else
    echo "Gitea already configured"
fi

echo "Starting Gitea..."
rm /tmp/preconfigure.sh
ln -s /usr/bin/entrypoint /tmp/preconfigure.sh
if [ $# -gt 0 ]; then
    exec /usr/bin/entrypoint "$@"
else
    exec /usr/bin/entrypoint /bin/s6-svscan /etc/s6
fi