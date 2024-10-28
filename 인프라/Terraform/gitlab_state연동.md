```
Terraform backend git 적용법
# linux
export TF_USERNAME=project_15_bot_TF_USERNAME
export TF_PASSWORD=glpat-TF_PASSWORD
export TF_STATE_NAME=TF_STATE_NAME
export PROJECT_ID="15"
export TF_ADDRESS=" https://gitlab.email.com/api/v4/projects/${PROJECT_ID}/terraform/state/${TF_STATE_NAME}"
terraform init \
-backend-config="address=${TF_ADDRESS}" \
-backend-config="lock_address=${TF_ADDRESS}/lock" \
-backend-config="unlock_address=${TF_ADDRESS}/lock" \
-backend-config="username=$TF_USERNAME" \
-backend-config="password=$TF_PASSWORD" \
-backend-config="lock_method=POST" \
-backend-config="unlock_method=DELETE" \
-backend-config="retry_wait_min=5"
----------
# windows
set TF_USERNAME=project_15_bot_TF_USERNAME
set TF_PASSWORD=glpat-TF_PASSWORD
set TF_STATE_NAME=default
set PROJECT_ID=15
set TF_ADDRESS= https://gitlab.email.com/api/v4/projects/%PROJECT_ID%/terraform/state/%TF_STATE_NAME%

terraform init -backend-config="address=%TF_ADDRESS%" -backend-config="lock_address=%TF_ADDRESS%/lock" -backend-config="unlock_address=%TF_ADDRESS%/lock" -backend-config="username=%TF_USERNAME%" -backend-config="password=%TF_PASSWORD%" -backend-config="lock_method=POST" -backend-config="unlock_method=DELETE" -backend-config="retry_wait_min=5"
terraform init -backend-config="address=%TF_ADDRESS%" -backend-config="lock_address=%TF_ADDRESS%/lock" -backend-config="unlock_address=%TF_ADDRESS%/lock" -backend-config="username=%TF_USERNAME%" -backend-config="password=%TF_PASSWORD%" -backend-config="lock_method=POST" -backend-config="unlock_method=DELETE" -backend-config="retry_wait_min=5"

```

