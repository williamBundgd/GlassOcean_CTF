#!/bin/bash
if [ -f "/data/fresh_install" ]; then
    echo "Configuring Drone..."

    # Create the admin user
    sqlite3 /data/database.sqlite "INSERT INTO users (user_login, user_email, user_admin, user_machine, user_active, user_syncing, user_synced, user_created, user_updated, user_last_login, user_avatar, user_oauth_expiry, user_hash, user_oauth_token, user_oauth_refresh) VALUES ('gitadmin', 'gitadmin@${EMAIL_DOMAIN:-domain.local}', 1, 0, 1, 0, 0, $(date +%s), $(date +%s), $(date +%s), '', 0, '$(echo gitadmin|md5sum|cut -d ' ' -f 1|base64)', '', '');"

    # Create users from the /config/users.csv file
    if [ -f "/config/users.csv" ]; then
        i=1
        echo "Creating users from /config/users.csv"
        while IFS="," read -r username email password || [ -n "$username" ]; do
            # Validate that username, email and password are not empty
            if [ -z "$username" ] || [ -z "$email" ] || [ -z "$password" ]; then
                echo "Invalid user: $username"
                continue
            fi
            echo "Creating user: $username"
            
            PEM=$( cat /tmp/private.pem )
            FINGERPRINT=$( openssl rsa -in <(echo -n "${PEM}") -pubout -outform DER 2>/dev/null | openssl dgst -sha256 -binary | openssl enc -base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n' )
            NOW=$( date +%s )
            IAT="${NOW}"
            EXP=$((NOW+36000))
            HEADER_RAW='{"alg": "RS256","kid": "'"$FINGERPRINT"'","typ": "JWT"}'
            HEADER=$( echo -n "${HEADER_RAW}" | openssl base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n' )

            PAYLOAD_RAW_AUTH='{"iat":'"${IAT}"',"exp":'"${EXP}"',"gnt":'"${i}"', "tt":0}'
            PAYLOAD_AUTH=$( echo -n "${PAYLOAD_RAW_AUTH}" | openssl base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n' )
            HEADER_PAYLOAD_AUTH="${HEADER}"."${PAYLOAD_AUTH}"
            SIGNATURE_AUTH=$( openssl dgst -sha256 -sign <(echo -n "${PEM}") <(echo -n "${HEADER_PAYLOAD_AUTH}") | openssl base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n' )
            JWT_AUTH="${HEADER_PAYLOAD_AUTH}"."${SIGNATURE_AUTH}"

            PAYLOAD_RAW_REFRESH='{"iat":'"${IAT}"',"exp":'"${EXP}"',"gnt":'"${i}"', "tt":1}'
            PAYLOAD_REFRESH=$( echo -n "${PAYLOAD_RAW_REFRESH}" | openssl base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n' )
            HEADER_PAYLOAD_REFRESH="${HEADER}"."${PAYLOAD_REFRESH}"
            SIGNATURE_REFRESH=$( openssl dgst -sha256 -sign <(echo -n "${PEM}") <(echo -n "${HEADER_PAYLOAD_REFRESH}") | openssl base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n' )
            JWT_REFRESH="${HEADER_PAYLOAD_REFRESH}"."${SIGNATURE_REFRESH}"

            echo $JWT_AUTH
            echo $JWT_REFRESH

            sqlite3 /data/database.sqlite "INSERT INTO users (user_login, user_email, user_admin, user_machine, user_active, user_syncing, user_synced, user_created, user_updated, user_last_login, user_avatar, user_oauth_expiry, user_hash, user_oauth_token, user_oauth_refresh) VALUES ('$username', '$email', 0, 0, 1, 0, 0, $(date +%s), $(date +%s), $(date +%s), '', $EXP, '$(echo $username|md5sum|cut -d ' ' -f 1|base64)', '$JWT_AUTH', '$JWT_REFRESH');"
            i=$((i+1))
        done < <(tail -n +2 /config/users.csv)
    fi

    # Create repositories from the /config/repositories.csv file
    if [ -f "/config/repositories.csv" ]; then
        echo "Creating repositories from /config/repositories.csv"
        i=1
        while IFS="," read -r username reponame tokens hooksecret private || [ -n "$username" ]; do
            # Validate that username and reponame are not empty
            if [ -z "$username" ] || [ -z "$reponame" ]; then
                echo "Invalid repo: $reponame"
                continue
            fi
            echo "Creating repository: $username/$reponame"
            if [ "${private,,}" = "true" ]; then
                private=1
            else
                private=0
            fi

            # Create the repository
            sqlite3 /data/database.sqlite "INSERT INTO repos (repo_uid, repo_user_id, repo_namespace, repo_name, repo_slug, repo_clone_url, repo_scm, repo_ssh_url, repo_html_url, repo_active, repo_private, repo_visibility, repo_branch, repo_counter, repo_config, repo_timeout, repo_trusted, repo_protected, repo_synced, repo_created, repo_updated, repo_version, repo_signer, repo_secret, repo_no_forks, repo_no_pulls, repo_cancel_pulls, repo_cancel_push, repo_throttle, repo_cancel_running) VALUES ($i, (select user_id from users where user_login = '$username'), '$username', '$reponame', '$username/$reponame', '$DRONE_GITEA_SERVER$username/$reponame.git', '', '', '$DRONE_GITEA_SERVER$username/$reponame', 1, $private, 'public', 'main', 1, '.drone.yml', 60, 0, 0, $(date +%s), $(date +%s), $(date +%s), 4, '$hooksecret', '', 0, 0, 0, 0, 0, 0);"
            i=$((i+1))
        done < <(tail -n +2 /config/repositories.csv)
    fi

    # Create secrets from the /config/secrets.csv file
    if [ -f "/config/secrets.csv" ]; then
        echo "Creating secrets from /config/secrets.csv"
        while IFS="," read -r secretname secretvalue namespace pullrequest repo || [ -n "$secretname" ]; do
            # Validate that secretname and secretvalue are not empty
            if [ -z "$secretname" ] || [ -z "$secretvalue" ] || [ -z "$namespace" ]; then
                echo "Invalid secret: $secretname"
                continue
            fi
            # check if secretvalue starts with b64: and decode it
            if [[ $secretvalue == b64:* ]]; then
                secretvalue=$(echo $secretvalue | cut -d: -f2 | base64 -d)
            fi
            echo "Creating secret: $secretname"
            if [ -z "$repo" ]; then
                sqlite3 /data/database.sqlite "INSERT INTO orgsecrets (secret_name, secret_data, secret_type, secret_namespace, secret_pull_request, secret_pull_request_push) VALUES ('$secretname', '$secretvalue','', '$namespace', $pullrequest, $pullrequest);"
            else
                repo=$(echo $repo | tr -d '\r')
                repoid=$(sqlite3 /data/database.sqlite "select repo_id from repos where repo_namespace = '$namespace' and repo_name = '$repo';")
                sqlite3 /data/database.sqlite "INSERT INTO secrets (secret_name, secret_data, secret_repo_id, secret_pull_request, secret_pull_request_push) VALUES ('$secretname', '$secretvalue', $repoid, $pullrequest, $pullrequest);"
            fi
        done < <(tail -n +2 /config/secrets.csv)
    fi

    # Create secrets from the /config/cron_jobs.csv file
    if [ -f "/config/cron_jobs.csv" ]; then
        echo "Creating cron jobs from /config/cron_jobs.csv"
        i=1
        while IFS="," read -r namespace repo_name name expr  || [ -n "$name" ]; do
            # Validate that the repo, name and expr is not empty
            if [ -z "$namespace" ] || [ -z "$repo_name"] || [ -z "$name" ] || [ -z "$expr" ]; then
                echo "Invalid cron job: $name"
                continue
            fi
            next=$(($(date +%s) + 240)) # When the cron timer should trigger next
            repoid=$(sqlite3 /data/database.sqlite "select repo_id from repos where repo_namespace = '$namespace' and repo_name = '$repo_name';")
            echo "Creating cron job: $name for $repoid"
            sqlite3 /data/database.sqlite "INSERT INTO cron (cron_id, cron_repo_id, cron_name, cron_expr, cron_next, cron_prev, cron_event, cron_branch, cron_target, cron_disabled, cron_created, cron_updated, cron_version) VALUES ($i, $repoid, '$name', '$expr', $next, 0, 'push', 'main', '', 0, 0, 0, 0);"
            i=$((i+1))
        done < <(tail -n +2 /config/cron_jobs.csv)
    fi

    rm /data/fresh_install
else
    echo "Drone already configured"
fi


echo "Starting Drone..."
exec /bin/drone-server
