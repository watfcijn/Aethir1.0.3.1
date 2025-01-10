#! /bin/bash

function clean() {
    sudo rm -rf $BackupDir
    sudo rm -rf $PackagePath
}

function resume() {
    sudo mv $BackupDir/"$LastPackageName".backup/* $RUN_DIR
    if [ $? -ne 0 ]; then
       touch $FailedLog
       echo "Failed to resume service." >> $FailedLog
       exit -1
    fi
    clean
}

if [ $# -ne 2 ]; then
    echo "Usage: ./update.sh <package-path>"
    exit -1
fi

PackagePath=$1
NewVersion=$2

UncompressDir=v"$NewVersion"

ServiceName=AethirCheckerService
CLIName=AethirCheckerCLI

BackupDir=/opt/tmp/Aethir
sudo mkdir -p $BackupDir/$UncompressDir

RUN_DIR=$(dirname $(realpath $0))

LastPackageName=$(basename "$RUN_DIR")

NewPackageName=$(basename "$PackagePath")

sudo rm -f $RUN_DIR/fail-*.log
sudo rm -f $RUN_DIR/success-*.log

FailedLog=$RUN_DIR/fail-$NewVersion.log
SuccessLog=$RUN_DIR/success-$NewVersion.log

# backup
sudo cp -Rd $RUN_DIR $BackupDir/"$LastPackageName".backup

sudo tar -xvf $PackagePath -C $BackupDir/$UncompressDir --strip-components 1
if [ $? -ne 0 ]; then
    touch $FailedLog
    echo "Failed uncompress installation package." >> $FailedLog
    resume
    exit -1
fi

sudo rm -rf $RUN_DIR/config
#sudo rm -rf $RUN_DIR/log
sudo mv $BackupDir/$UncompressDir/* $RUN_DIR
if [ $? -ne 0 ]; then
    touch $FailedLog
    echo "Failed to update service. to resume" >> $FailedLog
    resume
    exit -1
fi

#sudo ps -ef | grep $CLIName | grep -v grep | awk '{print $2}' | xargs kill -9
touch $SuccessLog
echo "Success!" >> $SuccessLog

sudo systemctl restart aethir-checker
#sudo bash $RUN_DIR/install.sh
if [ $? -ne 0 ]; then
    touch $FailedLog
    echo "Failed to install service. " >> $FailedLog
    exit -1
fi

exit 0
