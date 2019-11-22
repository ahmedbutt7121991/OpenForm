#! /bin/bash
echo "========================"
echo "      MAIN SCRIPT       "
echo "========================"
echo "================================"
echo " USING TERRAFORM TO CREATE NFV "
echo "================================"
echo "STEP 1...."
echo "Checking Script validation....."
status=$(terraform validate)
echo "$status"
status_script=$(echo "$status" | awk -F "!" '{ print $1}')
echo "$status_script"
status="Success"
#if [ "$status_script" == "Success" ]
if [[ $status_script == *"$status"* ]]
    then
        echo "="
        echo "=="
        echo "==="
        echo "STEP 2...."
        echo "Checking  Script plan....."
        terraform plan -out terraform-plan.out
        echo "="
        echo "=="
        echo "==="
        echo "STEP 3...."
        echo "Applying the terraform Plan....."
        terraform apply terraform-plan.out
    else
        echo "Script is not valid...."
fi

if [[ $1 == *"--destroy"* ]]
    then
        echo "="
        echo "=="
        echo "==="
        echo "STEP 4...."
        echo "Destroying all created Resource....."
        yes 'yes' | terraform destroy
fi