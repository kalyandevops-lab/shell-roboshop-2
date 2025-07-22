#!/bin/bash

source ./common.sh
app_name=mysql
check_root

echo -e "Please enter root password to setup"
read -s MYSQL_ROOT_PASSWORD

dnf install mysql-server -y &>>$LOG_FILE
VALIDATE $? "Installing MYSQL server"

systemctl enable mysqld &>>$LOG_FILE
VALIDATE $? "Enabling MYSQL"

systemctl start mysqld &>>$LOG_FILE
VALIDATE $? "Starting MYSQL"

mysql_secure_installation --set-root-pass $MYSQL_ROOT_PASSWORD &>>$LOG_FILE
VALIDATE $? "Setting MYSQL root password"

print_time

