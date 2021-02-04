#!/bin/bash
clear

#Checa se o usuario é root
LOCAL_USER=`id -u -n`

if [ $LOCAL_USER != "root" ] ; then
	echo "     Rodar como usuario root"
	echo "     saindo..."
	echo ""
	exit
fi
	dir="Diretorio Atual		 : `pwd`"
	hostname="Hostname			 : `hostname --fqdn`"
	ip="IP						 : `wget -qO - icanhazip.com`"
	#ip="IP						 : `ifconfig | awk 'NR>=2 && NR<=2' | awk '{print $3}'`"
    versaoso="Versao S.O.		 : `lsb_release -d | cut -d : -f 2- | sed 's/^[ \t]*//;s/[ \t]*$//'`"
	release="Release			 : `lsb_release -r | cut -d : -f 2- | sed 's/^[ \t]*//;s/[ \t]*$//'`"
	codename="Codename			 : `lsb_release -c | cut -d : -f 2- | sed 's/^[ \t]*//;s/[ \t]*$//'`"
	kernel="Kernel				 : `uname -r`"
	arquitetura="Arquitetura	 : `uname -m`"
    echo "+-------------------------------------------------+"
    echo "|         Utilitario para Duplicati  v1.8         |"
    echo "+-------------------------------------------------+"
    echo "+-------------------------------------------------+"
    echo "| Escrito por:                                    |"
    echo "| Thiago Castro - www.hostlp.cloud                |"
    echo "+-------------------------------------------------+"
    echo
    echo $dir
	echo "+-------------------------------------------------+"
	echo $hostname
	echo "+-------------------------------------------------+"
	echo $ip
	echo "+-------------------------------------------------+"
	echo $versaoso
	echo "+-------------------------------------------------+"
	echo $release
	echo "+-------------------------------------------------+"
	echo $codename
	echo "+-------------------------------------------------+"
    echo $kernel
	echo "+-------------------------------------------------+"
    echo $arquitetura
	echo "+-------------------------------------------------+"
	echo
	echo "Aperte <ENTER> para continuar e começar..."
	read 
	sleep 3
	echo
	echo "==================EXECUTANDO======================="
	echo

echo "Instalando dependencias..."
yum install appindicator-sharp libappindicator-sharp mono-core libappindicator yum-utils mono-devel dnf -y  1&> /dev/null
    echo "+-------------------------------------------------+OK"
	echo
	
echo "Download Duplicati..."
cd /opt/ ; wget https://updates.duplicati.com/beta/duplicati-2.0.5.1-2.0.5.1_beta_20200118.noarch.rpm  1&> /dev/null
    echo "+-------------------------------------------------+OK"
	echo

echo "Instalando Duplicati..."
#rpm -i duplicati-2.0.5.1-2.0.5.1_beta_20200118.noarch.rpm  1&> /dev/null
dnf install -y duplicati-*.rpm
     echo "+-------------------------------------------------+OK"
     echo

# Ask for configurations parameters
read -p 'Duplicati webserver hostname: ' duplicati_hostname
while true
do
  read -p 'Duplicati webserver port [padrão 8200]: ' duplicati_port
  [[ $duplicati_port =~ ^([0-9]+|'')$ ]] || { echo "Enter a valid number"; continue; }
  if (( duplicati_port >= 1 && duplicati_port <= 65535 )); then
    break;
  elif [ -z "$duplicati_port" ];then
    #Set default port
    duplicati_port=8200
    break;
  else
    echo "Porta invalida!"
  fi
done


read -p 'Duplicati webserver ssl certificate path (pkcs12) [Deixe em branco para usar HTTP]: ' ssl_cert_path

if [ -n "$ssl_cert_path" ]; then
  ssl_config="--webservice-sslcertificatefile=$ssl_cert_path"
fi
     echo "+-------------------------------------------------+OK"
     echo

echo "Criando arquivos systemctl..."
cat > /etc/systemd/system/duplicati.service << EOF
[Unit]
Description=Duplicati web-server
After=network.target

[Service]
Nice=19
IOSchedulingClass=idle
EnvironmentFile=-/etc/default/duplicati
ExecStart=/usr/bin/duplicati-server \$DAEMON_OPTS
Restart=always

[Install]
WantedBy=multi-user.target

EOF

cat > /etc/default/duplicati << EOF
# Defaults for duplicati initscript
# sourced by /etc/init.d/duplicati
# installed at /etc/default/duplicati by the maintainer scripts

#
# This is a POSIX shell fragment
#

echo "Opções adicionais que são passadas para o Daemon..."
DAEMON_OPTS="--webservice-port=$duplicati_port --webservice-interface=any --webservice-allowed-hostnames=$duplicati_hostname $ssl_config"

EOF
     echo "+-------------------------------------------------+OK"
     echo
	 
echo "Habilitando e iniciando o daemon Duplicati..."
systemctl daemon-reload
systemctl enable duplicati
systemctl start duplicati
     echo "+-------------------------------------------------+OK"
     echo

echo "Liberando porta $duplicati_port no Firewall..."
firewall-cmd --add-port=$duplicati_port/tcp  1&> /dev/null
firewall-cmd --reload  1&> /dev/null
     echo "+-------------------------------------------------+OK"
     echo
	 
echo "Adicionando certificados CA da Mozilla para evitar o erro "Nenhum certificado encontrado""
curl -O https://curl.haxx.se/ca/cacert.pem 1&> /dev/null
cert-sync --user cacert.pem 1&> /dev/null
rm -f cacert.pem 1&> /dev/null
     echo "+-------------------------------------------------+OK"
     echo
