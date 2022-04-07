SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd $SCRIPT_DIR

sudo chown -R ubuntu:ubuntu $SCRIPT_DIR
if test -f $SCRIPT_DIR/db.sqlite3; then
  sudo chown ubuntu:ubuntu $SCRIPT_DIR/db.sqlite3
fi

# Required Packages
sudo apt-get update
sudo apt-get install python3-pip libjpeg-dev libjpeg8-dev libpng-dev apache2 libapache2-mod-wsgi-py3 python3-virtualenv libsndfile1

virtualenv $SCRIPT_DIR/IV3DmEnv
source $SCRIPT_DIR/IV3DmEnv/bin/activate
pip3 install django djangorestframework requests

DATASERVER_PATH='/home/ubuntu/Storage/'
SERVER_ADDRESS='0.0.0.0'
[ -z "$SECRET_KEY" ] && SECRET_KEY=`cat /dev/urandom | tr -dc '[:alpha:]' | fold -w ${1:-20} | head -n 1`
export SECRET_KEY=$SECRET_KEY

# Ask User for Installation Path
read -p "Please Enter Storage Path [default: '/home/ubuntu/Storage/']: " userInput
[ ! -z "$userInput" ] && DATASERVER_PATH=$userInput

# Ask User for Domain IP
read -p "Please Enter Domain IP [default: '0.0.0.0']: " userInput
[ ! -z "$userInput" ] && SERVER_ADDRESS=$userInput

cp $SCRIPT_DIR/IV3DmAdmin/wsgi.py $SCRIPT_DIR/IV3DmAdmin/wsgi_production.py
export STATIC_ROOT="$SCRIPT_DIR/AdminPlatform/static"
export DATASERVER_PATH=$DATASERVER_PATH
export SERVER_ADDRESS=$SERVER_ADDRESS
sed -i "15 i os.environ[\"STATIC_ROOT\"] = \"$STATIC_ROOT\"" "$SCRIPT_DIR/IV3DmAdmin/wsgi_production.py"
sed -i "16 i os.environ[\"SECRET_KEY\"] = \"$SECRET_KEY\"" "$SCRIPT_DIR/IV3DmAdmin/wsgi_production.py"
sed -i "17 i os.environ[\"SERVER_ADDRESS\"] = \"$SERVER_ADDRESS\"" "$SCRIPT_DIR/IV3DmAdmin/wsgi_production.py"
sed -i "17 i os.environ[\"DATASERVER_PATH\"] = \"$DATASERVER_PATH\"" "$SCRIPT_DIR/IV3DmAdmin/wsgi_production.py"

ADMIN_EMAIL='Admin@IV3DmUF.edu'

cp $SCRIPT_DIR/iv3dm.conf $SCRIPT_DIR/iv3dm_production.conf
sed -i "s#%{DOCUMENTROOT}#$SCRIPT_DIR#g" $SCRIPT_DIR/iv3dm_production.conf
sed -i "s#%{ADMIN_NAME}#$ADMIN_EMAIL#g" $SCRIPT_DIR/iv3dm_production.conf
sed -i "s#%{SERVER_NAME}#$SERVER_ADDRESS#g" $SCRIPT_DIR/iv3dm_production.conf
sudo cp $SCRIPT_DIR/iv3dm_production.conf /etc/apache2/sites-available/iv3dm.conf

sudo a2dissite 000-default.conf
sudo a2ensite iv3dm.conf
sudo systemctl reload apache2

if test -f $SCRIPT_DIR/db.sqlite3; then
  sudo rm $SCRIPT_DIR/db.sqlite3
fi
python3 $SCRIPT_DIR/manage.py makemigrations
python3 $SCRIPT_DIR/manage.py migrate
python3 $SCRIPT_DIR/manage.py collectstatic

sudo chown -R www-data:www-data $SCRIPT_DIR
sudo chown www-data:www-data $SCRIPT_DIR/db.sqlite3

mkdir -p $DATASERVER_PATH
sudo chown -R www-data:www-data $DATASERVER_PATH
