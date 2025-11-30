#!/bin/bash
echo "Waiting for Gitea to spawn..."

until $(curl --output /dev/null --silent --head --fail http://localhost:3000); do
    printf '.'
    sleep 5
done

chmod 777 /tokens

if [ -n "$GLOBAL_TOKEN" ] && [ "${GLOBAL_TOKEN,,}" = "true" ]; then
    echo "Creating global runner token"
    su -c "gitea actions generate-runner-token > /tokens/global" git
fi


base_webhook_config='{"push_only":false,"send_everything":false,"choose_events":true,"branch_filter":"main","events":{"create":true,"delete":true,"fork":false,"issues":false,"issue_assign":false,"issue_label":false,"issue_milestone":false,"issue_comment":false,"push":true,"pull_request":true,"pull_request_assign":true,"pull_request_label":true,"pull_request_milestone":true,"pull_request_comment":true,"pull_request_review":true,"pull_request_sync":true,"pull_request_review_request":true,"wiki":false,"repository":false,"release":false,"package":false}}'

# Create repositories from the /config/repositories.csv file
if [ -f "/config/repositories.csv" ]; then
    echo "Creating repositories from /config/repositories.csv"
    while IFS="," read -r username reponame token hooksecret private webhook_config|| [ -n "$username" ]; do
        # Validate that username and reponame are not empty
        if [ -z "$username" ] || [ -z "$reponame" ] || [ -z "$token" ]; then
            echo "Invalid repo: $reponame"
            continue
        fi
        # Create missing git folders
        mkdir -p /config/repositories/$username/$reponame/git/branches
        mkdir -p /config/repositories/$username/$reponame/git/refs/heads
        mkdir -p /config/repositories/$username/$reponame/git/refs/tags
        
        echo "Creating repository: $username/$reponame"
        su -c "gitea restore-repo -r /config/repositories/$username/$reponame --owner_name  $username --repo_name $reponame" git
        if [ -n "$hooksecret" ]; then
            if [ -z "$webhook_config" ]; then
                webhook_config=$base_webhook_config
            fi
            echo "Adding webhook to repository: $username/$reponame"
            sqlite3 /data/gitea/gitea.db "insert into webhook(repo_id,url,http_method,content_type,secret,events,is_active,type,created_unix,updated_unix) values((select id from repository where owner_name='$username' and name='$reponame'),'https://$DRONE_SERVER_HOST/hook?secret=$hooksecret','POST',1,'$hooksecret','$webhook_config',1,'gitea', 1709123975, 1709123975);"
        fi

        if [ "${private,,}" = "true" ]; then
            echo "Making repository private: $username/$reponame"
            sqlite3 /data/gitea/gitea.db "update repository set is_private=1 where owner_name='$username' and name='$reponame';"
        fi

        # If token is not empty and the token var is caseinsensetively equeal to true, create a runner token
        if [ -n "$token" ] && [ "${token,,}" = "true" ]; then
            echo "Creating runner token for repository: $username/$reponame"
            su -c "gitea actions generate-runner-token -s $username/$reponame > /tokens/$username-$reponame" git
        fi
    done < <(tail -n +2 /config/repositories.csv)
fi

# Adding colaborators from the /config/repositories.csv file
if [ -f "/config/contributers.csv" ]; then
    echo "Creating contributers from /config/contributers.csv"
    while IFS="," read -r username reponame contributers mode|| [ -n "$username" ]; do
        # Validate that username and reponame are not empty
        if [ -z "$username" ] || [ -z "$reponame" ] || [ -z "$contributers" ] || [ -z "$mode" ]; then
            echo "Invalid contributer for: $reponame"
            continue
        fi

        if [ -n "$contributers" ]; then
            echo "Adding contributers to repository: $username/$reponame"
            while IFS="," read -r contributer || [ -n "$contributer" ]; do
                if [ -z "$contributer" ]; then
                    continue
                fi
                echo "Adding contributer: $contributer"
                sqlite3 /data/gitea/gitea.db "insert into access(user_id, repo_id, mode) values((select id from user where name='$contributer'),(select id from repository where owner_name='$username' and name='$reponame'),$mode);"
            done < <(echo $contributers | tr -d '\r')
        fi

    done < <(tail -n +2 /config/contributers.csv)
fi

# Adding branch protection rules from the /config/branch_protection.csv file
if [ -f "/config/branch_protection.csv" ]; then
    i=1
    timestamp=$(date +%s) # When the cron timer should trigger next
    echo "Creating branch protection rules from /config/branch_protection.csv"
    while IFS="," read -r username reponame branch_name can_push required_approvals|| [ -n "$username" ]; do
        # Validate that username and reponame are not empty
        if [ -z "$username" ] || [ -z "$reponame" ] || [ -z "$branch_name" ] || [ -z "$can_push" ] || [ -z "$required_approvals" ]; then
            echo "Invalid branch protection rule for: $reponame"
            continue
        fi

        if [ -n "$required_approvals" ]; then
            echo "Adding branch protection rule to repository: $username/$reponame"
            while IFS="," read -r required_approvals || [ -n "$required_approvals" ]; do
                if [ -z "$required_approvals" ]; then
                    continue
                fi
                echo "Adding rule"
                sqlite3 /data/gitea/gitea.db "insert into protected_branch(id, repo_id, branch_name, can_push, required_approvals, created_unix, updated_unix) values($i,(select id from repository where owner_name='$username' and name='$reponame'),'$branch_name',$can_push,$required_approvals,$timestamp,$timestamp);"
            done < <(echo $required_approvals | tr -d '\r')
        fi

    i=$((i+1))
    done < <(tail -n +2 /config/branch_protection.csv)
fi

if [ -f "/config/tokens.csv" ]; then
    echo "Creating tokens from /config/tokens.csv"
    while IFS="," read -r username name tokenhash salt lasteight scope || [ -n "$username" ]; do
        # Validate that username, name and tokenhash are not empty
        if [ -z "$username" ] || [ -z "$name" ] || [ -z "$tokenhash" ]; then
            echo "Invalid token: $name"
            continue
        fi
        echo "Creating token: $name"
        sqlite3 /data/gitea/gitea.db "insert into access_token(uid, name, token_hash, token_salt, token_last_eight, scope, created_unix, updated_unix) values((select id from user where name='$username'), '$name', '$tokenhash', '$salt', '$lasteight', '$scope', 1709123975, 1709123975);"
    done < <(tail -n +2 /config/tokens.csv)
fi

rm /data/fresh_install
echo "Gitea configured"
rm /tmp/postconfigure.sh
