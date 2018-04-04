#!/bin/bash

set -e

function installcmake {
  wget "https://cmake.org/files/v3.10/cmake-3.10.3-Linux-x86_64.sh" -O /tmp/cmake-3.10.3-Linux-x86_64.sh
  sudo sh /tmp/cmake-3.10.3-Linux-x86_64.sh --skip-license --prefix=/usr/local
}

DIR=`echo $PWD | xargs dirname | xargs dirname`
OS=$(cat /etc/os-release | grep "^ID=" | sed 's/ID=//g' | sed 's\"\\g')
if [ $OS = "centos" ] || [ $OS = "rhel" ];then
  echo "Installing the environment in $OS"  

  GOREL="go1.8.7.linux-amd64.tar.gz"

  # TODO: ALLWAYS DOWNLOAD AND INSTALL GOLANG!!!!

  #install Go
  if ! type "go" > /dev/null; then
    #INSTALACION DE GO
    PATH="$PATH:/usr/local/go/bin"
    echo "Installing GO"
    sudo yum -y install wget
    wget -q "https://storage.googleapis.com/golang/${GOREL}"
    tar -xvzf "${GOREL}"
    rm -Rf /usr/local/go
    mv go /usr/local/go
    sudo rm "${GOREL}"
  else
    V1=$(go version | grep -oP '\d+(?:\.\d+)+')
    V2=$(echo $GOREL | grep -oP '\d+(?:\.\d+)+')
    nV1=$(echo $V1 | sed 's/\.//g')
    nV2=$(echo $V2 | sed 's/\.//g')
    if (( $nV1 >= $nV2 )); then
       echo "Using your own version of Go"
    else
       echo "Your version of go is smaller than required"
       exit
    fi
  fi

  # install build deps
  sudo yum clean all
  echo "Installing Libraries"
  sudo yum -y update
  sudo yum -y install gmp-devel
  sudo yum -y install gcc gcc-c++ make openssl-devel
  sudo yum -y install libdb-devel
  sudo yum -y install ncurses-devel
  
  # Check EPEL repository availability. It is available by default in Fedora and CentOS, but it requires manuall
  # installation in RHEL
  EPEL_AVAILABLE=$(sudo yum search epel | grep release || true)
  if [[ -z $EPEL_AVAILABLE ]];then
    echo EPEL Repository is not available via YUM. Downloading
    wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm -O /tmp/epel-release-latest-7.noarch.rpm
    sudo yum -y install /tmp/epel-release-latest-7.noarch.rpm
  else 
    echo EPEL repository is available in YUM via distro packages. Adding it as a source for packages 
    sudo yum -y install epel-release
  fi

  echo "Installing LIBSODIUM"
  wget https://github.com/naphaso/jsodium/raw/master/native/linux/libsodium.so.18
  sudo chmod 755 libsodium.so.18
  sudo cp libsodium.so.18 /usr/lib64/
  echo "Installing LIBDB"
  wget https://github.com/hypergraphdb/hypergraphdb/raw/master/storage/bdb-native/native/linux/x86_64/libdb-5.3.so
  sudo chmod 755 libdb-5.3.so
  sudo cp libdb-5.3.so /usr/lib64/ || true
  cd ..
  
  #LEVELDB FIX
  echo "Installing LEVELDB"
  git clone https://github.com/google/leveldb.git
  cd leveldb/
  installcmake
  cmake .
  make
  make install
  sudo ldconfig || true
  cd ..
  sudo rm -r leveldb
  cd ..
  echo "Cleaning CACHE RPM"
  rm -f /var/lib/rpm/__db*
  rpm --rebuilddb
  echo "Installing NODE"
  sudo yum install -y nodejs
  
  #ETHEREUM
  echo "Installing ETHEREUM"
  git clone https://github.com/ethereum/go-ethereum
  cd go-ethereum/
  make geth
  ls -al  build/bin/geth
  sudo npm install -g solc
  
  # install constellation
  echo "Installing CONSTELLATION"
  wget -q https://github.com/jpmorganchase/constellation/releases/download/v0.3.2/constellation-0.3.2-ubuntu1604.tar.xz 
  unxz constellation-0.3.2-ubuntu1604.tar.xz 
  tar -xf constellation-0.3.2-ubuntu1604.tar
  sudo cp constellation-0.3.2-ubuntu1604/constellation-node /usr/local/bin 
  sudo chmod 0755 /usr/local/bin/constellation-node
  sudo rm -rf constellation-0.3.2-ubuntu1604.tar.xz constellation-0.3.2-ubuntu1604.tar constellation-0.3.2-ubuntu1604

  # make/install quorum
  echo "Installing QUORUM"
  git clone https://github.com/alastria/quorum.git
  pushd quorum >/dev/null
  git checkout af59943283e1abb39b4e4a27ec0062d59f3291ec
  make all
  sudo cp build/bin/geth /usr/local/bin
  sudo cp build/bin/bootnode /usr/local/bin
  popd >/dev/null

  # install Porosity
  echo "Installing POROSITY"
  wget -q https://github.com/jpmorganchase/quorum/releases/download/v1.2.0/porosity
  sudo mv porosity /usr/local/bin
  sudo chmod 0755 /usr/local/bin/porosity

elif [ $OS = "ubuntu" ];then
  echo "Installing the environment in " + $OS 

  GOREL="go1.8.7.linux-amd64.tar.gz"

  #Do not mess with Go instalations
  if ! type "go" > /dev/null; then
    #INSTALACION DE GO
    PATH="$PATH:/usr/local/go/bin"
    echo "Installing GO"
    wget -q "https://storage.googleapis.com/golang/${GOREL}"
    tar -xvzf "${GOREL}"
    sudo rm -rf /usr/local/go
    mv go /usr/local/go
    sudo rm "${GOREL}"
  else
    V1=$(go version | grep -oP '\d+(?:\.\d+)+')
    V2=$(echo $GOREL | grep -oP '\d+(?:\.\d+)+')
    nV1=$(echo $V1 | sed 's/\.//g')
    nV2=$(echo $V2 | sed 's/\.//g')
    if (( $nV1 >= $nV2 )); then
       echo "Using your own version of Go"
    else
       echo "Your version of go is smaller than required"
       exit
    fi
  fi

  sudo apt-get update && sudo apt-get install -y

  #INSTALACION DE LIBRERIAS
  sudo apt-get install -y software-properties-common unzip wget git make gcc libsodium-dev build-essential libdb-dev zlib1g-dev libtinfo-dev sysvbanner wrk psmisc

  echo "Installing WRK"
  rm -rf wrk
  git clone https://github.com/wg/wrk.git wrk
  cd wrk
  make
  sudo cp wrk /usr/local/bin
  
  #LEVELDB FIX
  git clone https://github.com/google/leveldb.git
  cd leveldb/
  installcmake
  cmake .
  make
  make install
  sudo ldconfig
  cd ..
  rm -r leveldb

#INSTALACION ETHEREUM
  sudo add-apt-repository -y ppa:ethereum/ethereum && sudo add-apt-repository -y ppa:ethereum/ethereum-dev && sudo apt-get update && sudo apt-get install -y solc

  #INSTALACION CONSTELLATION 0.2.0
  wget -q https://github.com/jpmorganchase/constellation/releases/download/v0.3.2/constellation-0.3.2-ubuntu1604.tar.xz 
  unxz constellation-0.3.2-ubuntu1604.tar.xz 
  tar -xf constellation-0.3.2-ubuntu1604.tar
  sudo cp constellation-0.3.2-ubuntu1604/constellation-node /usr/local/bin && sudo chmod 0755 /usr/local/bin/constellation-node
  sudo rm -rf constellation-0.3.2-ubuntu1604.tar.xz constellation-0.3.2-ubuntu1604.tar constellation-0.3.2-ubuntu1604

  #INSTALACION DE QUORUM
  git clone https://github.com/alastria/quorum.git

  cd quorum && git checkout 94e1e31eb6a97e08dff4e44a8695dab1252ca3bc && make all &&  cp build/bin/geth /usr/local/bin && cp build/bin/bootnode /usr/local/bin

  cd ..
  sudo rm -rf constellation-0.3.2-ubuntu1604.tar.xz constellation-0.3.2-ubuntu1604.tar constellation-0.3.2-ubuntu1604 quorum

fi

# Manage GOROOT variable
if [[ -z "$GOROOT" ]]; then
    echo "[*] Trying default $GOROOT. If the script fails please run $DIR/alastria-node/bootstrap.sh or configure GOROOT correctly"
    echo 'export GOROOT=/usr/local/go' >> $DIR/.bashrc
    echo 'export GOPATH=$HOME/alastria/workspace' >> $DIR/.bashrc
    echo 'export PATH=$GOROOT/bin:$GOPATH/bin:$PATH' >> $DIR/.bashrc
    export GOROOT=/usr/local/go
    export GOPATH=$DIR/alastria/workspace
    export PATH=$GOROOT/bin:$GOPATH/bin:$PATH

    echo "[*] GOROOT = $GOROOT, GOPATH = $GOPATH"

    mkdir -p "$GOPATH"/bin
    mkdir -p "$GOPATH"/src
fi

set +e
source ~/.bashrc
