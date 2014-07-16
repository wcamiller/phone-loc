from flask import Flask, render_template,request, jsonify, redirect, session, url_for, flash
from functools import wraps
from werkzeug.exceptions import BadRequest
from sqlalchemy import create_engine, Column, Integer, String, MetaData, exists
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, scoped_session
from sqlalchemy.exc import OperationalError
from sqlalchemy.orm.exc import NoResultFound
import time, os

app = Flask(__name__)
app.secret_key = '2c1a9ed49d562f6b363341776f159b0600876794006ea0ada2a35fa2fabecdf9e258f3bb'

engine = create_engine('sqlite:////users/wcamiller/github/phone-loc/app/db/db.db', echo=True)
Base = declarative_base()
Session = scoped_session(sessionmaker(bind=engine))

class User(Base):
	__tablename__ = 'users'
	id = Column(Integer, primary_key='True')
	username = Column(String)
	password = Column(String)
	first_name = Column(String)
	last_name = Column(String)

	def __repr__(self):
	    return "'%s', '%s', '%s', '%s'" % (self.username, self.password, self.first_name, self.last_name)

	def get_username(self):
	    return str(self.username)

	def get_password(self):
	    return str(self.password)

	def get_first_name(self):
	    return str(self.first_name)

	def get_last_name(self):
	    return str(self.last_name)

class MapData(Base):
	__tablename__ = 'mapdata'
	id = Column(Integer, primary_key='True')
	lat = Column(Integer)
	long = Column(Integer)
	timestamp = Column(String)

	def __repr__(self):
		return "'%s', '%s'" % (self.lat, self.long)

	def get_lat(self):
		return str(self.lat)

	def get_long(self):
		return str(self.long)

	def get_timestamp(self):
		return str(self.timestamp)

Base.metadata.create_all(bind=engine)

def check_url(f):
    @wraps(f)
    def wrapped(*args, **kwargs):
        url = str(request.url)
        slice = url[:url.find(':')]
        if slice == 'http':
            return reriect(url_for(f.__name__))
        else:
            return f(*args, **kwargs)
    return wrapped

def login_required(f):
    @wraps(f)
    def wrapped(*args, **kwargs):
        if 'username' in session:
        	return f(*args, **kwargs)
        elif request.method == 'POST':
        	 return get_phone_session(request.json['username'], request.json['password'])
        else:
        	return render_template('login.html')
    return wrapped

@app.route('/', methods=['GET', 'POST'])
@login_required
#@check_url
def home():
	db_session = Session()
	db_count = db_session.query(MapData).count()
	return render_template('display_map.html', db_count=db_count, username=session['username'])

@app.route('/display_map')
@login_required
#@check_url
def display_map():
    db_session = Session()
    db_count = db_session.query(MapData).count()
    return render_template('display_map.html', db_count=db_count, username=session['username'])

@app.route('/login', methods=['GET', 'POST'])
#@login_required
#@check_url
def login():
	if request.method == 'POST':
		db_session = Session()
		submitted_username = request.form['username']
		submitted_password = request.form['password']
		username_valid = db_session.query(exists().where(User.username == submitted_username)).scalar()
		try:
		    db_password = db_session.query(User).filter(User.username == submitted_username).one().password
		except (OperationalError, NoResultFound):
		    db_password = None
		if username_valid and submitted_password == db_password:
			first_name = db_session.query(User).filter(User.username == submitted_username).one().first_name
			session['username'] = submitted_username
			return "http://localhost:5000/"
		else:
			return BadRequest()
	return render_template('login.html')

@app.route('/poll_server', methods=["POST"])
@login_required
#@check_url
def poll_server():
	db_session = Session()
	incoming_len = request.form['len']
	actual_len = db_session.query(MapData).count()
	if int(incoming_len) < int(actual_len):
		return jsonify(locs=gather_data('locs'), colors=gather_data('colors'))
	else:
		raise BadRequest()

@app.route('/setup_map')
@login_required
#@check_url
def setup_map():
	return jsonify(locs=gather_data('locs'), colors=gather_data('colors'))

@app.route('/run_post', methods=["POST"])
@login_required
def run_post():
	db_session = Session()
	value = request.json['array']
	db_session.add(MapData(lat=value[0], long=value[1], timestamp=value[2]))
	db_session.commit()
	return str(value)

@app.route('/logout')
@login_required
def logout():
    session.pop('username', None)
    return redirect(url_for('home'))

@app.route('/purge_db')
@login_required
def purge_db():
	db_session = Session()
	query = db_session.query(MapData)
	for e in range(1, query.count() + 1):
		db_session.delete(query.get(e))
	db_session.commit()
	return redirect(url_for('display_map'))

def get_phone_session(username, password):
	if username and password:
		session['username'] = username
		session['password'] = password
	return str(session['username']) + ", " + str(session['password'])

def get_colors(timestamps):
	colors = []
	current_time = time.strftime("%d%H%M")

	for e in range(1,len(timestamps)):
		test_val = int(current_time) - int(timestamps[e])
		if (int(current_time) / 10000) - (int(timestamps[e])/10000) == 0:
			if test_val <= 15:
				colors.append("#ff0000")
			elif test_val <= 30:
				colors.append("#cc0000")
			elif test_val <= 45:
				colors.append("#990000")
			else:
				colors.append("#4c0000")
		else:
			colors.append("#4c0000")

	return colors

def gather_data(type='locs'):
	db_session = Session()
	query = db_session.query(MapData)
	locs = [[query.get(e).get_lat(), query.get(e).get_long()] for e in range(1, query.count() + 1)]
	timestamps = [str(query.get(e).get_timestamp()) for e in range(1, query.count() + 1)]
	colors = get_colors(timestamps)

	return {'locs': locs, 'timestamps': timestamps, 'colors': colors}[type]

if __name__ == '__main__':
	os.environ['TZ'] = 'GMT'
	app.run(debug=True, threaded=True)

