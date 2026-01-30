#

---

## 📋 Prerequisites

Before running the project, make sure the following are installed and ready:

* **Flutter SDK** (for the mobile application)
* **Python 3.x** (for the backend server)
* **USB Cable** (to connect your Android phone to the computer)
* **Android Phone** with **USB Debugging enabled**

> ⚠️ Ensure Flutter and Python are correctly added to your system PATH.

---

## 🚀 Quick Start Guide

Follow the steps below in order to successfully run the project.

---

### Step 1: Hardware Setup

1. Connect your **Android phone** to your computer using a USB cable.
2. Enable **USB Debugging** on your phone:

   * Go to **Settings → Developer Options → USB Debugging**
3. Keep the phone connected for the entire process.

---

### Step 2: Start the Backend (Python Server)

The backend server manages:

* Database operations
* Image processing
* Automatic ADB port forwarding between the phone and computer

#### 1️⃣ Navigate to the server directory

```bash
cd server
```

#### 2️⃣ Install required Python packages

```bash
pip install -r requirements.txt
```

#### 3️⃣ Run the server

```bash
python app.py
```

✅ **Success Indicator**

You should see a message similar to:

```
✅ Success! Android Phone can now access Localhost:5000
```

This confirms that the ADB bridge has been configured successfully.

> ⚠️ Keep this terminal open while using the mobile app.

---

### Step 3: Run the Flutter Mobile App

1. Open a **new terminal window** (do not close the server terminal).
2. Navigate to the **project root directory** (where `pubspec.yaml` is located).

#### 1️⃣ Install Flutter dependencies

```bash
flutter pub get
```

#### 2️⃣ Launch the app on the connected device

```bash
flutter run
```

The application should now install and launch on your Android phone.

---

##

* Ensure the phone is connected via USB.
* Check the phone screen and **allow USB debugging** if prompted.
* Try unplugging and reconnecting the USB cable.
* Restart the server after reconnecting the device.

---

### 2. App shows "Connection Refused" or "Network Error"

* Confirm the Python server is still running.
* Verify `lib/config.dart` is pointing to:

```
http://127.0.0.1:5000
```

* Restart the server to refresh the ADB port forwarding:

```bash
Ctrl + C
python app.py
```

---

### 3. "pip is not recognized" error

* Make sure Python is added to your system PATH.
* Alternatively, try:

```bash
python -m pip install -r requirements.txt
```

or

```bash
python3 -m pip install -r requirements.txt
```

---

## ✅ Notes

* This project is intended for **local development and testing**.
* Keep both the **server** and **Flutter app** running simultaneously.
* Do not delete the `tools/` directory inside the server folder, as it contains required ADB utilities.

---
