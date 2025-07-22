#!/bin/bash

source ./common.sh
app_name=shipping

check_root
echo -e "Please enter root password to setup"
read -s MYSQL_ROOT_PASSWORD

app_setup
maven_setup
systemd_setup

dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "Installing MYSQL"

mysql -h mysql.daws85s.fun -u root -p$MYSQL_ROOT_PASSWORD -e 'use cities' &>>$LOG_FILE
if [ $? -ne 0 ]
then
    mysql -h mysql.daws85s.fun -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/schema.sql &>>$LOG_FILE
    mysql -h mysql.daws85s.fun -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/app-user.sql &>>$LOG_FILE
    mysql -h mysql.daws85s.fun -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/master-data.sql &>>$LOG_FILE
    VALIDATE $? "Loading data into MYSQL"
else
    echo -e "Data is already loaded in MYSQL ... $Y SKIPPING $N"
fi        

systemctl restart shipping &>>$LOG_FILE
VALIDATE $? "Restarting shipping"

print_time