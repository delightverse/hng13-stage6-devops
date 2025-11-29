[app_servers]
${server_ip} ansible_user=${ansible_user} ansible_ssh_private_key_file=${ssh_private_key_path}

[app_servers:vars]
github_repo_url=${github_repo_url}
github_branch=${github_branch}
domain=${domain}
jwt_secret=${jwt_secret}
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
app_directory=/opt/todo-app
