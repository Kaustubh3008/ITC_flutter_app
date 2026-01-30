# from flask import Flask, request, jsonify
# from flask_sqlalchemy import SQLAlchemy
# from flask_bcrypt import Bcrypt
# from flask_jwt_extended import JWTManager, create_access_token
# import os

# app = Flask(__name__)

# # --- CONFIGURATION ---
# # In production, change this to your cloud database URL (e.g., PostgreSQL)
# app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///site.db' 
# app.config['SECRET_KEY'] = 'super-secret-key-change-this-in-prod'

# db = SQLAlchemy(app)
# bcrypt = Bcrypt(app)
# jwt = JWTManager(app)

# # --- DATABASE MODEL ---
# class User(db.Model):
#     id = db.Column(db.Integer, primary_key=True)
#     name = db.Column(db.String(100), nullable=False)
#     email = db.Column(db.String(120), unique=True, nullable=False)
#     password = db.Column(db.String(60), nullable=False)

# # --- ENDPOINTS ---

# @app.route('/register', methods=['POST'])
# def register():
#     data = request.get_json()
    
#     # 1. Check if user exists
#     if User.query.filter_by(email=data['email']).first():
#         return jsonify({"message": "Email already exists"}), 400
    
#     # 2. Hash password (Professional Security)
#     hashed_password = bcrypt.generate_password_hash(data['password']).decode('utf-8')
    
#     # 3. Create and Save User
#     new_user = User(name=data['name'], email=data['email'], password=hashed_password)
#     db.session.add(new_user)
#     db.session.commit()
    
#     return jsonify({"message": "User created successfully"}), 201

# @app.route('/login', methods=['POST'])
# def login():
#     data = request.get_json()
    
#     # 1. Find User
#     user = User.query.filter_by(email=data['email']).first()
    
#     # 2. Check Password
#     if user and bcrypt.check_password_hash(user.password, data['password']):
#         # 3. Generate Token
#         access_token = create_access_token(identity=user.id)
#         return jsonify({
#             "message": "Login successful",
#             "token": access_token,
#             "name": user.name
#         }), 200
#     else:
#         return jsonify({"message": "Invalid email or password"}), 401

# if __name__ == '__main__':
#     with app.app_context():
#         db.create_all() # Creates the database if it doesn't exist
#     # Host 0.0.0.0 allows external access
#     app.run(debug=True, host='0.0.0.0', port=5000)



import os
import subprocess
import platform
from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from flask_bcrypt import Bcrypt
from flask_jwt_extended import JWTManager, create_access_token

app = Flask(__name__)

# --- CONFIGURATION ---
# In production, change this to your cloud database URL (e.g., PostgreSQL)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///site.db' 
app.config['SECRET_KEY'] = 'super-secret-key-change-this-in-prod'

db = SQLAlchemy(app)
bcrypt = Bcrypt(app)
jwt = JWTManager(app)

# --- DATABASE MODEL ---
class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password = db.Column(db.String(60), nullable=False)

# --- ENDPOINTS ---

@app.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    
    # 1. Check if user exists
    if User.query.filter_by(email=data['email']).first():
        return jsonify({"message": "Email already exists"}), 400
    
    # 2. Hash password (Professional Security)
    hashed_password = bcrypt.generate_password_hash(data['password']).decode('utf-8')
    
    # 3. Create and Save User
    new_user = User(name=data['name'], email=data['email'], password=hashed_password)
    db.session.add(new_user)
    db.session.commit()
    
    return jsonify({"message": "User created successfully"}), 201

@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    
    # 1. Find User
    user = User.query.filter_by(email=data['email']).first()
    
    # 2. Check Password
    if user and bcrypt.check_password_hash(user.password, data['password']):
        # 3. Generate Token
        access_token = create_access_token(identity=user.id)
        return jsonify({
            "message": "Login successful",
            "token": access_token,
            "name": user.name
        }), 200
    else:
        return jsonify({"message": "Invalid email or password"}), 401

# --- AUTOMATIC ADB SETUP ---
def auto_setup_adb_reverse():
    """
    Automatically bridges the phone's connection to localhost
    so users don't have to manually run adb commands.
    """
    # 1. Detect OS
    system = platform.system()
    executable_name = "adb.exe" if system == "Windows" else "adb"
    
    # 2. Find the bundled ADB in the 'tools' folder
    base_dir = os.path.dirname(os.path.abspath(__file__))
    adb_path = os.path.join(base_dir, "tools", executable_name)

    # 3. Check if we bundled it, otherwise fall back to system PATH
    if not os.path.exists(adb_path):
        print(f"⚠️  Bundled ADB not found at: {adb_path}")
        print("    Trying system 'adb' instead...")
        adb_path = "adb"

    # 4. Run the magic command
    try:
        print(f"🔄 Configuring Android USB Bridge using: {adb_path} ...")
        # Run: adb reverse tcp:5000 tcp:5000
        subprocess.run([adb_path, 'reverse', 'tcp:5000', 'tcp:5000'], check=True)
        print("✅ Success! Android Phone can now access Localhost:5000")
    except FileNotFoundError:
        print("❌ Error: ADB executable not found. Please install Android Platform Tools.")
    except subprocess.CalledProcessError:
        print("⚠️  Warning: Could not run 'adb reverse'. Is the phone connected via USB with Debugging ON?")
        print("    (If you are using an Emulator, you can ignore this.)")

if __name__ == '__main__':
    # 1. Run the Auto-Setup
    auto_setup_adb_reverse()

    # 2. Setup DB context
    with app.app_context():
        db.create_all() # Creates the database if it doesn't exist
    
    # 3. Start Server
    # Host 0.0.0.0 allows external access
    app.run(debug=True, host='0.0.0.0', port=5000)