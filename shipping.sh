#!/bin/bash

START_TIME=$(date +%s)
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

mkdir -p $LOGS_FOLDER
echo "Script started executing at: $(date)" | tee -a $LOG_FILE

# Check the user has root priveleges or not
if [ $USERID -ne 0 ]
then
    echo -e "$R Errror:: Please run this script with root access $N" | tee -a $LOG_FILE
    exit 1 #give other than 0 upto 127
else
    echo "You are running with root access" | tee -a $LOG_FILE
fi

echo -e "Please enter root password to setup"
read -s MYSQL_ROOT_PASSWORD

# validate function takes input as exit status, what command they tried to install
VALIDATE(){
   if [ $1 -eq 0 ]
    then
        echo -e "$2 is ...$G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 is ...$R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    fi   
}

dnf install maven -y &>>$LOG_FILE
VALIDATE $? "Installing Maven and Java"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Creating roboshop system user"
else
    echo -e "System user roboshop already created ... $Y SKIPPING $N" 
fi       

mkdir -p /app 
VALIDATE $? "Creating app directory"

curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading shipping"

rm -rf /app/*
cd /app 
unzip /tmp/shipping.zip &>>$LOG_FILE
VALIDATE $? "unzipping shipping"

mvn clean package &>>$LOG_FILE
VALIDATE $? "Packaging the shipping application"

mv target/shipping-1.0.jar shipping.jar &>>$LOG_FILE
VALIDATE $? "Moving and Renaming Jar file"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Daemon Reload"

systemctl enable shipping &>>$LOG_FILE
VALIDATE $? "Enabling shipping"

systemctl start shipping &>>$LOG_FILE
VALIDATE $? "Starting shipping"

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

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))

echo -e "Script execution completed successfully, $Y Time taken: $TOTAL_TIME  seconds $N" | tee -a $LOG_FILE
